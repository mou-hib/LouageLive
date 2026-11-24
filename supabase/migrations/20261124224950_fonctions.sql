-- =====================================================================
-- Louage Live — 3/4 : fonctions métier (RPC) — BNF-2
-- =====================================================================
-- Toutes les modifications de places / file / réservations passent ici.
-- Chaque fonction verrouille la ligne "passages" concernée (FOR UPDATE)
-- avant de modifier : deux actions simultanées sont traitées l'une après
-- l'autre, donc impossible de dépasser la capacité (9e place bloquée).
--
-- Quand une fonction touche un passage ET ses réservations, elle verrouille
-- toujours le passage d'abord, puis la réservation (même ordre = pas de deadlock).
--
-- Les erreurs sont des CODES (ex. 'LOUAGE_COMPLET') : le client Flutter
-- les traduit en FR/AR via les fichiers ARB.
-- Appel depuis Flutter : supabase.rpc('modifier_places', params: {...})
-- =====================================================================


-- ---------------------------------------------------------------------
-- Fonctions internes (non appelables par le client)
-- ---------------------------------------------------------------------

-- notification (le texte est construit côté client)
create function public._notifier(p_utilisateur uuid, p_type text, p_donnees jsonb default '{}'::jsonb)
returns void
language sql security definer set search_path = ''
as $$
  insert into public.notifications (utilisateur_id, type, donnees)
  values (p_utilisateur, p_type, p_donnees);
$$;

-- l'utilisateur courant peut-il gérer ce passage ?
-- (chauffeur du louage, agent de la ligne, ou admin)
create function public._peut_gerer(p_passage_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.passages p
    join public.louages lo on lo.id = p.louage_id
    where p.id = p_passage_id
      and (   lo.chauffeur_id = (select auth.uid())
           or (public.mon_role() = 'agent' and p.ligne_id = public.ma_ligne())
           or public.mon_role() = 'admin')
  );
$$;

-- fixe le nombre de places d'un passage en tête de file, et son état
-- (COMPLET si plein, EN_REMPLISSAGE sinon). Le passage doit déjà être verrouillé.
create function public._fixer_places(p_passage_id uuid, p_places integer)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
  v_reservees integer;
begin
  select * into v from public.passages where id = p_passage_id for update;

  if v.etat not in ('EN_REMPLISSAGE', 'COMPLET') then
    raise exception 'PASSAGE_PAS_EN_REMPLISSAGE';
  end if;
  if p_places > v.capacite then
    raise exception 'LOUAGE_COMPLET';
  end if;
  if p_places < 0 then
    raise exception 'PLACES_HORS_LIMITES';
  end if;

  -- on ne peut pas descendre sous le nombre de places réservées
  select count(*) into v_reservees
  from public.reservations
  where passage_id = v.id and etat in ('EN_ATTENTE', 'CONFIRMEE');
  if p_places < v_reservees then
    raise exception 'PLACES_RESERVEES';
  end if;

  update public.passages
  set places_occupees = p_places,
      etat = case when p_places = v.capacite
                  then 'COMPLET'::public.etat_passage
                  else 'EN_REMPLISSAGE'::public.etat_passage end,
      heure_complet = case when p_places = v.capacite
                           then coalesce(v.heure_complet, now()) end
  where id = v.id
  returning * into v;

  return v;
end;
$$;

-- S1 / S3 : si la ligne n'a pas de tête, le plus ancien EN_ATTENTE passe EN_REMPLISSAGE
create function public._avancer_file(p_ligne_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_suivant public.passages;
  v_chauffeur uuid;
begin
  perform 1 from public.lignes where id = p_ligne_id for update;  -- sérialise par ligne

  if exists (select 1 from public.passages
             where ligne_id = p_ligne_id and etat in ('EN_REMPLISSAGE', 'COMPLET')) then
    return;
  end if;

  select * into v_suivant
  from public.passages
  where ligne_id = p_ligne_id and etat = 'EN_ATTENTE'
  order by heure_entree, id
  limit 1
  for update;

  if not found then
    return;
  end if;

  update public.passages
  set etat = 'EN_REMPLISSAGE', heure_debut_remplissage = now()
  where id = v_suivant.id;

  select chauffeur_id into v_chauffeur from public.louages where id = v_suivant.louage_id;
  if v_chauffeur is not null then
    perform public._notifier(v_chauffeur, 'TOUR_DE_REMPLIR',
                             jsonb_build_object('passage_id', v_suivant.id, 'ligne_id', p_ligne_id));
  end if;
end;
$$;

-- déclencheur : quand la tête part (PARTI) ou est retirée (RETIRE), on avance la file
create function public._trg_avancer_file()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public._avancer_file(new.ligne_id);
  return null;
end;
$$;

create trigger passage_tete_liberee
  after update of etat on public.passages
  for each row
  when (old.etat in ('EN_REMPLISSAGE', 'COMPLET') and new.etat in ('PARTI', 'RETIRE'))
  execute function public._trg_avancer_file();


-- ---------------------------------------------------------------------
-- RPC Chauffeur
-- ---------------------------------------------------------------------

-- C2 : rejoindre la file en scannant le QR de la station + choix de la ligne
create function public.rejoindre_file(p_code_station text, p_ligne_id uuid)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v_louage public.louages;
  v_passage public.passages;
begin
  if public.mon_role() is distinct from 'chauffeur' then
    raise exception 'ACCES_REFUSE';
  end if;

  select * into v_louage from public.louages
  where chauffeur_id = (select auth.uid()) and actif;
  if not found then
    raise exception 'AUCUN_LOUAGE';
  end if;

  perform 1
  from public.lignes l
  join public.stations s on s.id = l.station_id
  where l.id = p_ligne_id and s.code_qr = p_code_station and l.actif and s.actif
  for update of l;
  if not found then
    raise exception 'QR_STATION_INVALIDE';
  end if;

  if exists (select 1 from public.passages
             where louage_id = v_louage.id and etat in ('EN_ATTENTE', 'EN_REMPLISSAGE', 'COMPLET')) then
    raise exception 'DEJA_EN_FILE';
  end if;

  insert into public.passages (louage_id, ligne_id, capacite)
  values (v_louage.id, p_ligne_id, v_louage.capacite)
  returning * into v_passage;

  perform public._avancer_file(p_ligne_id);

  select * into v_passage from public.passages where id = v_passage.id;
  return v_passage;
end;
$$;

-- C3 : +1 / -1 passager (aussi utilisable par l'agent de la ligne)
create function public.modifier_places(p_passage_id uuid, p_delta integer)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
begin
  if p_delta not in (-1, 1) then
    raise exception 'DELTA_INVALIDE';
  end if;
  if not public._peut_gerer(p_passage_id) then
    raise exception 'ACCES_REFUSE';
  end if;

  select * into v from public.passages where id = p_passage_id for update;
  return public._fixer_places(v.id, v.places_occupees + p_delta);
end;
$$;

-- C6 : confirmer le départ (louage complet)
create function public.confirmer_depart(p_passage_id uuid)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
begin
  if not public._peut_gerer(p_passage_id) then
    raise exception 'ACCES_REFUSE';
  end if;

  select * into v from public.passages where id = p_passage_id for update;

  -- le chauffeur part seulement à COMPLET ; l'agent/admin peut forcer depuis EN_REMPLISSAGE
  if not (v.etat = 'COMPLET'
          or (v.etat = 'EN_REMPLISSAGE' and public.mon_role() in ('agent', 'admin'))) then
    raise exception 'LOUAGE_PAS_COMPLET';
  end if;

  -- réservations jamais scannées : expirées
  with exp as (
    update public.reservations
    set etat = 'EXPIREE'
    where passage_id = v.id and etat = 'EN_ATTENTE'
    returning voyageur_id, id
  )
  insert into public.notifications (utilisateur_id, type, donnees)
  select voyageur_id, 'RESERVATION_EXPIREE', jsonb_build_object('reservation_id', id) from exp;

  update public.passages
  set etat = 'PARTI', heure_depart = now()
  where id = v.id
  returning * into v;          -- le trigger fait avancer le louage suivant

  return v;
end;
$$;

-- C4 : scanner le QR d'une réservation à l'embarquement
create function public.scanner_reservation(p_code_qr text)
returns public.reservations
language plpgsql security definer set search_path = ''
as $$
declare
  v_passage_id uuid;
  r public.reservations;
begin
  select passage_id into v_passage_id from public.reservations where code_qr = p_code_qr;
  if not found then
    raise exception 'QR_RESERVATION_INVALIDE';
  end if;
  if not public._peut_gerer(v_passage_id) then
    raise exception 'RESERVATION_AUTRE_LOUAGE';
  end if;

  perform 1 from public.passages where id = v_passage_id for update;
  select * into r from public.reservations where code_qr = p_code_qr for update;

  if r.etat = 'CONFIRMEE' then raise exception 'RESERVATION_DEJA_SCANNEE'; end if;
  if r.etat = 'ANNULEE'   then raise exception 'RESERVATION_ANNULEE';      end if;
  if r.etat = 'EXPIREE' or r.date_expiration < now() then
    raise exception 'RESERVATION_EXPIREE';
  end if;

  update public.reservations
  set etat = 'CONFIRMEE', date_confirmation = now()
  where id = r.id
  returning * into r;

  return r;
end;
$$;


-- ---------------------------------------------------------------------
-- RPC Voyageur
-- ---------------------------------------------------------------------

-- V5 : réserver une place dans le louage en tête de file
create function public.reserver_place(p_passage_id uuid)
returns public.reservations
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
  r public.reservations;
  v_duree integer;
begin
  if public.mon_role() is distinct from 'voyageur' then
    raise exception 'ACCES_REFUSE';
  end if;

  select * into v from public.passages where id = p_passage_id for update;
  if found and (v.etat = 'COMPLET' or v.places_occupees >= v.capacite) then
    raise exception 'LOUAGE_COMPLET';
  end if;
  if not found or v.etat <> 'EN_REMPLISSAGE' then
    raise exception 'RESERVATION_IMPOSSIBLE';
  end if;

  -- une seule réservation en attente à la fois par voyageur (anti-abus)
  if exists (select 1 from public.reservations
             where voyageur_id = (select auth.uid()) and etat = 'EN_ATTENTE') then
    raise exception 'RESERVATION_DEJA_ACTIVE';
  end if;

  select duree_expiration_reservation_min into v_duree from public.parametres;

  insert into public.reservations (passage_id, voyageur_id, date_expiration)
  values (v.id, (select auth.uid()), now() + make_interval(mins => v_duree))
  returning * into r;

  perform public._fixer_places(v.id, v.places_occupees + 1);
  return r;
end;
$$;

-- V6 : annuler sa réservation (seulement si pas encore scannée)
create function public.annuler_reservation(p_reservation_id uuid)
returns public.reservations
language plpgsql security definer set search_path = ''
as $$
declare
  v_passage_id uuid;
  v public.passages;
  r public.reservations;
begin
  select passage_id into v_passage_id
  from public.reservations
  where id = p_reservation_id and voyageur_id = (select auth.uid());
  if not found then
    raise exception 'RESERVATION_INTROUVABLE';
  end if;

  select * into v from public.passages where id = v_passage_id for update;
  select * into r from public.reservations where id = p_reservation_id for update;

  if r.etat <> 'EN_ATTENTE' then
    raise exception 'ANNULATION_IMPOSSIBLE';
  end if;

  update public.reservations
  set etat = 'ANNULEE', date_annulation = now()
  where id = r.id
  returning * into r;

  if v.etat in ('EN_REMPLISSAGE', 'COMPLET') then
    perform public._fixer_places(v.id, v.places_occupees - 1);
  end if;

  return r;
end;
$$;


-- ---------------------------------------------------------------------
-- RPC Agent de station
-- ---------------------------------------------------------------------

-- A3 : corriger le nombre de places (valeur exacte)
create function public.corriger_places(p_passage_id uuid, p_places integer)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
begin
  if public.mon_role() not in ('agent', 'admin') or not public._peut_gerer(p_passage_id) then
    raise exception 'ACCES_REFUSE';
  end if;
  perform 1 from public.passages where id = p_passage_id for update;
  return public._fixer_places(p_passage_id, p_places);
end;
$$;

-- A4 : retirer un louage de la file
create function public.retirer_louage(p_passage_id uuid)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
begin
  if public.mon_role() not in ('agent', 'admin') or not public._peut_gerer(p_passage_id) then
    raise exception 'ACCES_REFUSE';
  end if;

  select * into v from public.passages where id = p_passage_id for update;
  if v.etat not in ('EN_ATTENTE', 'EN_REMPLISSAGE', 'COMPLET') then
    raise exception 'PASSAGE_DEJA_TERMINE';
  end if;

  with ann as (
    update public.reservations
    set etat = 'ANNULEE', date_annulation = now()
    where passage_id = v.id and etat = 'EN_ATTENTE'
    returning voyageur_id, id
  )
  insert into public.notifications (utilisateur_id, type, donnees)
  select voyageur_id, 'RESERVATION_ANNULEE', jsonb_build_object('reservation_id', id) from ann;

  update public.passages
  set etat = 'RETIRE', heure_retrait = now()
  where id = v.id
  returning * into v;          -- si c'était la tête, le trigger avance la file

  return v;
end;
$$;

-- A5 / D4 : mettre en file le louage d'un chauffeur sans smartphone
create function public.ajouter_louage_en_file(p_louage_id uuid, p_ligne_id uuid)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v_louage public.louages;
  v_passage public.passages;
begin
  if not (public.mon_role() = 'admin'
          or (public.mon_role() = 'agent' and public.ma_ligne() = p_ligne_id)) then
    raise exception 'ACCES_REFUSE';
  end if;

  perform 1 from public.lignes where id = p_ligne_id and actif for update;
  if not found then
    raise exception 'LIGNE_INVALIDE';
  end if;

  select * into v_louage from public.louages where id = p_louage_id and actif;
  if not found then
    raise exception 'AUCUN_LOUAGE';
  end if;

  if exists (select 1 from public.passages
             where louage_id = v_louage.id and etat in ('EN_ATTENTE', 'EN_REMPLISSAGE', 'COMPLET')) then
    raise exception 'DEJA_EN_FILE';
  end if;

  insert into public.passages (louage_id, ligne_id, capacite, ajoute_par)
  values (v_louage.id, p_ligne_id, v_louage.capacite, (select auth.uid()))
  returning * into v_passage;

  perform public._avancer_file(p_ligne_id);

  select * into v_passage from public.passages where id = v_passage.id;
  return v_passage;
end;
$$;


-- ---------------------------------------------------------------------
-- RPC commun
-- ---------------------------------------------------------------------

-- A8 : après le changement de mot de passe à la 1re connexion
create function public.marquer_mdp_change()
returns void
language sql security definer set search_path = ''
as $$
  update public.profils set doit_changer_mdp = false where id = (select auth.uid());
$$;


-- ---------------------------------------------------------------------
-- Système (S4) : expiration des réservations — appelé par pg_cron
-- ---------------------------------------------------------------------
create function public.expirer_reservations()
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_passage_id uuid;
  v public.passages;
  n integer;
  total integer := 0;
begin
  for v_passage_id in
    select distinct passage_id from public.reservations
    where etat = 'EN_ATTENTE' and date_expiration < now()
    order by passage_id
  loop
    select * into v from public.passages where id = v_passage_id for update;

    with exp as (
      update public.reservations
      set etat = 'EXPIREE'
      where passage_id = v_passage_id and etat = 'EN_ATTENTE' and date_expiration < now()
      returning voyageur_id, id
    )
    insert into public.notifications (utilisateur_id, type, donnees)
    select voyageur_id, 'RESERVATION_EXPIREE', jsonb_build_object('reservation_id', id) from exp;
    get diagnostics n = row_count;

    if n > 0 and v.etat in ('EN_REMPLISSAGE', 'COMPLET') then
      perform public._fixer_places(v.id, v.places_occupees - n);
    end if;

    total := total + n;
  end loop;
  return total;
end;
$$;


-- ---------------------------------------------------------------------
-- Droits d'exécution
-- ---------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon, authenticated;

-- utilisées dans les policies RLS
grant execute on function public.mon_role()  to authenticated;
grant execute on function public.ma_ligne()  to authenticated;

-- RPC appelables par l'app
grant execute on function public.rejoindre_file(text, uuid)          to authenticated;
grant execute on function public.modifier_places(uuid, integer)      to authenticated;
grant execute on function public.confirmer_depart(uuid)              to authenticated;
grant execute on function public.scanner_reservation(text)           to authenticated;
grant execute on function public.reserver_place(uuid)                to authenticated;
grant execute on function public.annuler_reservation(uuid)           to authenticated;
grant execute on function public.corriger_places(uuid, integer)      to authenticated;
grant execute on function public.retirer_louage(uuid)                to authenticated;
grant execute on function public.ajouter_louage_en_file(uuid, uuid)  to authenticated;
grant execute on function public.marquer_mdp_change()                to authenticated;
-- les fonctions _internes et expirer_reservations() restent fermées au client
