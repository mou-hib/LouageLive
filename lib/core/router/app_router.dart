import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/agent/presentation/agent_home_screen.dart';
import '../../features/auth/data/user_role.dart';
import '../../features/auth/logic/auth_providers.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_error_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/chauffeur/presentation/chauffeur_home_screen.dart';
import '../../features/chauffeur/presentation/chauffeur_placeholder_screen.dart';
import '../../features/chauffeur/presentation/scanner_screen.dart';
import '../../features/voyageur/presentation/voyageur_home_screen.dart';
import '../dev/dev_gallery_screen.dart';

abstract final class AppRoutes {
  static const splash = '/chargement';
  static const login = '/login';
  static const signUp = '/inscription';
  static const profileError = '/erreur-profil';

  /// A8 — forced password change (temporary password set by the admin).
  static const changePassword = '/changer-mdp';
  static const chauffeurScanner = '/chauffeur/scanner';

  /// Placeholders: C1 "Mes départs", C4 "Scanner une réservation" (Step 3e).
  static const chauffeurDeparts = '/chauffeur/departs';
  static const chauffeurScanReservation = '/chauffeur/scanner-reservation';

  /// Widget gallery, registered in debug builds only.
  static const devGallery = '/dev/gallery';
}

/// Redirect rules (BNF-6, UI side only — RLS is the real protection):
/// - session/role loading → splash
/// - not signed in → /login, or /inscription (only reachable signed out)
/// - signed in → the home of the user's role (and its sub-pages, e.g.
///   /chauffeur/scanner), and only that one.
/// - signed in with [mustChangePassword] (profils.doit_changer_mdp) →
///   /changer-mdp before any role home; nothing else is reachable.
/// - profile not loadable → error screen (never a default role). A
///   signed-in status without a role is treated the same way.
String? redirectFor(
  AuthStatus status,
  UserRole? role,
  String location, {
  bool mustChangePassword = false,
}) {
  if (status == AuthStatus.signedOut && location == AppRoutes.signUp) {
    return null;
  }
  final target = switch (status) {
    AuthStatus.loading => AppRoutes.splash,
    AuthStatus.signedOut => AppRoutes.login,
    AuthStatus.profileError => AppRoutes.profileError,
    AuthStatus.signedIn => switch (role) {
      null => AppRoutes.profileError,
      _ when mustChangePassword => AppRoutes.changePassword,
      final role => role.homePath,
    },
  };
  final allowed = location == target || location.startsWith('$target/');
  return allowed ? null : target;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: session,
    redirect: (context, state) =>
        kDebugMode && state.matchedLocation == AppRoutes.devGallery
        ? null
        : redirectFor(
            session.status,
            session.role,
            state.matchedLocation,
            mustChangePassword: session.mustChangePassword,
          ),
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
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileError,
        builder: (context, state) => const ProfileErrorScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: UserRole.voyageur.homePath,
        builder: (context, state) => const VoyageurHomeScreen(),
      ),
      GoRoute(
        path: UserRole.chauffeur.homePath,
        builder: (context, state) => const ChauffeurHomeScreen(),
        routes: [
          GoRoute(
            path: 'scanner',
            builder: (context, state) => const ScannerScreen(),
          ),
          GoRoute(
            path: 'departs',
            builder: (context, state) =>
                ChauffeurPlaceholderScreen(title: (l10n) => l10n.myDepartures),
          ),
          GoRoute(
            path: 'scanner-reservation',
            builder: (context, state) => ChauffeurPlaceholderScreen(
              title: (l10n) => l10n.scanReservation,
            ),
          ),
        ],
      ),
      GoRoute(
        path: UserRole.agent.homePath,
        builder: (context, state) => const AgentHomeScreen(),
      ),
      GoRoute(
        path: UserRole.admin.homePath,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.devGallery,
          builder: (context, state) => const DevGalleryScreen(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
