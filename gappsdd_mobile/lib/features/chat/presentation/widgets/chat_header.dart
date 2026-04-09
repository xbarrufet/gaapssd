import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/chat_models.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.thread,
    required this.onBackTap,
    required this.onTapContactSwitcher,
  });

  final ChatThread thread;
  final VoidCallback onBackTap;
  final VoidCallback onTapContactSwitcher;

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    return GestureDetector(
      onTap: onTapContactSwitcher,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          border: Border(bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBackTap,
              icon: Icon(isCupertino ? CupertinoIcons.back : Icons.arrow_back_rounded),
              color: AppColors.primary,
            ),
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: thread.contactAvatarUrl.isNotEmpty
                      ? Image.network(
                          thread.contactAvatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
                        )
                      : const Icon(Icons.person_rounded),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread.contactName, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    thread.contactRole.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
            Icon(
              isCupertino ? CupertinoIcons.chevron_down : Icons.expand_more,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
