import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/client_visits_data.dart';

class TimerControlsCard extends StatelessWidget {
  const TimerControlsCard({
    super.key,
    required this.visit,
    this.onEditTimestamps,
    this.onQrExit,
    this.onManualExit,
  });

  final ActiveVisitSnapshot visit;
  final VoidCallback? onEditTimestamps;
  final VoidCallback? onQrExit;
  final VoidCallback? onManualExit;

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildEditableTimeBox({
    required BuildContext context,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.primaryContainer.withValues(alpha: 0.25)
                : AppColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEnabled
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.outline.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;
    final durationStr = visit.duration != null ? _formatDuration(visit.duration!) : '00:00:00';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ENTRADA', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    _buildEditableTimeBox(
                      context: context,
                      value: _formatTime(visit.startedAt),
                      icon: isCupertino ? CupertinoIcons.arrow_right_circle_fill : Icons.login_rounded,
                      onTap: onEditTimestamps,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      visit.isActive ? 'DURACION EN VIVO' : 'DURACION TOTAL',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationStr,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (visit.endedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SALIDA', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        _buildEditableTimeBox(
                          context: context,
                          value: _formatTime(visit.endedAt!),
                          icon: isCupertino ? CupertinoIcons.arrow_left_circle_fill : Icons.logout_rounded,
                          onTap: onEditTimestamps,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ESTADO', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: visit.isVerified ? const Color(0xFF4CAF50).withValues(alpha: 0.2) : const Color(0xFFF44336).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            visit.isVerified ? 'Verificada' : 'No Verificada',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: visit.isVerified ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (visit.isActive && onManualExit != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: isCupertino
                      ? CupertinoButton(
                          onPressed: onQrExit != null ? () { HapticFeedback.mediumImpact(); onQrExit!(); } : null,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.qrcode_viewfinder, color: AppColors.onPrimary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'ESCANEAR QR SALIDA',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: AppColors.onPrimary,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: onQrExit != null ? () { HapticFeedback.mediumImpact(); onQrExit!(); } : null,
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: Text(
                            'ESCANEAR QR SALIDA',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 10,
                                ),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: isCupertino
                      ? CupertinoButton(
                          onPressed: onManualExit != null ? () { HapticFeedback.mediumImpact(); onManualExit!(); } : null,
                          color: AppColors.surfaceHighest,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.pencil, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'SALIDA MANUAL',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: onManualExit != null ? () { HapticFeedback.mediumImpact(); onManualExit!(); } : null,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(
                            'SALIDA MANUAL',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 10),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.outline.withValues(alpha: 0.35)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
