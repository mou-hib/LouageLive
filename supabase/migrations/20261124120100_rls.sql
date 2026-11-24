-- =====================================================================
-- Louage Live — 2/4 : sécurité (RLS + droits) — BNF-6
-- =====================================================================
-- Principe : le client LIT les tables (selon son rôle) mais n'ÉCRIT
-- presque jamais directement. Toute écriture métier passe par les
-- fonctions RPC du fichier 3/4.
-- =====================================================================

-- ---------- Fonctions d'aide (utilisées dans les policies) ----------
create function public.mon_role()
returns public.role_utilisateur
language sql stable security definer set search_path = ''
as $$
  select role from public.profils where id = (select auth.uid()) and actif;
$$;

create function public.ma_ligne()
returns uuid
language sql stable security definer set search_path = ''
as $$
  select ligne_id from public.profils
  where id = (select auth.uid()) and role = 'agent' and actif;
$$;

-- ---------- Activer RLS partout ----------
alter table public.stations      enable row level security;
alter table public.lignes        enable row level security;
alter table public.profils       enable row level security;
alter table public.louages       enable row level security;
alter table public.passages      enable row level security;
alter table public.reservations  enable row level security;
alter table public.notifications enable row level security;
alter table public.parametres    enable row level security;

-- ---------- Droits de base ----------
-- anon (non connecté) : rien. L'app exige une connexion.
revoke all on all tables in schema public from anon;

-- tables écrites uniquement par les RPC
revoke insert, update, delete on public.passages, public.reservations, public.notifications
  from authenticated;

-- profils : l'utilisateur ne peut modifier QUE ces colonnes (pas role, ni ligne_id, ni actif)
revoke insert, update, delete on public.profils from authenticated;
grant update (nom, prenom, telephone, langue) on public.profils to authenticated;

-- notifications : seulement marquer comme lu
grant update (lu) on public.notifications to authenticated;

-- ---------- profils ----------
create policy profils_lecture on public.profils
  for select to authenticated
  using (id = (select auth.uid()) or public.mon_role() in ('agent', 'admin'));

create policy profils_modif_soi on public.profils
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- ---------- stations ----------
create policy stations_lecture on public.stations
  for select to authenticated
  using (actif or public.mon_role() = 'admin');

create policy stations_admin on public.stations
  for all to authenticated
  using (public.mon_role() = 'admin')
  with check (public.mon_role() = 'admin');

-- ---------- lignes ----------
create policy lignes_lecture on public.lignes
  for select to authenticated
  using (actif or public.mon_role() = 'admin');

create policy lignes_admin on public.lignes
  for all to authenticated
  using (public.mon_role() = 'admin')
  with check (public.mon_role() = 'admin');

-- ---------- louages ----------
-- l'immatriculation est visible sur la voiture : lecture pour tous les connectés
create policy louages_lecture on public.louages
  for select to authenticated
  using (true);

create policy louages_admin on public.louages
  for all to authenticated
  using (public.mon_role() = 'admin')
  with check (public.mon_role() = 'admin');

-- l'agent peut ajouter un louage pour un chauffeur (D5)
create policy louages_ajout_agent on public.louages
  for insert to authenticated
  with check (public.mon_role() = 'agent' and cree_par = (select auth.uid()));

-- ---------- passages (la file est une information publique) ----------
create policy passages_lecture on public.passages
  for select to authenticated
  using (true);

-- ---------- réservations ----------
create policy reservations_lecture on public.reservations
  for select to authenticated
  using (
    voyageur_id = (select auth.uid())
    or public.mon_role() = 'admin'
    or exists (
      select 1
      from public.passages p
      join public.louages lo on lo.id = p.louage_id
      where p.id = reservations.passage_id
        and (lo.chauffeur_id = (select auth.uid())
             or (public.mon_role() = 'agent' and p.ligne_id = public.ma_ligne()))
    )
  );

-- ---------- notifications ----------
create policy notifications_lecture on public.notifications
  for select to authenticated
  using (utilisateur_id = (select auth.uid()));

create policy notifications_marquer_lu on public.notifications
  for update to authenticated
  using (utilisateur_id = (select auth.uid()))
  with check (utilisateur_id = (select auth.uid()));

-- ---------- paramètres ----------
create policy parametres_lecture on public.parametres
  for select to authenticated
  using (true);

create policy parametres_admin on public.parametres
  for update to authenticated
  using (public.mon_role() = 'admin')
  with check (public.mon_role() = 'admin');
