-- =====================================================================
-- Louage Live — 1/4 : schéma (types, tables, contraintes, vue)
-- =====================================================================
-- Règles clés appliquées ici, au niveau de la base :
--   * un louage ne peut être que dans UNE file à la fois ;
--   * une ligne n'a qu'UN louage en tête (EN_REMPLISSAGE ou COMPLET) ;
--   * jamais plus de places que la capacité (BNF-2, aussi vérifié dans les RPC).
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------- Types ----------
create type public.role_utilisateur as enum ('voyageur', 'chauffeur', 'agent', 'admin');
create type public.etat_passage     as enum ('EN_ATTENTE', 'EN_REMPLISSAGE', 'COMPLET', 'PARTI', 'RETIRE');
create type public.etat_reservation as enum ('EN_ATTENTE', 'CONFIRMEE', 'ANNULEE', 'EXPIREE');
create type public.langue           as enum ('fr', 'ar');

-- ---------- Stations ----------
create table public.stations (
  id          uuid primary key default gen_random_uuid(),
  nom         text not null,
  ville       text not null,
  adresse     text,
  latitude    double precision,
  longitude   double precision,
  -- contenu du QR code imprimé dans la station (scanné par le chauffeur)
  code_qr     text not null unique default encode(extensions.gen_random_bytes(12), 'hex'),
  actif       boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ---------- Lignes (ville de départ = ville de la station) ----------
create table public.lignes (
  id             uuid primary key default gen_random_uuid(),
  station_id     uuid not null references public.stations(id) on delete restrict,
  ville_arrivee  text not null,
  tarif          numeric(7,3) not null check (tarif >= 0),   -- en TND (3 décimales = millimes)
  actif          boolean not null default true,
  created_at     timestamptz not null default now(),
  unique (station_id, ville_arrivee)
);

-- ---------- Profils (1 ligne par compte auth.users) ----------
create table public.profils (
  id                uuid primary key references auth.users(id) on delete cascade,
  nom               text,
  prenom            text,
  telephone         text,
  role              public.role_utilisateur not null default 'voyageur',
  ligne_id          uuid references public.lignes(id) on delete restrict,  -- agent : sa ligne
  langue            public.langue not null default 'fr',
  doit_changer_mdp  boolean not null default false,
  actif             boolean not null default true,
  created_at        timestamptz not null default now(),
  constraint agent_a_une_ligne check (role <> 'agent' or ligne_id is not null)
);

-- ---------- Louages (le véhicule physique) ----------
create table public.louages (
  id              uuid primary key default gen_random_uuid(),
  immatriculation text not null unique,
  capacite        smallint not null default 8 check (capacite between 1 and 8),
  chauffeur_id    uuid references public.profils(id) on delete set null,
  cree_par        uuid references public.profils(id) on delete set null,
  actif           boolean not null default true,
  created_at      timestamptz not null default now()
);
-- un chauffeur conduit un seul louage actif
create unique index un_louage_actif_par_chauffeur
  on public.louages (chauffeur_id) where actif and chauffeur_id is not null;

-- ---------- Passages (un séjour d'un louage dans la file d'une ligne) ----------
create table public.passages (
  id                       uuid primary key default gen_random_uuid(),
  louage_id                uuid not null references public.louages(id) on delete restrict,
  ligne_id                 uuid not null references public.lignes(id) on delete restrict,
  etat                     public.etat_passage not null default 'EN_ATTENTE',
  places_occupees          smallint not null default 0 check (places_occupees between 0 and 8),
  capacite                 smallint not null default 8 check (capacite between 1 and 8),
  heure_entree             timestamptz not null default now(),
  heure_debut_remplissage  timestamptz,
  heure_complet            timestamptz,
  heure_depart             timestamptz,
  heure_retrait            timestamptz,
  ajoute_par               uuid references public.profils(id) on delete set null, -- agent qui a ajouté le louage (D4)
  constraint places_max check (places_occupees <= capacite)
);
-- un louage n'est que dans une seule file active
create unique index un_passage_actif_par_louage
  on public.passages (louage_id) where etat in ('EN_ATTENTE', 'EN_REMPLISSAGE', 'COMPLET');
-- une seule tête de file par ligne
create unique index une_tete_par_ligne
  on public.passages (ligne_id) where etat in ('EN_REMPLISSAGE', 'COMPLET');
create index passages_file_idx on public.passages (ligne_id, etat, heure_entree);

-- ---------- Réservations ----------
create table public.reservations (
  id                 uuid primary key default gen_random_uuid(),
  passage_id         uuid not null references public.passages(id) on delete restrict,
  voyageur_id        uuid not null references public.profils(id) on delete cascade,
  code_qr            text not null unique default encode(extensions.gen_random_bytes(16), 'hex'),
  etat               public.etat_reservation not null default 'EN_ATTENTE',
  date_creation      timestamptz not null default now(),
  date_expiration    timestamptz not null,
  date_confirmation  timestamptz,
  date_annulation    timestamptz,
  constraint expiration_apres_creation check (date_expiration > date_creation)
);
create unique index une_reservation_active_par_passage
  on public.reservations (passage_id, voyageur_id) where etat in ('EN_ATTENTE', 'CONFIRMEE');
create index reservations_a_expirer_idx
  on public.reservations (date_expiration) where etat = 'EN_ATTENTE';
create index reservations_voyageur_idx on public.reservations (voyageur_id, date_creation desc);

-- ---------- Notifications ----------
-- Pas de texte stocké : le client traduit (FR/AR) à partir de "type" + "donnees".
create table public.notifications (
  id              uuid primary key default gen_random_uuid(),
  utilisateur_id  uuid not null references public.profils(id) on delete cascade,
  type            text not null,     -- ex. 'TOUR_DE_REMPLIR', 'RESERVATION_EXPIREE', 'RESERVATION_ANNULEE'
  donnees         jsonb not null default '{}'::jsonb,
  lu              boolean not null default false,
  created_at      timestamptz not null default now()
);
create index notifications_utilisateur_idx on public.notifications (utilisateur_id, lu, created_at desc);

-- ---------- Paramètres (une seule ligne) ----------
create table public.parametres (
  id                                boolean primary key default true check (id),
  duree_expiration_reservation_min  integer not null default 20 check (duree_expiration_reservation_min > 0)
);
insert into public.parametres default values;

-- ---------- Vue : file d'attente d'une ligne (rang 1 = tête) ----------
create view public.file_attente with (security_invoker = true) as
select
  p.id               as passage_id,
  p.ligne_id,
  p.louage_id,
  lo.immatriculation,
  p.etat,
  p.places_occupees,
  p.capacite,
  p.heure_entree,
  p.heure_debut_remplissage,
  row_number() over (
    partition by p.ligne_id
    order by (p.etat in ('EN_REMPLISSAGE', 'COMPLET')) desc, p.heure_entree, p.id
  ) as rang
from public.passages p
join public.louages lo on lo.id = p.louage_id
where p.etat in ('EN_ATTENTE', 'EN_REMPLISSAGE', 'COMPLET');

-- ---------- Création automatique du profil à l'inscription ----------
-- Le rôle vient de raw_APP_meta_data (modifiable seulement côté serveur / service_role).
-- Un voyageur qui s'inscrit ne peut donc PAS se donner le rôle admin.
create function public.creer_profil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role public.role_utilisateur :=
    coalesce((new.raw_app_meta_data ->> 'role')::public.role_utilisateur, 'voyageur');
begin
  insert into public.profils (id, nom, prenom, telephone, role, ligne_id, doit_changer_mdp)
  values (
    new.id,
    new.raw_user_meta_data ->> 'nom',
    new.raw_user_meta_data ->> 'prenom',
    new.raw_user_meta_data ->> 'telephone',
    v_role,
    nullif(new.raw_app_meta_data ->> 'ligne_id', '')::uuid,
    v_role <> 'voyageur'          -- comptes créés par l'admin : mot de passe à changer
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.creer_profil();
