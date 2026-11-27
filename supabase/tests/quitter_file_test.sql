-- =====================================================================
-- Tests : quitter_file (migrations etat_quitte + quitter_file)
-- Lancer : supabase test db
-- Tout s'exécute dans une transaction annulée à la fin.
-- Les appels RPC et les SELECT se font en rôle `authenticated` avec
-- request.jwt.claims (auth.uid()), comme depuis l'app.
-- =====================================================================
begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

-- ---------------------------------------------------------------------
-- Données (superuser)
-- ---------------------------------------------------------------------
-- ligne L1 : P1 (chauffeur1, tête)  P2 (chauffeur2, rang 2)  P3 (chauffeur3, rang 3)
--            P0 (chauffeur2, ancien passage PARTI)
-- agent1 → L1 ; voyageur1
insert into public.stations (id, nom, ville, code_qr) values
  ('eeeeeeee-0000-0000-0000-000000000001', 'Station test', 'Tunis', 'TEST-STATION');
insert into public.lignes (id, station_id, ville_arrivee, tarif) values
  ('ffffffff-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 'TestSousse', 12);

insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'voyageur1@test.local', '{}', '{}'),
  ('cccccccc-0000-0000-0000-000000000001', 'chauffeur1@test.local', '{"role":"chauffeur"}', '{}'),
  ('cccccccc-0000-0000-0000-000000000002', 'chauffeur2@test.local', '{"role":"chauffeur"}', '{}'),
  ('cccccccc-0000-0000-0000-000000000003', 'chauffeur3@test.local', '{"role":"chauffeur"}', '{}'),
  ('dddddddd-0000-0000-0000-000000000001', 'agent1@test.local',
     '{"role":"agent","ligne_id":"ffffffff-0000-0000-0000-000000000001"}', '{}');

insert into public.louages (id, immatriculation, capacite, chauffeur_id) values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'T 001', 8, 'cccccccc-0000-0000-0000-000000000001'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'T 002', 8, 'cccccccc-0000-0000-0000-000000000002'),
  ('bbbbbbbb-0000-0000-0000-000000000003', 'T 003', 8, 'cccccccc-0000-0000-0000-000000000003');

insert into public.passages (id, louage_id, ligne_id, etat, capacite, heure_entree, heure_debut_remplissage, heure_depart) values
  ('99999999-0000-0000-0000-000000000000', 'bbbbbbbb-0000-0000-0000-000000000002',
   'ffffffff-0000-0000-0000-000000000001', 'PARTI',          8, now() - interval '2 h', now() - interval '2 h', now() - interval '1 h'),
  ('99999999-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001',
   'ffffffff-0000-0000-0000-000000000001', 'EN_REMPLISSAGE', 8, now() - interval '10 min', now(), null),
  ('99999999-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002',
   'ffffffff-0000-0000-0000-000000000001', 'EN_ATTENTE',     8, now() - interval '5 min', null, null),
  ('99999999-0000-0000-0000-000000000003', 'bbbbbbbb-0000-0000-0000-000000000003',
   'ffffffff-0000-0000-0000-000000000001', 'EN_ATTENTE',     8, now() - interval '3 min', null, null);

-- ---------------------------------------------------------------------
-- Structure
-- ---------------------------------------------------------------------
select ok('QUITTE' = any (enum_range(null::public.etat_passage)::text[]),
          'etat_passage has QUITTE');
select has_function('public', 'quitter_file', array['uuid'], 'quitter_file(uuid) exists');
select ok(not has_function_privilege('anon', 'public.quitter_file(uuid)', 'execute'),
          'quitter_file: not executable by anon');
select ok(has_function_privilege('authenticated', 'public.quitter_file(uuid)', 'execute'),
          'quitter_file: executable by authenticated');
select ok((select prosecdef and proconfig @> array['search_path=""']
           from pg_proc where oid = 'public.quitter_file(uuid)'::regprocedure),
          'quitter_file: SECURITY DEFINER + search_path');

-- Toutes les étapes suivantes en rôle authenticated
set local role authenticated;

-- =====================================================================
-- Qui peut appeler : seulement le chauffeur du passage
-- =====================================================================
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok($$select public.quitter_file('99999999-0000-0000-0000-000000000002')$$,
  'P0001', 'ACCES_REFUSE', 'voyageur → ACCES_REFUSE');

set local request.jwt.claims to '{"sub":"dddddddd-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok($$select public.quitter_file('99999999-0000-0000-0000-000000000002')$$,
  'P0001', 'ACCES_REFUSE', 'agent of the line → ACCES_REFUSE (agents use retirer_louage)');

set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000003","role":"authenticated"}';
select throws_ok($$select public.quitter_file('99999999-0000-0000-0000-000000000002')$$,
  'P0001', 'ACCES_REFUSE', 'another chauffeur''s passage → ACCES_REFUSE');
select throws_ok($$select public.quitter_file('99999999-0000-0000-0000-0000000000ff')$$,
  'P0001', 'ACCES_REFUSE', 'unknown passage → ACCES_REFUSE (no existence leak)');
select is((select etat::text from public.passages where id = '99999999-0000-0000-0000-000000000002'),
  'EN_ATTENTE', 'refused calls change nothing');

-- No direct write either (rule: RPC only)
select throws_ok($$update public.passages set etat = 'QUITTE'
                   where id = '99999999-0000-0000-0000-000000000003'$$,
  '42501', null, 'chauffeur cannot UPDATE passages directly');

-- =====================================================================
-- La tête ne peut pas quitter
-- =====================================================================
set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok($$select public.quitter_file('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'QUITTER_IMPOSSIBLE_EN_TETE', 'head (EN_REMPLISSAGE) → QUITTER_IMPOSSIBLE_EN_TETE');
select is((select etat::text from public.passages where id = '99999999-0000-0000-0000-000000000001'),
  'EN_REMPLISSAGE', 'head is unchanged');

-- =====================================================================
-- chauffeur2 quitte depuis le rang 2
-- =====================================================================
set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000002","role":"authenticated"}';
select is((select rang from public.file_attente where passage_id = '99999999-0000-0000-0000-000000000003'),
  3::bigint, 'before: chauffeur3 is 3rd');

select is((public.quitter_file('99999999-0000-0000-0000-000000000002')).etat::text,
  'QUITTE', 'chauffeur2 leaves: RPC returns the QUITTE passage');
select is((select etat::text from public.passages where id = '99999999-0000-0000-0000-000000000002'),
  'QUITTE', 'passage is QUITTE (plain SELECT as chauffeur2)');
select isnt((select heure_retrait from public.passages where id = '99999999-0000-0000-0000-000000000002'),
  null, 'heure_retrait is set');
select is((select count(*) from public.file_attente
           where passage_id = '99999999-0000-0000-0000-000000000002'),
  0::bigint, 'QUITTE passage is out of file_attente');
select is((select count(*) from public.file_attente
           where ligne_id = 'ffffffff-0000-0000-0000-000000000001'),
  2::bigint, 'queue has 2 louages left');
select is((select rang from public.file_attente where passage_id = '99999999-0000-0000-0000-000000000003'),
  2::bigint, 'after: chauffeur3 moved up to 2nd');
select is((select rang from public.file_attente where passage_id = '99999999-0000-0000-0000-000000000001'),
  1::bigint, 'head keeps rank 1');

select throws_ok($$select public.quitter_file('99999999-0000-0000-0000-000000000002')$$,
  'P0001', 'PASSAGE_DEJA_TERMINE', 'leaving twice → PASSAGE_DEJA_TERMINE');
select throws_ok($$select public.quitter_file('99999999-0000-0000-0000-000000000000')$$,
  'P0001', 'PASSAGE_DEJA_TERMINE', 'old PARTI passage → PASSAGE_DEJA_TERMINE');

-- QUITTE frees the louage: it can join again, at the end of the queue
select lives_ok($$select public.rejoindre_file('TEST-STATION', 'ffffffff-0000-0000-0000-000000000001')$$,
  'chauffeur2 can rejoin after leaving');
select is((select rang from public.file_attente fa
           join public.louages lo on lo.id = fa.louage_id
           where lo.immatriculation = 'T 002'),
  3::bigint, 'rejoined at the end (3rd)');

-- =====================================================================
-- Quand la tête part, la file avance sans le passage QUITTE
-- =====================================================================
set local request.jwt.claims to '{"sub":"dddddddd-0000-0000-0000-000000000001","role":"authenticated"}';
select lives_ok($$select public.retirer_louage('99999999-0000-0000-0000-000000000001')$$,
  'agent removes the head');
select is((select etat::text from public.passages where id = '99999999-0000-0000-0000-000000000003'),
  'EN_REMPLISSAGE', 'chauffeur3 (next waiting) becomes the head');
select is((select etat::text from public.passages where id = '99999999-0000-0000-0000-000000000002'),
  'QUITTE', 'the QUITTE passage is never promoted');

select * from finish();
rollback;
