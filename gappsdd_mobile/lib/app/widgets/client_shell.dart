import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/domain/chat_unread_provider.dart';
import '../router.dart';
import '../theme/app_theme.dart';

/// Shell widget that wraps client tab screens with a persistent bottom nav bar.
class ClientShell extends StatelessWidget {
  const ClientShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _ClientBottomNavBar(
        currentPath: currentPath,
        onVisitsTap: () => context.go(AppRoutes.clientVisits),
        onInboxTap: () => context.go(AppRoutes.clientInbox),
      ),
    );
  }
}

class _ClientBottomNavBar extends ConsumerWidget {
  const _ClientBottomNavBar({
    required this.currentPath,
    required this.onVisitsTap,
    required this.onInboxTap,
  });

  final String currentPath;
  final VoidCallback onVisitsTap;
  final VoidCallback onInboxTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;
    final hasUnread = ref.watch(chatUnreadProvider);
    final isVisitsActive = currentPath.startsWith(AppRoutes.clientVisits);

    final navChild = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: isCupertino ? CupertinoIcons.leaf_arrow_circlepath : Icons.local_florist_rounded,
          label: 'Visits',
          active: isVisitsActive,
          onTap: onVisitsTap,
        ),
        _NavItem(
          icon: isCupertino ? CupertinoIcons.chat_bubble_2 : Icons.chat_bubble_outline_rounded,
          label: 'Inbox',
          active: currentPath.startsWith(AppRoutes.clientInbox),
          dot: hasUnread,
          onTap: onInboxTap,
        ),
        _NavItem(
          icon: isCupertino ? CupertinoIcons.settings : Icons.settings_outlined,
          label: 'Settings',
        ),
      ],
    );

    if (isCupertino) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.82),
              border: Border(
                top: BorderSide(color: AppColors.outline.withValues(alpha: 0.18)),
              ),
            ),
            child: navChild,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x141C1C17),
            blurRadius: 24,
            spreadRadius: -6,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: navChild,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.dot = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool dot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.surface : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: foreground, size: 20),
                if (dot)
                  const Positioned(
                    top: -2,
                    right: -3,
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
