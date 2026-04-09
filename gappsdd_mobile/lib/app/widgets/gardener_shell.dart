import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import 'gardener_bottom_nav_bar.dart';

/// Shell widget that wraps gardener tab screens with a persistent bottom nav bar.
class GardenerShell extends StatelessWidget {
  const GardenerShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  GardenerNavTab? get _activeTab {
    if (currentPath.startsWith(AppRoutes.gardenerVisits)) return GardenerNavTab.visits;
    if (currentPath.startsWith(AppRoutes.gardenerClients)) return GardenerNavTab.clients;
    if (currentPath.startsWith(AppRoutes.gardenerChat)) return GardenerNavTab.chat;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: GardenerBottomNavBar(
        activeTab: _activeTab,
        onVisitsTap: () => context.go(AppRoutes.gardenerVisits),
        onClientsTap: () => context.go(AppRoutes.gardenerClients),
        onNewVisitTap: () => context.push(AppRoutes.gardenerNewVisit),
        onChatTap: () => context.go(AppRoutes.gardenerChat),
      ),
    );
  }
}
