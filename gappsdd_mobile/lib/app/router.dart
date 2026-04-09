import 'package:flutter/material.dart';
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
import '../features/visits/presentation/visit_report_screen.dart';
import 'providers.dart';
import 'widgets/client_shell.dart';
import 'widgets/gardener_shell.dart';

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
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _gardenerShellKey = GlobalKey<NavigatorState>();
final _clientShellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isLoggedIn = auth != null;
      final isOnLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isOnLogin) return AppRoutes.login;
      if (isLoggedIn && isOnLogin) {
        return auth.isClient ? AppRoutes.clientVisits : AppRoutes.gardenerVisits;
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
        navigatorKey: _gardenerShellKey,
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
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewVisitScreen(),
      ),
      GoRoute(
        path: AppRoutes.gardenerVisitDetail,
        parentNavigatorKey: _rootNavigatorKey,
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
        navigatorKey: _clientShellKey,
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

      // ── Client full-screen routes ──
      GoRoute(
        path: AppRoutes.clientVisitReport,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final visit = state.extra as VisitSummary;
          return VisitReportScreen(visit: visit);
        },
      ),
    ],
  );
});
