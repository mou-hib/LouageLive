import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/agent/presentation/agent_home_screen.dart';
import '../../features/auth/data/user_role.dart';
import '../../features/auth/logic/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/chauffeur/presentation/chauffeur_home_screen.dart';
import '../../features/voyageur/presentation/voyageur_home_screen.dart';

abstract final class AppRoutes {
  static const splash = '/chargement';
  static const login = '/login';
}

/// Redirect rules (BNF-6, UI side only — RLS is the real protection):
/// - session/role loading → splash
/// - not signed in → /login
/// - signed in → the home of the user's role, and only that one.
String? redirectFor(AuthStatus status, UserRole? role, String location) {
  final target = switch (status) {
    AuthStatus.loading => AppRoutes.splash,
    AuthStatus.signedOut => AppRoutes.login,
    AuthStatus.signedIn => (role ?? UserRole.voyageur).homePath,
  };
  return location == target ? null : target;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) =>
        redirectFor(session.status, session.role, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: UserRole.voyageur.homePath,
        builder: (context, state) => const VoyageurHomeScreen(),
      ),
      GoRoute(
        path: UserRole.chauffeur.homePath,
        builder: (context, state) => const ChauffeurHomeScreen(),
      ),
      GoRoute(
        path: UserRole.agent.homePath,
        builder: (context, state) => const AgentHomeScreen(),
      ),
      GoRoute(
        path: UserRole.admin.homePath,
        builder: (context, state) => const AdminHomeScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
