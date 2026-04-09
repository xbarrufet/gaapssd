import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../features/chat/domain/chat_unread_provider.dart';

enum GardenerNavTab { visits, clients, newVisit, chat, config }

/// Shared gardener bottom navigation bar.
/// Uses Riverpod to read unread chat status instead of per-screen FutureBuilder.
class GardenerBottomNavBar extends ConsumerWidget {
  const GardenerBottomNavBar({
    super.key,
    this.activeTab,
    this.onVisitsTap,
    this.onClientsTap,
    required this.onNewVisitTap,
    this.onChatTap,
  });

  final GardenerNavTab? activeTab;
  final VoidCallback? onVisitsTap;
  final VoidCallback? onClientsTap;
  final VoidCallback onNewVisitTap;
  final VoidCallback? onChatTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;
    final hasUnread = ref.watch(chatUnreadProvider);

    final navChild = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _BottomItem(
          icon: isCupertino ? CupertinoIcons.house_fill : Icons.home_rounded,
          label: 'Visita',
          active: activeTab == GardenerNavTab.visits,
          onTap: onVisitsTap,
        ),
        _BottomItem(
          icon: isCupertino ? CupertinoIcons.person_2 : Icons.people_alt_outlined,
          label: 'Clientes',
          active: activeTab == GardenerNavTab.clients,
          onTap: onClientsTap,
        ),
        _BottomItem(
          icon: isCupertino ? CupertinoIcons.qrcode_viewfinder : Icons.qr_code_scanner_rounded,
          label: 'Nueva Visita',
          emphasize: true,
          onTap: onNewVisitTap,
        ),
        _BottomItem(
          icon: isCupertino ? CupertinoIcons.chat_bubble_2 : Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          active: activeTab == GardenerNavTab.chat,
          dot: hasUnread,
          onTap: onChatTap,
        ),
        _BottomItem(
          icon: isCupertino ? CupertinoIcons.settings : Icons.settings_outlined,
          label: 'Config',
          active: activeTab == GardenerNavTab.config,
        ),
      ],
    );

    if (isCupertino) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.82),
              border: Border(
                top: BorderSide(color: AppColors.outline.withValues(alpha: 0.2)),
              ),
            ),
            child: navChild,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: navChild,
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.dot = false,
    this.emphasize = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool dot;
  final bool emphasize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    final isHighlighted = active && !emphasize;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlighted ? AppColors.primaryContainer.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: emphasize ? 44 : null,
                  height: emphasize ? 44 : null,
                  decoration: emphasize
                      ? BoxDecoration(
                          color: const Color(0xFFD6EAB6),
                          borderRadius: BorderRadius.circular(14),
                        )
                      : null,
                  child: Icon(
                    icon,
                    size: emphasize ? 26 : 22,
                    color: emphasize ? AppColors.secondary : color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: emphasize ? AppColors.secondary : color,
                        fontSize: emphasize ? 9 : 10,
                      ),
                ),
              ],
            ),
          ),
          if (dot)
            const Positioned(
              top: 4,
              right: 8,
              child: SizedBox(
                width: 7,
                height: 7,
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
    );
  }
}
