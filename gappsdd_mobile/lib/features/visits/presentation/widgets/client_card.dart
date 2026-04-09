import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/client_visits_data.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.garden,
    required this.onMessageTap,
  });

  final AssignedGardenVisitStatus garden;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JARDIN ACTUAL',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      garden.gardenName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(garden.address, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                ),
                icon: Icon(isCupertino ? CupertinoIcons.phone_fill : Icons.call_rounded),
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onMessageTap,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                icon: Icon(
                  isCupertino ? CupertinoIcons.chat_bubble_2_fill : Icons.chat_bubble_outline_rounded,
                ),
                color: AppColors.onPrimary,
              ),
            ],
          ),
          Positioned(
            right: -14,
            bottom: -22,
            child: IgnorePointer(
              child: Icon(
                Icons.park_rounded,
                size: 84,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
