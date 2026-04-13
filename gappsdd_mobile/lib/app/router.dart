import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/chat/domain/chat_models.dart';
import '../features/chat/presentation/chat_with_request_modes_screen.dart';
import '../features/visits/domain/client_visits_data.dart';
import '../features/visits/presentation/assigned_gardens_visit_status_screen.dart';
import '../features/visits/presentation/client_visits_screen.dart';
import '../features/visits/presentation/gardener_visit_details_screen.dart';
import '../features/visits/presentation/gardener_visits_list_screen.dart';
import '../features/visits/presentation/new_visit_screen.dart';
import '../features/visits/presentation/visit_heatmap_screen.dart';
import '../features/visits/presentation/visit_report_screen.dart';
import 'nav_keys.dart';
import 'providers.dart';
import 'widgets/client_shell.dart';
import 'widgets/gardener_shell.dart';

/// ChangeNotifier that bridges Riverpod auth state → GoRouter refreshListenable.
/// Ensures the router is created once and redirects re-run on auth changes,
/// without recreating the GoRouter (which causes duplicate GlobalKey errors).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState?>(authProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;

  AuthState? get _auth => _ref.read(authProvider);
  bool get isLoggedIn => _auth != null;
  bool get isClient => _auth?.isClient ?? false;
}

/// Route path constants.
abstract final class AppRoutes {
  static const login = '/login';

  // Gardener shell
  static const gardenerVisits = '/gardener/visits';
  static const gardenerClients = '/gardener/clients';
  static const gardenerChat = '/gardener/chat';

  // Gardener full-screen (no bottom nav)
  static const gardenerNewVisit = '/gardener/new-visit';
  static const gardenerVisitDetail = '/gardener/visit-detail';

  // Client shell
  static const clientVisits = '/client/visits';
  static const clientInbox = '/client/inbox';

  // Client full-screen
  static const clientVisitReport = '/client/visit-report';

  // Shared full-screen
  static const visitHeatmap = '/visit-heatmap';
}

// Navigator keys are declared in nav_keys.dart to avoid circular imports.

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isOnLogin = state.matchedLocation == AppRoutes.login;

      if (!notifier.isLoggedIn && !isOnLogin) return AppRoutes.login;
      if (notifier.isLoggedIn && isOnLogin) {
        return notifier.isClient ? AppRoutes.clientVisits : AppRoutes.gardenerVisits;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Gardener shell (bottom nav) ──
      ShellRoute(
        navigatorKey: gardenerShellKey,
        builder: (context, state, child) => GardenerShell(
          currentPath: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.gardenerVisits,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GardenerVisitsListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.gardenerClients,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AssignedGardensVisitStatusScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.gardenerChat,
            pageBuilder: (context, state) => NoTransitionPage(
              child: Builder(builder: (context) {
                final container = ProviderScope.containerOf(context);
                final authState = container.read(authProvider);
                final chatRepo = container.read(chatRepositoryProvider);
                return ChatWithRequestModesScreen(
                  repository: chatRepo,
                  conversationId: 'conv-default',
                  currentUserId: authState?.userId ?? 'gardener-001',
                  currentUserRole: MessageRole.gardener,
                );
              }),
            ),
          ),
        ],
      ),

      // ── Gardener full-screen routes (no bottom nav) ──
      GoRoute(
        path: AppRoutes.gardenerNewVisit,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NewVisitScreen(),
      ),
      GoRoute(
        path: AppRoutes.gardenerVisitDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return GardenerVisitDetailsScreen(
            garden: extra['garden'] as AssignedGardenVisitStatus,
            selectedVisitId: extra['selectedVisitId'] as String?,
          );
        },
      ),

      // ── Client shell (bottom nav) ──
      ShellRoute(
        navigatorKey: clientShellKey,
        builder: (context, state, child) => ClientShell(
          currentPath: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.clientVisits,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ClientVisitsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.clientInbox,
            pageBuilder: (context, state) => NoTransitionPage(
              child: Builder(builder: (context) {
                final container = ProviderScope.containerOf(context);
                final authState = container.read(authProvider);
                final chatRepo = container.read(chatRepositoryProvider);
                return ChatWithRequestModesScreen(
                  repository: chatRepo,
                  conversationId: 'conv-default',
                  currentUserId: authState?.userId ?? 'client-001',
                  currentUserRole: MessageRole.client,
                );
              }),
            ),
          ),
        ],
      ),

      // ── Shared full-screen routes ──
      GoRoute(
        path: AppRoutes.visitHeatmap,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => VisitHeatmapScreen(visitId: state.extra as String),
      ),

      // ── Client full-screen routes ──
      GoRoute(
        path: AppRoutes.clientVisitReport,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          // extra can be a VisitSummary (from visits list) or a String visitId
          // (from a push notification tap).
          final extra = state.extra;
          final String visitId;
          if (extra is VisitSummary) {
            visitId = extra.id;
          } else {
            visitId = extra as String;
          }
          return VisitReportScreen(visitId: visitId);
        },
      ),
    ],
  );
});
