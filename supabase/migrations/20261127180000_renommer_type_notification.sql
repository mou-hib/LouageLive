-- =====================================================================
-- Louage Live — type de notification aligné sur la convention
-- =====================================================================
-- 'reservation_annulee_agent' → 'RESERVATION_ANNULEE_AGENT'
-- (comme TOUR_DE_REMPLIR, RESERVATION_EXPIREE, RESERVATION_ANNULEE).
-- autoriser_depart est identique à 20261127120000_regles_depart.sql
-- sauf le type inséré. create or replace conserve les droits d'exécution.
-- =====================================================================

create or replace function public.autoriser_depart(p_passage_id uuid)
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
  select voyageur_id, 'RESERVATION_ANNULEE_AGENT',
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

-- notifications déjà envoyées avec l'ancien nom
update public.notifications
set type = 'RESERVATION_ANNULEE_AGENT'
where type = 'reservation_annulee_agent';
