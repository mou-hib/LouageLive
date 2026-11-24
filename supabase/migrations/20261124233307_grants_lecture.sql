-- Lecture pour les utilisateurs connectés ; RLS filtre les lignes.
-- Les écritures passent par les RPC (BNF-2) ; aucun droit pour anon.
grant select on
  public.stations, public.lignes, public.profils, public.louages,
  public.passages, public.reservations, public.notifications,
  public.parametres, public.file_attente
to authenticated;
