import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../theme/app_theme.dart';

/// Circular avatar button showing the user's initial.
/// Tapping opens [ProfileSheet].
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final auth = ref.read(authProvider);

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => ProfileSheet(
          name: displayName,
          email: auth?.email ?? '',
          initial: initial,
          onLogout: () async {
            Navigator.of(context).pop();
            await ref.read(authProvider.notifier).signOut();
          },
        ),
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with profile info and logout.
class ProfileSheet extends StatelessWidget {
  const ProfileSheet({
    super.key,
    required this.name,
    required this.email,
    required this.initial,
    required this.onLogout,
  });

  final String name;
  final String email;
  final String initial;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: Theme.of(context).textTheme.titleLarge),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: isCupertino
                ? CupertinoButton(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onLogout,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.square_arrow_left,
                            color: Color(0xFFBA1A1A), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Cerrar sesión',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: const Color(0xFFBA1A1A)),
                        ),
                      ],
                    ),
                  )
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFDAD6),
                      foregroundColor: const Color(0xFFBA1A1A),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión'),
                  ),
          ),
        ],
      ),
    );
  }
}
