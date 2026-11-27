#!/usr/bin/env bash
# =====================================================================
# Concurrence BNF-2 : 10 appels simultanés sur un louage à 6/8
#   5 × reserver_place (5 voyageurs)  +  5 × modifier_places(+1) (chauffeur)
# Attendu : exactement 2 succès, 8 échecs LOUAGE_COMPLET, passage à 8/8 COMPLET.
#
# Chaque appel = une session psql séparée, en rôle `authenticated` avec ses
# propres request.jwt.claims. Une barrière (verrou consultatif tenu par une
# session coordinatrice) libère les 10 sessions en même temps : elles se
# disputent réellement le verrou FOR UPDATE du passage.
#
# LOCAL UNIQUEMENT : passe par le conteneur Docker de `supabase start`.
#   supabase start && supabase db reset --local
#   test/concurrency/reserver_place_concurrency.sh [rounds]   (défaut 5)
# =====================================================================
set -euo pipefail

ROUNDS="${1:-5}"
CONTAINER="${DB_CONTAINER:-supabase_db_LouageLive}"
WORKERS=10
LOCK_KEY=424242
TMP="$(mktemp -d)"
trap 'cleanup >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT

docker ps --format '{{.Names}}' | grep -qx "$CONTAINER" || {
  echo "Conteneur $CONTAINER introuvable : lancez d'abord 'supabase start'." >&2
  exit 2
}

psql_q() { docker exec -i "$CONTAINER" psql -U postgres -X -q -tA -v ON_ERROR_STOP=1 "$@"; }

PASSAGE=c0c0c0c0-0000-0000-0000-0000000000a1
CHAUFFEUR=c0c0c0c0-0000-0000-0000-0000000000c1
voyageur() { printf 'c0c0c0c0-0000-0000-0000-00000000000%d' "$1"; }

cleanup() {
  psql_q <<SQL
delete from public.notifications where utilisateur_id::text like 'c0c0c0c0-%';
delete from public.reservations  where passage_id = '$PASSAGE';
delete from public.passages      where id = '$PASSAGE';
delete from public.louages       where id = 'c0c0c0c0-0000-0000-0000-0000000000b1';
delete from auth.users           where id::text like 'c0c0c0c0-%';
delete from public.lignes        where id = 'c0c0c0c0-0000-0000-0000-0000000000d1';
delete from public.stations      where id = 'c0c0c0c0-0000-0000-0000-0000000000e1';
SQL
}

setup() {
  cleanup
  psql_q <<SQL
insert into public.stations (id, nom, ville, code_qr)
values ('c0c0c0c0-0000-0000-0000-0000000000e1', 'Station concurrence', 'Tunis', 'CONC-STATION');
insert into public.lignes (id, station_id, ville_arrivee, tarif)
values ('c0c0c0c0-0000-0000-0000-0000000000d1', 'c0c0c0c0-0000-0000-0000-0000000000e1', 'ConcSousse', 12);
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
select ('c0c0c0c0-0000-0000-0000-00000000000' || i)::uuid, 'conc-voyageur' || i || '@test.local', '{}', '{}'
from generate_series(1, 5) i;
insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data)
values ('$CHAUFFEUR', 'conc-chauffeur@test.local', '{"role":"chauffeur"}', '{}');
insert into public.louages (id, immatriculation, capacite, chauffeur_id)
values ('c0c0c0c0-0000-0000-0000-0000000000b1', 'CONC 001', 8, '$CHAUFFEUR');
-- 6 passagers déjà à bord (sans réservation) → 6/8
insert into public.passages (id, louage_id, ligne_id, etat, places_occupees, capacite, heure_debut_remplissage)
values ('$PASSAGE', 'c0c0c0c0-0000-0000-0000-0000000000b1', 'c0c0c0c0-0000-0000-0000-0000000000d1',
        'EN_REMPLISSAGE', 6, 8, now());
SQL
}

# un appel dans sa propre session : rôle + claims, attente à la barrière, appel
worker() {
  local n="$1" sub call
  if (( n % 2 == 1 )); then
    sub="$(voyageur $(( (n + 1) / 2 )))"
    call="select 'OK' from public.reserver_place('$PASSAGE');"
  else
    sub="$CHAUFFEUR"
    call="select 'OK' from public.modifier_places('$PASSAGE', 1);"
  fi
  docker exec -i "$CONTAINER" psql -U postgres -X -q -tA -v ON_ERROR_STOP=1 >"$TMP/w$n.out" 2>&1 <<SQL || true
set role authenticated;
set request.jwt.claims to '{"sub":"$sub","role":"authenticated"}';
select pg_advisory_lock_shared($LOCK_KEY) is null;
select pg_advisory_unlock_shared($LOCK_KEY) is null;
$call
SQL
}

round() {
  local r="$1"
  setup

  # coordinatrice : prend le verrou, attend les 10 sessions, puis les libère ensemble
  psql_q >"$TMP/coord.out" 2>&1 <<SQL &
select pg_advisory_lock($LOCK_KEY) is null;
do \$\$
declare w int; t0 timestamptz := clock_timestamp();
begin
  loop
    select count(*) into w from pg_locks
    where locktype = 'advisory' and objid = $LOCK_KEY and not granted;
    exit when w >= $WORKERS;
    if clock_timestamp() - t0 > interval '30 s' then
      raise exception 'barrière : seulement % sessions en attente', w;
    end if;
    perform pg_sleep(0.02);
  end loop;
  raise notice 'BARRIERE % sessions en attente', w;
end \$\$;
select pg_advisory_unlock($LOCK_KEY) is null;
SQL
  local coord=$!

  # ne lancer les sessions qu'une fois le verrou pris
  until [[ "$(psql_q -c "select count(*) from pg_locks where locktype='advisory' and objid=$LOCK_KEY and granted")" == 1 ]]; do
    sleep 0.05
  done

  local pids=()
  for n in $(seq 1 $WORKERS); do worker "$n" & pids+=($!); done
  wait "$coord"
  wait "${pids[@]}"

  # résultats
  local ok=0 complet=0 autre=0 ok_resa=0 ok_modif=0
  for n in $(seq 1 $WORKERS); do
    local kind; (( n % 2 == 1 )) && kind="reserver_place " || kind="modifier_places"
    local res
    if grep -qx OK "$TMP/w$n.out"; then
      res=OK; ok=$((ok + 1))
      [[ $kind == reserver* ]] && ok_resa=$((ok_resa + 1)) || ok_modif=$((ok_modif + 1))
    elif grep -q 'ERROR:  LOUAGE_COMPLET' "$TMP/w$n.out"; then
      res=LOUAGE_COMPLET; complet=$((complet + 1))
    else
      res="AUTRE: $(tr '\n' ' ' <"$TMP/w$n.out")"; autre=$((autre + 1))
    fi
    printf '  appel %2d  %s  → %s\n' "$n" "$kind" "$res"
  done

  local etat
  etat="$(psql_q -c "select places_occupees || '/' || capacite || ' ' || etat || ' resa_en_attente=' ||
                       (select count(*) from public.reservations where passage_id = p.id and etat = 'EN_ATTENTE')
                     from public.passages p where id = '$PASSAGE'")"
  local barriere; barriere="$(grep -o 'BARRIERE [0-9]*' "$TMP/coord.out" || echo 'BARRIERE ?')"

  echo "  ${barriere#BARRIERE } sessions libérées ensemble | succès=$ok (reserver=$ok_resa, modifier=$ok_modif) | LOUAGE_COMPLET=$complet | autre=$autre"
  echo "  passage final : $etat"

  local attendu="8/8 COMPLET resa_en_attente=$ok_resa"
  if [[ $ok -eq 2 && $complet -eq 8 && $autre -eq 0 && "$etat" == "$attendu" ]]; then
    echo "  tour $r : OK"
    return 0
  fi
  echo "  tour $r : ÉCHEC (attendu : 2 succès, 8 LOUAGE_COMPLET, « $attendu »)"
  return 1
}

failed=0
for r in $(seq 1 "$ROUNDS"); do
  echo "Tour $r/$ROUNDS — 10 appels simultanés sur un louage à 6/8"
  round "$r" || failed=$((failed + 1))
done
cleanup
echo
if (( failed == 0 )); then
  echo "RÉSULTAT : OK — $ROUNDS/$ROUNDS tours à exactement 8/8 avec exactement 2 succès"
else
  echo "RÉSULTAT : ÉCHEC — $failed/$ROUNDS tours incorrects"
  exit 1
fi
