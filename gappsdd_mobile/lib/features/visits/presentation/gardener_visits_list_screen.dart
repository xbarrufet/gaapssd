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

class GardenerVisitsListScreen extends ConsumerStatefulWidget {
  const GardenerVisitsListScreen({
    super.key,
  });

  @override
  ConsumerState<GardenerVisitsListScreen> createState() => _GardenerVisitsListScreenState();
}

class _GardenerVisitsListScreenState extends ConsumerState<GardenerVisitsListScreen> {
  String _searchQuery = '';

  bool get _isCupertino => Theme.of(context).platform == TargetPlatform.iOS;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<({
    List<VisitSummary> visits,
    Map<String, String> gardenNamesById,
    ActiveVisitSnapshot? activeVisit,
  })> _loadScreenData() async {
    final repo = ref.read(visitsRepositoryProvider);
    final visitsFuture = repo.loadCompletedVisits();
    final gardensFuture = repo.loadAssignedGardensVisitStatus();
    final activeVisitFuture = repo.loadActiveVisit();

    final visits = await visitsFuture;
    final gardens = await gardensFuture;
    final activeVisit = await activeVisitFuture;

    final map = <String, String>{for (final garden in gardens) garden.id: garden.gardenName};
    return (visits: visits, gardenNamesById: map, activeVisit: activeVisit);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<({
          List<VisitSummary> visits,
          Map<String, String> gardenNamesById,
          ActiveVisitSnapshot? activeVisit,
        })>(
          future: _loadScreenData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No se han podido cargar las visitas.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            final data = snapshot.data;
            final completedVisits = data?.visits ?? const <VisitSummary>[];
            final gardenNamesById = data?.gardenNamesById ?? const <String, String>{};
            final activeVisit = data?.activeVisit;

            final cards = <({VisitSummary visit, bool isActive})>[];
            if (activeVisit != null) {
              final startedAt = activeVisit.startedAt;
              final elapsed = DateTime.now().difference(startedAt);
              cards.add((
                visit: VisitSummary(
                  id: 'active-${startedAt.millisecondsSinceEpoch}',
                  gardenId: activeVisit.garden.id,
                  durationMinutes: elapsed.inMinutes,
                  dayLabel: startedAt.day.toString().padLeft(2, '0'),
                  monthLabel: fmt.monthLabel(startedAt.month),
                  title: 'Visita en curso',
                  description: 'Visita abierta actualmente',
                  status: activeVisit.isVerified
                      ? VisitVerificationStatus.verified
                      : VisitVerificationStatus.manualEntry,
                  photoCount: activeVisit.photos.length,
                ),
                isActive: true,
              ));
            }

            cards.addAll(completedVisits.map((visit) => (visit: visit, isActive: false)));
            final visits = cards.map((c) => c.visit).toList();

            final weeklyVisits = visits.where((visit) {
              final date = fmt.parseVisitDate(visit.id);
              return date != null && fmt.isInCurrentWeek(date);
            }).toList();

            final totalWeeklyMinutes = weeklyVisits.fold<int>(
              0,
              (total, visit) => total + visit.durationMinutes,
            );

            final query = _searchQuery.trim().toLowerCase();
            final filteredCards = query.isEmpty
              ? cards
              : cards.where((card) {
                final visit = card.visit;
                final gardenName = gardenNamesById[visit.gardenId] ?? 'Jardin';
                return gardenName.toLowerCase().contains(query) ||
                        visit.description.toLowerCase().contains(query) ||
                        visit.monthLabel.toLowerCase().contains(query) ||
                        visit.dayLabel.toLowerCase().contains(query);
                  }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
              children: [
                Text('Visits', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('${visits.length} visitas', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 12),
                _WeeklyMetricsCard(
                  weeklyVisitsCount: weeklyVisits.length,
                  weeklyHoursLabel: fmt.formatHours(totalWeeklyMinutes),
                ),
                const SizedBox(height: 10),
                _isCupertino
                    ? CupertinoSearchTextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        placeholder: 'Buscar visitas...',
                        backgroundColor: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    : TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar visitas...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: AppColors.surfaceLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.22)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.22)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                const SizedBox(height: 14),
                for (final card in filteredCards) ...[
                  _VisitSummaryCard(
                    visit: card.visit,
                    isActive: card.isActive,
                    gardenName: gardenNamesById[card.visit.gardenId] ?? 'Jardin visitado',
                    durationLabel: fmt.formatVisitDuration(card.visit.durationMinutes),
                    onTap: () async {
                      if (card.isActive && activeVisit != null) {
                        await context.push(AppRoutes.gardenerVisitDetail, extra: {'garden': activeVisit.garden});
                        if (mounted) {
                          setState(() {});
                        }
                        return;
                      }

                      try {
                        final snapshot = await ref.read(visitsRepositoryProvider).openCompletedVisitForEditing(
                          visitId: card.visit.id,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        await context.push(AppRoutes.gardenerVisitDetail, extra: {'garden': snapshot.garden, 'selectedVisitId': card.visit.id});
                        if (mounted) {
                          setState(() {});
                        }
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }
                        _showMessage('No se pudo abrir la visita: $e');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                if (filteredCards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text(
                        'No hay visitas que coincidan con la busqueda',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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

class _WeeklyMetricsCard extends StatelessWidget {
  const _WeeklyMetricsCard({
    required this.weeklyVisitsCount,
    required this.weeklyHoursLabel,
  });

  final int weeklyVisitsCount;
  final String weeklyHoursLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2F5D41),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF244733)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(
              title: 'Visitas esta semana',
              value: '$weeklyVisitsCount',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Expanded(
            child: _MetricItem(
              title: 'Horas invertidas',
              value: weeklyHoursLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

class _VisitSummaryCard extends StatefulWidget {
  const _VisitSummaryCard({
    required this.visit,
    required this.isActive,
    required this.gardenName,
    required this.durationLabel,
    required this.onTap,
  });

  final VisitSummary visit;
  final bool isActive;
  final String gardenName;
  final String durationLabel;
  final Future<void> Function() onTap;

  @override
  State<_VisitSummaryCard> createState() => _VisitSummaryCardState();
}

class _VisitSummaryCardState extends State<_VisitSummaryCard> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.visit.status == VisitVerificationStatus.verified;
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    return AdaptiveTappable(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(12),
      haptic: HapticStyle.light,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isActive ? const Color(0xFFE8F3E6) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isActive
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(widget.visit.dayLabel, style: Theme.of(context).textTheme.titleLarge),
                  Text(widget.visit.monthLabel, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.gardenName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.durationLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: widget.isActive ? AppColors.primaryContainer : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 4),
                      if (_isLoading)
                        const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      else
                        Icon(
                          isCupertino ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.visit.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : isVerified
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.isActive ? 'Abierta' : (isVerified ? 'Verificada' : 'Manual'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: widget.isActive
                            ? AppColors.primary
                            : isVerified
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF8A5A00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
