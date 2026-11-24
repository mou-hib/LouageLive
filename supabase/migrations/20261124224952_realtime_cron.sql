-- =====================================================================
-- Louage Live — 4/4 : temps réel (BNF-1) + tâche planifiée (S4)
-- =====================================================================

-- Realtime : le client s'abonne aux changements (filtrés par RLS)
alter publication supabase_realtime add table public.passages, public.reservations, public.notifications;

-- pg_cron : expiration des réservations chaque minute
-- (si erreur : activer "Cron" dans Dashboard > Integrations, puis relancer ce fichier)
create extension if not exists pg_cron;

select cron.schedule(
  'expirer-reservations',
  '* * * * *',
  $$select public.expirer_reservations()$$
);
