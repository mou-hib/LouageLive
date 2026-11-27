-- =====================================================================
-- Louage Live — quitter_file : le chauffeur sort lui-même de la file (C3)
-- =====================================================================
--  * seulement le chauffeur du louage du passage → sinon ACCES_REFUSE
--    (aussi pour un passage inconnu : on ne révèle pas qu'il existe) ;
--  * seulement EN_ATTENTE :
--      EN_REMPLISSAGE / COMPLET (en tête) → QUITTER_IMPOSSIBLE_EN_TETE
--      PARTI / RETIRE / QUITTE (terminé)  → PASSAGE_DEJA_TERMINE
--  * passe le passage à QUITTE (heure_retrait = maintenant).
--
-- Pas de réservation à traiter : reserver_place n'accepte que la tête
-- (EN_REMPLISSAGE), un passage EN_ATTENTE n'en a jamais.
-- Pas de trigger d'avance de file : le passage n'était pas la tête.
--
-- Verrous : la ligne puis le passage, dans le même ordre que
-- _avancer_file et rejoindre_file. Une promotion en tête simultanée est
-- donc soit faite avant (→ QUITTER_IMPOSSIBLE_EN_TETE), soit faite après
-- et elle choisit alors le louage suivant.
-- =====================================================================

create function public.quitter_file(p_passage_id uuid)
returns public.passages
language plpgsql security definer set search_path = ''
as $$
declare
  v public.passages;
  v_ligne_id uuid;
begin
  if public.mon_role() is distinct from 'chauffeur' then
    raise exception 'ACCES_REFUSE';
  end if;

  select p.ligne_id into v_ligne_id
  from public.passages p
  join public.louages lo on lo.id = p.louage_id
  where p.id = p_passage_id
    and lo.chauffeur_id = (select auth.uid());
  if not found then
    raise exception 'ACCES_REFUSE';
  end if;

  perform 1 from public.lignes where id = v_ligne_id for update;
  select * into v from public.passages where id = p_passage_id for update;

  if v.etat in ('EN_REMPLISSAGE', 'COMPLET') then
    raise exception 'QUITTER_IMPOSSIBLE_EN_TETE';
  end if;
  if v.etat <> 'EN_ATTENTE' then
    raise exception 'PASSAGE_DEJA_TERMINE';
  end if;

  update public.passages
  set etat = 'QUITTE', heure_retrait = now()
  where id = v.id
  returning * into v;

  return v;
end;
$$;

comment on column public.passages.heure_retrait is
  'Sortie de la file : RETIRE (par un agent) ou QUITTE (par le chauffeur).';

revoke execute on function public.quitter_file(uuid) from public, anon;
grant  execute on function public.quitter_file(uuid) to authenticated;
