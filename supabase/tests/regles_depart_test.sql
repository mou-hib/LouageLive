-- =====================================================================
-- Tests : règles de réservation et de départ (migration regles_depart)
-- Lancer : supabase test db
-- Tout s'exécute dans une transaction annulée à la fin.
-- Les appels RPC et les SELECT se font en rôle `authenticated` avec
-- request.jwt.claims (auth.uid()), comme depuis l'app.
-- =====================================================================
begin;
create extension if not exists pgtap with schema extensions;
select plan(69);

-- ---------------------------------------------------------------------
-- Données (superuser)
-- ---------------------------------------------------------------------
-- voyageurs  aaaaaaaa-…-00000000000{1,2,3}
-- chauffeurs cccccccc-…-00000000000{1,2,3}
-- agents     dddddddd-…-00000000000{1,2}   (agent1 → ligne L1, agent2 → L2)
-- ligne L1 : P1 (louage chauffeur1, tête, capacité 3), P2 (chauffeur2, en attente)
-- ligne L2 : P3 (louage chauffeur3, tête, capacité 2)
insert into public.stations (id, nom, ville, code_qr) values
  ('eeeeeeee-0000-0000-0000-000000000001', 'Station test', 'Tunis', 'TEST-STATION');
insert into public.lignes (id, station_id, ville_arrivee, tarif) values
  ('ffffffff-0000-0000-0000-000000000001', 'eeeeeeee-0000-0000-0000-000000000001', 'TestSousse', 12),
  ('ffffffff-0000-0000-0000-000000000002', 'eeeeeeee-0000-0000-0000-000000000001', 'TestSfax',   20);

insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'voyageur1@test.local', '{}', '{}'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'voyageur2@test.local', '{}', '{}'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'voyageur3@test.local', '{}', '{}'),
  ('cccccccc-0000-0000-0000-000000000001', 'chauffeur1@test.local', '{"role":"chauffeur"}', '{}'),
  ('cccccccc-0000-0000-0000-000000000002', 'chauffeur2@test.local', '{"role":"chauffeur"}', '{}'),
  ('cccccccc-0000-0000-0000-000000000003', 'chauffeur3@test.local', '{"role":"chauffeur"}', '{}'),
  ('dddddddd-0000-0000-0000-000000000001', 'agent1@test.local',
     '{"role":"agent","ligne_id":"ffffffff-0000-0000-0000-000000000001"}', '{}'),
  ('dddddddd-0000-0000-0000-000000000002', 'agent2@test.local',
     '{"role":"agent","ligne_id":"ffffffff-0000-0000-0000-000000000002"}', '{}');

insert into public.louages (id, immatriculation, capacite, chauffeur_id) values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'T 001', 3, 'cccccccc-0000-0000-0000-000000000001'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'T 002', 8, 'cccccccc-0000-0000-0000-000000000002'),
  ('bbbbbbbb-0000-0000-0000-000000000003', 'T 003', 2, 'cccccccc-0000-0000-0000-000000000003');

insert into public.passages (id, louage_id, ligne_id, etat, capacite, heure_entree, heure_debut_remplissage) values
  ('99999999-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001',
   'ffffffff-0000-0000-0000-000000000001', 'EN_REMPLISSAGE', 3, now() - interval '10 min', now()),
  ('99999999-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002',
   'ffffffff-0000-0000-0000-000000000001', 'EN_ATTENTE',     8, now() - interval '5 min', null),
  ('99999999-0000-0000-0000-000000000003', 'bbbbbbbb-0000-0000-0000-000000000003',
   'ffffffff-0000-0000-0000-000000000002', 'EN_REMPLISSAGE', 2, now() - interval '10 min', now());

-- ---------------------------------------------------------------------
-- Structure
-- ---------------------------------------------------------------------
select has_index('public', 'reservations', 'une_reservation_en_attente_par_voyageur',
                 'R1: partial unique index exists');
select ok(not has_function_privilege('anon', 'public.autoriser_depart(uuid)', 'execute'),
          'autoriser_depart: not executable by anon');
select ok(has_function_privilege('authenticated', 'public.autoriser_depart(uuid)', 'execute'),
          'autoriser_depart: executable by authenticated');
select ok((select prosecdef and proconfig @> array['search_path=""']
           from pg_proc where oid = 'public.autoriser_depart(uuid)'::regprocedure),
          'autoriser_depart: SECURITY DEFINER + search_path');

-- Toutes les étapes suivantes en rôle authenticated
set local role authenticated;

-- =====================================================================
-- voyageur1
-- =====================================================================
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}';

-- R3 : P2 n'est pas en tête
select throws_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000002')$$,
  'P0001', 'LOUAGE_PAS_EN_TETE', 'R3: booking a waiting louage → LOUAGE_PAS_EN_TETE');

-- R2 : une réservation = +1 place
select lives_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000001')$$,
  'R3: booking the head louage works');
select is((select places_occupees from public.passages where id = '99999999-0000-0000-0000-000000000001'),
  1::smallint, 'R2: one reservation = exactly one seat');
select is((select count(*) from public.reservations where etat = 'EN_ATTENTE'),
  1::bigint, 'RLS: voyageur1 sees their pending reservation');

-- R1
select throws_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'RESERVATION_DEJA_EN_COURS', 'R1: second booking same louage → RESERVATION_DEJA_EN_COURS');
select throws_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000003')$$,
  'P0001', 'RESERVATION_DEJA_EN_COURS', 'R1: second booking other line → RESERVATION_DEJA_EN_COURS');
select is((select places_occupees from public.passages where id = '99999999-0000-0000-0000-000000000003'),
  0::smallint, 'R1: refused booking did not take a seat');

-- RLS / droits : pas d'écriture directe
select throws_ok($$insert into public.reservations (passage_id, voyageur_id, date_expiration)
                   values ('99999999-0000-0000-0000-000000000003',
                           'aaaaaaaa-0000-0000-0000-000000000001', now() + interval '1 h')$$,
  '42501', null, 'RLS: voyageur cannot INSERT a reservation directly');
select throws_ok($$update public.passages set places_occupees = 0$$,
  '42501', null, 'RLS: voyageur cannot UPDATE passages directly');
select throws_ok($$select public._fixer_places('99999999-0000-0000-0000-000000000001', 0)$$,
  '42501', null, 'internal _fixer_places is not callable by the client');
select throws_ok($$select public.autoriser_depart('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'ACCES_REFUSE', 'R5: voyageur → ACCES_REFUSE');
select is((select count(*) from public.passages
           where ligne_id = 'ffffffff-0000-0000-0000-000000000001'),
  2::bigint, 'RLS: voyageur can read the queue (passages)');
select is((select count(*) from public.file_attente
           where ligne_id = 'ffffffff-0000-0000-0000-000000000001'),
  2::bigint, 'RLS: voyageur can read file_attente');

-- R1 au niveau base : même en contournant la RPC, l'index refuse
reset role;
select throws_ok($$insert into public.reservations (passage_id, voyageur_id, date_expiration)
                   values ('99999999-0000-0000-0000-000000000003',
                           'aaaaaaaa-0000-0000-0000-000000000001', now() + interval '1 h')$$,
  '23505', null, 'R1: index rejects a 2nd pending reservation even outside the RPC');
set local role authenticated;
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}';

-- R7 : annulation libre, place libérée, sans pénalité
select lives_ok($$select public.annuler_reservation(
                   (select id from public.reservations where etat = 'EN_ATTENTE'))$$,
  'R7: voyageur cancels a pending reservation');
select is((select places_occupees from public.passages where id = '99999999-0000-0000-0000-000000000001'),
  0::smallint, 'R7: cancelled seat is freed');
select is((select etat::text from public.reservations), 'ANNULEE', 'R7: reservation is ANNULEE');
select is((select count(*) from public.notifications), 0::bigint, 'R7: no notification / penalty');
select lives_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000001')$$,
  'R7: voyageur can book again right away (no penalty)');
select throws_ok($$select public.annuler_reservation(
                   (select id from public.reservations where etat = 'ANNULEE'))$$,
  'P0001', 'ANNULATION_IMPOSSIBLE', 'R7: cancelling a non-pending reservation is refused');
do $$ begin
  perform set_config('test.resa_v1',
    (select id::text from public.reservations where etat = 'EN_ATTENTE'), true);
end $$;

-- =====================================================================
-- voyageur2 : ne voit pas les réservations des autres, ne peut pas les annuler
-- =====================================================================
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000002","role":"authenticated"}';
select is((select count(*) from public.reservations), 0::bigint,
  'RLS: voyageur2 sees no reservation of voyageur1');
select is((select count(*) from public.reservations
           where id = current_setting('test.resa_v1')::uuid), 0::bigint,
  'RLS: voyageur2 cannot read voyageur1''s reservation by id');
select throws_ok($$select public.annuler_reservation(current_setting('test.resa_v1')::uuid)$$,
  'P0001', 'RESERVATION_INTROUVABLE', 'R7: cannot cancel someone else''s reservation');

-- =====================================================================
-- chauffeur1 : R6 et R4 (pas complet)
-- =====================================================================
set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000001","role":"authenticated"}';
select is((select count(*) from public.reservations), 2::bigint,
  'RLS: chauffeur1 sees the reservations on their louage (1 ANNULEE + 1 EN_ATTENTE)');
select is((public.modifier_places('99999999-0000-0000-0000-000000000001', 1)).places_occupees,
  2::smallint, 'R6: +1 walk-in passenger → 2');
select is((public.modifier_places('99999999-0000-0000-0000-000000000001', -1)).places_occupees,
  1::smallint, 'R6: -1 back to the reservation count → 1');
select throws_ok($$select public.modifier_places('99999999-0000-0000-0000-000000000001', -1)$$,
  'P0001', 'PLACES_SOUS_RESERVATIONS', 'R6: modifier_places below reservations → PLACES_SOUS_RESERVATIONS');
select throws_ok($$select public.confirmer_depart('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'LOUAGE_PAS_COMPLET', 'R4: chauffeur departs while not full → LOUAGE_PAS_COMPLET');
select throws_ok($$select public.autoriser_depart('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'ACCES_REFUSE', 'R5: chauffeur → ACCES_REFUSE');

-- =====================================================================
-- agent1 : R6 (corriger) et plus de départ forcé via confirmer_depart
-- =====================================================================
set local request.jwt.claims to '{"sub":"dddddddd-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok($$select public.corriger_places('99999999-0000-0000-0000-000000000001', 0)$$,
  'P0001', 'PLACES_SOUS_RESERVATIONS', 'R6: corriger_places below reservations → PLACES_SOUS_RESERVATIONS');
select throws_ok($$select public.confirmer_depart('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'LOUAGE_PAS_COMPLET', 'R4: agent can no longer force confirmer_depart when not full');

-- voyageur2 réserve sur P1 → 2/3
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000002","role":"authenticated"}';
select lives_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000001')$$,
  'voyageur2 books P1');

-- chauffeur1 scanne voyageur1 → CONFIRMEE
set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000001","role":"authenticated"}';
select is((public.scanner_reservation(
            (select code_qr from public.reservations
             where voyageur_id = 'aaaaaaaa-0000-0000-0000-000000000001' and etat = 'EN_ATTENTE'))).etat::text,
  'CONFIRMEE', 'chauffeur1 scans voyageur1');

-- voyageur1 (CONFIRMEE dans P1) ne peut pas re-réserver P1
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'RESERVATION_DEJA_EN_COURS', 'R1: confirmed in this louage → RESERVATION_DEJA_EN_COURS');

-- R6 : CONFIRMEE + EN_ATTENTE comptent (2)
set local request.jwt.claims to '{"sub":"dddddddd-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok($$select public.corriger_places('99999999-0000-0000-0000-000000000001', 1)$$,
  'P0001', 'PLACES_SOUS_RESERVATIONS', 'R6: CONFIRMEE + EN_ATTENTE both counted');
select is((public.corriger_places('99999999-0000-0000-0000-000000000001', 2)).places_occupees,
  2::smallint, 'R6: corriger_places to exactly the reservation count works');
select is((select count(*) from public.reservations
           where passage_id = '99999999-0000-0000-0000-000000000001'),
  3::bigint, 'RLS: agent1 sees reservations on their line (ANNULEE + CONFIRMEE + EN_ATTENTE)');

-- chauffeur1 : +1 → COMPLET, mais voyageur2 pas encore scanné
set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000001","role":"authenticated"}';
select is((public.modifier_places('99999999-0000-0000-0000-000000000001', 1)).etat::text,
  'COMPLET', 'P1 is COMPLET (3/3)');
select throws_ok($$select public.modifier_places('99999999-0000-0000-0000-000000000001', 1)$$,
  'P0001', 'LOUAGE_COMPLET', 'no 4th seat on a 3-seat louage');

-- R4 : RESERVATION_EN_ATTENTE + heure d'expiration dans DETAIL
do $$
declare m text; d text;
begin
  perform public.confirmer_depart('99999999-0000-0000-0000-000000000001');
  perform set_config('test.msg', 'PAS_D_ERREUR', true);
exception when others then
  get stacked diagnostics m = message_text, d = pg_exception_detail;
  perform set_config('test.msg', m, true);
  perform set_config('test.detail', coalesce(d, ''), true);
end $$;
select is(current_setting('test.msg'), 'RESERVATION_EN_ATTENTE',
  'R4: full but a reservation is pending → RESERVATION_EN_ATTENTE');
select is(current_setting('test.detail')::timestamptz,
  (select date_expiration from public.reservations
   where passage_id = '99999999-0000-0000-0000-000000000001' and etat = 'EN_ATTENTE'),
  'R4: error DETAIL = expiry time of the pending reservation');
select matches(current_setting('test.detail'),
  '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$', 'R4: DETAIL is ISO 8601 UTC');
select is((select etat::text from public.passages where id = '99999999-0000-0000-0000-000000000001'),
  'COMPLET', 'R4: refused departure left P1 COMPLET');

-- chauffeur2 n'est pas le chauffeur de P1
set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000002","role":"authenticated"}';
select throws_ok($$select public.confirmer_depart('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'ACCES_REFUSE', 'confirmer_depart by another chauffeur → ACCES_REFUSE');
select is((select count(*) from public.reservations), 0::bigint,
  'RLS: chauffeur2 sees no reservation of P1');

-- =====================================================================
-- R5 : autoriser_depart
-- =====================================================================
-- agent2 : autre ligne
set local request.jwt.claims to '{"sub":"dddddddd-0000-0000-0000-000000000002","role":"authenticated"}';
select throws_ok($$select public.autoriser_depart('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'ACCES_REFUSE', 'R5: agent of another line → ACCES_REFUSE');
select is((select count(*) from public.reservations
           where passage_id = '99999999-0000-0000-0000-000000000001'),
  0::bigint, 'RLS: agent2 sees no reservation of line L1');

-- agent1
set local request.jwt.claims to '{"sub":"dddddddd-0000-0000-0000-000000000001","role":"authenticated"}';
select throws_ok($$select public.autoriser_depart('99999999-0000-0000-0000-000000000002')$$,
  'P0001', 'LOUAGE_PAS_EN_TETE', 'R5: louage not at the head → LOUAGE_PAS_EN_TETE');
select is((public.autoriser_depart('99999999-0000-0000-0000-000000000001')).etat::text,
  'PARTI', 'R5: agent1 authorises departure → PARTI');
select is((select places_occupees from public.passages where id = '99999999-0000-0000-0000-000000000001'),
  2::smallint, 'R5: the pending seat was freed (3 → 2)');
select is((select etat::text from public.reservations
           where voyageur_id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  'ANNULEE', 'R5: pending reservation → ANNULEE');
select is((select etat::text from public.reservations
           where voyageur_id = 'aaaaaaaa-0000-0000-0000-000000000001' and etat <> 'ANNULEE'),
  'CONFIRMEE', 'R5: confirmed reservation untouched');
select is((select etat::text from public.passages where id = '99999999-0000-0000-0000-000000000002'),
  'EN_REMPLISSAGE', 'R5: trigger advanced the next louage (P2 → EN_REMPLISSAGE)');
select throws_ok($$select public.autoriser_depart('99999999-0000-0000-0000-000000000001')$$,
  'P0001', 'PASSAGE_DEJA_TERMINE', 'R5: already departed → PASSAGE_DEJA_TERMINE');
select is((select count(*) from public.notifications), 0::bigint,
  'RLS: agent1 does not see voyageur notifications');

-- voyageur2 : notification reçue, et peut réserver à nouveau (P2 en tête)
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000002","role":"authenticated"}';
select is((select type from public.notifications), 'reservation_annulee_agent',
  'R5: voyageur2 got a reservation_annulee_agent notification');
select is((select donnees ->> 'passage_id' from public.notifications),
  '99999999-0000-0000-0000-000000000001', 'R5: notification carries the passage id');
select lives_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000002')$$,
  'R5: voyageur2 can book the new head louage');

-- voyageur1 ne voit pas la notification de voyageur2
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}';
select is((select count(*) from public.notifications), 0::bigint,
  'RLS: voyageur1 does not see voyageur2''s notification');

-- chauffeur2 : notifié que c'est son tour
set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000002","role":"authenticated"}';
select is((select type from public.notifications), 'TOUR_DE_REMPLIR',
  'R5: chauffeur2 notified TOUR_DE_REMPLIR');

-- =====================================================================
-- R4 chemin normal (ligne L2) : complet + tout scanné → PARTI
-- =====================================================================
set local request.jwt.claims to '{"sub":"aaaaaaaa-0000-0000-0000-000000000003","role":"authenticated"}';
select lives_ok($$select public.reserver_place('99999999-0000-0000-0000-000000000003')$$,
  'voyageur3 books P3');

set local request.jwt.claims to '{"sub":"cccccccc-0000-0000-0000-000000000003","role":"authenticated"}';
select is((public.modifier_places('99999999-0000-0000-0000-000000000003', 1)).etat::text,
  'COMPLET', 'P3 is COMPLET (2/2)');
select throws_ok($$select public.confirmer_depart('99999999-0000-0000-0000-000000000003')$$,
  'P0001', 'RESERVATION_EN_ATTENTE', 'R4: pending reservation blocks departure');
select lives_ok($$select public.scanner_reservation(
                   (select code_qr from public.reservations where etat = 'EN_ATTENTE'))$$,
  'chauffeur3 scans voyageur3');
select is((public.confirmer_depart('99999999-0000-0000-0000-000000000003')).etat::text,
  'PARTI', 'R4: full and nothing pending → PARTI');

select * from finish();
rollback;
