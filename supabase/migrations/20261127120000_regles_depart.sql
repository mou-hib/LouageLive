-- =====================================================================
-- Louage Live — règles de réservation et de départ
-- =====================================================================
--  R1  une seule réservation EN_ATTENTE par voyageur (index partiel unique)
--      → RESERVATION_DEJA_EN_COURS (même en cas de course entre 2 appels)
--  R2  1 place par réservation (reserver_place n'a pas de quantité)
--  R3  réservation uniquement sur le louage en tête (EN_REMPLISSAGE)
--      → LOUAGE_PAS_EN_TETE
--  R4  confirmer_depart : seulement si COMPLET (places = capacité)
--      → LOUAGE_PAS_COMPLET ; refus tant qu'une réservation est EN_ATTENTE
--      → RESERVATION_EN_ATTENTE (DETAIL = heure d'expiration, ISO 8601 UTC)
--  R5  autoriser_depart (agent de la ligne) : annule les réservations
--      EN_ATTENTE, libère leurs places, notifie, puis PARTI.
--      Le trigger passage_tete_liberee avance le louage suivant.
--  R6  modifier_places / corriger_places : jamais sous le nombre de
--      réservations comptées (EN_ATTENTE + CONFIRMEE) → PLACES_SOUS_RESERVATIONS
--  R7  annuler_reservation : inchangée (libre tant que EN_ATTENTE, sans pénalité)
--
-- Ordre des verrous inchangé : passage d'abord, puis ses réservations.
-- =====================================================================


-- ---------- R1 : index partiel unique ----------
-- Échoue si la base contient déjà un voyageur avec 2 réservations EN_ATTENTE.
create unique index une_reservation_en_attente_par_voyageur
  on public.reservations (voyageur_id) where etat = 'EN_ATTENTE';


-- ---------- R6 : _fixer_places (code d'erreur renommé) ----------
create or replace function public._fixer_places(p_passage_id uuid, p_places integer)
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
    raise exception 'PLACES_SOUS_RESERVATIONS';
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


-- ---------- R1 / R2 / R3 : reserver_place ----------
create or replace function public.reserver_place(p_passage_id uuid)
returns public.reservations
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
  r public.reservations;
  v_duree integer;
  v_moi uuid := (select auth.uid());
begin
  if public.mon_role() is distinct from 'voyageur' then
    raise exception 'ACCES_REFUSE';
  end if;

  select * into v from public.passages where id = p_passage_id for update;
  if not found then
    raise exception 'RESERVATION_IMPOSSIBLE';
  end if;
  if v.etat = 'COMPLET' or v.places_occupees >= v.capacite then
    raise exception 'LOUAGE_COMPLET';
  end if;
  -- R3 : seul le louage en tête (EN_REMPLISSAGE) accepte des réservations
  if v.etat <> 'EN_REMPLISSAGE' then
    raise exception 'LOUAGE_PAS_EN_TETE';
  end if;

  -- R1 : une seule réservation en attente à la fois ; et pas deux réservations
  -- actives dans le même louage
  if exists (select 1 from public.reservations
             where voyageur_id = v_moi
               and (etat = 'EN_ATTENTE'
                    or (passage_id = v.id and etat = 'CONFIRMEE'))) then
    raise exception 'RESERVATION_DEJA_EN_COURS';
  end if;

  select duree_expiration_reservation_min into v_duree from public.parametres;

  -- R2 : une réservation = une place
  begin
    insert into public.reservations (passage_id, voyageur_id, date_expiration)
    values (v.id, v_moi, now() + make_interval(mins => v_duree))
    returning * into r;
  exception when unique_violation then
    -- deux appels simultanés sur deux louages différents : l'index tranche
    raise exception 'RESERVATION_DEJA_EN_COURS';
  end;

  perform public._fixer_places(v.id, v.places_occupees + 1);
  return r;
end;
$$;


-- ---------- R4 : confirmer_depart ----------
-- Chauffeur du louage (ou agent de la ligne / admin via _peut_gerer).
-- Plus de départ forcé ici : l'agent utilise autoriser_depart.
create or replace function public.confirmer_depart(p_passage_id uuid)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
  v_expiration timestamptz;
begin
  if not public._peut_gerer(p_passage_id) then
    raise exception 'ACCES_REFUSE';
  end if;

  select * into v from public.passages where id = p_passage_id for update;

  if v.etat <> 'COMPLET' or v.places_occupees <> v.capacite then
    raise exception 'LOUAGE_PAS_COMPLET';
  end if;

  -- réservations pas encore scannées : on attend leur embarquement ou
  -- leur expiration (DETAIL = la plus tardive, pour l'afficher dans l'app)
  select max(date_expiration) into v_expiration
  from public.reservations
  where passage_id = v.id and etat = 'EN_ATTENTE';
  if v_expiration is not null then
    raise exception 'RESERVATION_EN_ATTENTE'
      using detail = to_char(v_expiration at time zone 'UTC',
                             'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
  end if;

  update public.passages
  set etat = 'PARTI', heure_depart = now()
  where id = v.id
  returning * into v;          -- le trigger fait avancer le louage suivant

  return v;
end;
$$;


-- ---------- R5 : autoriser_depart (agent de la ligne uniquement) ----------
create function public.autoriser_depart(p_passage_id uuid)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
  n integer;
begin
  if public.mon_role() is distinct from 'agent' then
    raise exception 'ACCES_REFUSE';
  end if;

  select * into v from public.passages where id = p_passage_id for update;
  if not found or v.ligne_id is distinct from public.ma_ligne() then
    raise exception 'ACCES_REFUSE';
  end if;

  if v.etat = 'EN_ATTENTE' then
    raise exception 'LOUAGE_PAS_EN_TETE';
  end if;
  if v.etat not in ('EN_REMPLISSAGE', 'COMPLET') then
    raise exception 'PASSAGE_DEJA_TERMINE';
  end if;

  -- réservations non scannées : annulées (places libérées) + notification
  with ann as (
    update public.reservations
    set etat = 'ANNULEE', date_annulation = now()
    where passage_id = v.id and etat = 'EN_ATTENTE'
    returning voyageur_id, id
  )
  insert into public.notifications (utilisateur_id, type, donnees)
  select voyageur_id, 'reservation_annulee_agent',
         jsonb_build_object('reservation_id', id, 'passage_id', v.id)
  from ann;
  get diagnostics n = row_count;

  update public.passages
  set places_occupees = places_occupees - n,
      etat = 'PARTI',
      heure_depart = now()
  where id = v.id
  returning * into v;          -- le trigger fait avancer le louage suivant

  return v;
end;
$$;

revoke execute on function public.autoriser_depart(uuid) from public, anon;
grant  execute on function public.autoriser_depart(uuid) to authenticated;
