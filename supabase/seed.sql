-- =====================================================================
-- Louage Live — données de test Sprint 1
-- =====================================================================
-- À coller dans Supabase > SQL Editor (db push n'exécute PAS ce fichier).
-- Tarifs = valeurs de TEST, pas les tarifs officiels.
-- =====================================================================

-- ---------- PARTIE 1 : stations et lignes ----------
insert into public.stations (id, nom, ville, code_qr) values
  ('00000000-0000-0000-0000-00000000a001', 'Station Moncef Bey', 'Tunis',  'STATION-TUNIS-MONCEFBEY'),
  ('00000000-0000-0000-0000-00000000a002', 'Station Sousse',     'Sousse', 'STATION-SOUSSE');

insert into public.lignes (id, station_id, ville_arrivee, tarif) values
  ('00000000-0000-0000-0000-00000000b001', '00000000-0000-0000-0000-00000000a001', 'Sousse', 12.000),
  ('00000000-0000-0000-0000-00000000b002', '00000000-0000-0000-0000-00000000a001', 'Sfax',   20.000),
  ('00000000-0000-0000-0000-00000000b003', '00000000-0000-0000-0000-00000000a001', 'Nabeul',  6.000),
  ('00000000-0000-0000-0000-00000000b004', '00000000-0000-0000-0000-00000000a002', 'Tunis',  12.000);


-- ---------- PARTIE 2 : comptes de test ----------
-- 1) Créer d'abord les comptes dans Dashboard > Authentication > Add user
--    (cocher "Auto Confirm User") :
--      admin@louage.test, agent1@louage.test,
--      chauffeur1@louage.test, chauffeur2@louage.test, chauffeur3@louage.test,
--      voyageur1@louage.test
--    Le trigger crée leur profil avec le rôle 'voyageur'.
-- 2) Puis exécuter ce bloc pour donner les rôles et créer les louages :

update public.profils set role = 'admin', nom = 'Admin', prenom = 'Test'
where id = (select id from auth.users where email = 'admin@louage.test');

update public.profils
set role = 'agent', ligne_id = '00000000-0000-0000-0000-00000000b001', nom = 'Agent', prenom = 'Tunis-Sousse'
where id = (select id from auth.users where email = 'agent1@louage.test');

update public.profils set role = 'chauffeur', nom = 'Chauffeur', prenom = 'Un'
where id = (select id from auth.users where email = 'chauffeur1@louage.test');
update public.profils set role = 'chauffeur', nom = 'Chauffeur', prenom = 'Deux'
where id = (select id from auth.users where email = 'chauffeur2@louage.test');
update public.profils set role = 'chauffeur', nom = 'Chauffeur', prenom = 'Trois'
where id = (select id from auth.users where email = 'chauffeur3@louage.test');

insert into public.louages (immatriculation, chauffeur_id)
select v.immat, u.id
from (values ('101 TU 1001', 'chauffeur1@louage.test'),
             ('102 TU 1002', 'chauffeur2@louage.test'),
             ('103 TU 1003', 'chauffeur3@louage.test')) as v(immat, email)
join auth.users u on u.email = v.email;
