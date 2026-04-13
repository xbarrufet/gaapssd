import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/adaptive_tappable.dart';
import '../../../core/utils/format_utils.dart' as fmt;
import '../domain/client_visits_data.dart';

class AssignedGardensVisitStatusScreen extends ConsumerStatefulWidget {
  const AssignedGardensVisitStatusScreen({
    super.key,
  });

  @override
  ConsumerState<AssignedGardensVisitStatusScreen> createState() =>
      _AssignedGardensVisitStatusScreenState();
}

class _AssignedGardensVisitStatusScreenState extends ConsumerState<AssignedGardensVisitStatusScreen> {
  late Future<List<AssignedGardenVisitStatus>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(visitsRepositoryProvider).loadAssignedGardensVisitStatus();
  }

  void _refreshAfterDetail() {
    if (!mounted) return;
    setState(() {
      _future = ref.read(visitsRepositoryProvider).loadAssignedGardensVisitStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<AssignedGardenVisitStatus>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No s\'han pogut carregar els jardins assignats.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            final gardens = snapshot.data!;

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned Gardens',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${gardens.length} Sites Total',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                  sliver: SliverList.separated(
                    itemCount: gardens.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final garden = gardens[index];
                      return _GardenStatusCard(
                        garden: garden,
                        onOpenDetails: () async {
                          try {
                            final repo = ref.read(visitsRepositoryProvider);
                            // Load latest completed visit for this garden
                            final completedVisits = await repo.loadCompletedVisits();
                            final gardenVisit = completedVisits
                                .where((v) => v.gardenId == garden.id)
                                .toList();

                            if (!context.mounted) {
                              return;
                            }

                            if (gardenVisit.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No hay visitas para este jardín')),
                              );
                              return;
                            }

                            await context.push(
                              AppRoutes.gardenerVisitDetail,
                              extra: {
                                'garden': garden,
                                'selectedVisitId': gardenVisit.first.id,
                              },
                            );
                            _refreshAfterDetail();
                          } catch (e) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No se pudo abrir la ultima visita: $e')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}




class _GardenStatusCard extends StatefulWidget {
  const _GardenStatusCard({required this.garden, required this.onOpenDetails});

  final AssignedGardenVisitStatus garden;
  final Future<void> Function() onOpenDetails;

  @override
  State<_GardenStatusCard> createState() => _GardenStatusCardState();
}

class _GardenStatusCardState extends State<_GardenStatusCard> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onOpenDetails();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.garden.evidence == VisitEvidence.verified;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.garden.gardenName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  widget.garden.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AdaptiveTappable(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(10),
            haptic: HapticStyle.light,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'ÚLTIMA VISITA',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 9),
                  ),
                  const SizedBox(width: 10),
                  if (widget.garden.lastVisitDate != null) ...[
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.garden.lastVisitDate!.day.toString().padLeft(2, '0'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                          ),
                          Text(
                            fmt.monthLabel(widget.garden.lastVisitDate!.month),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? const Color(0xFFD6EAB6)
                          : const Color(0xFFFFF0CC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVerified ? Icons.check_circle : Icons.info,
                          size: 12,
                          color: isVerified
                              ? const Color(0xFF3C4C26)
                              : const Color(0xFF8A5A00),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVerified ? 'Verificada' : 'No verificada',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: isVerified
                                    ? const Color(0xFF3C4C26)
                                    : const Color(0xFF8A5A00),
                                fontSize: 9,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isLoading)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
