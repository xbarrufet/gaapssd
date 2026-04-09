import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_models.dart';
import '../../chat/presentation/chat_with_request_modes_screen.dart';
import '../data/visits_repository.dart';
import '../domain/client_visits_data.dart';
import 'assigned_gardens_visit_status_screen.dart';
import 'gardener_visit_details_screen.dart';
import 'new_visit_screen.dart';

class GardenerVisitsListScreen extends StatefulWidget {
  const GardenerVisitsListScreen({
    super.key,
    required this.repository,
  });

  final VisitsRepository repository;

  @override
  State<GardenerVisitsListScreen> createState() => _GardenerVisitsListScreenState();
}

class _GardenerVisitsListScreenState extends State<GardenerVisitsListScreen> {
  String _searchQuery = '';

  Future<({List<VisitSummary> visits, Map<String, String> gardenNamesById})> _loadScreenData() async {
    final visitsFuture = widget.repository.loadCompletedVisits();
    final gardensFuture = widget.repository.loadAssignedGardensVisitStatus();

    final visits = await visitsFuture;
    final gardens = await gardensFuture;

    final map = <String, String>{for (final garden in gardens) garden.id: garden.gardenName};
    return (visits: visits, gardenNamesById: map);
  }

  DateTime? _parseVisitDate(VisitSummary visit) {
    final parts = visit.id.split('-');
    if (parts.length < 4) {
      return null;
    }

    final year = int.tryParse(parts[1]);
    final month = int.tryParse(parts[2]);
    final day = int.tryParse(parts[3]);

    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
  }

  String _formatHours(int minutes) {
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(1)}h';
  }

  String _formatVisitDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) {
      return '${mins}m';
    }
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _GardenerBottomNavBar(
        visitsActive: true,
        onVisitsTap: () {},
        onClientsTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => AssignedGardensVisitStatusScreen(repository: widget.repository),
            ),
          );
        },
        onNewVisitTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => NewVisitScreen(repository: widget.repository),
            ),
          );
        },
        onChatTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChatWithRequestModesScreen(
                repository: SqliteChatRepository(),
                conversationId: 'conv-default',
                currentUserId: 'gardener-001',
                currentUserRole: MessageRole.gardener,
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: FutureBuilder<({List<VisitSummary> visits, Map<String, String> gardenNamesById})>(
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
            final visits = data?.visits ?? const <VisitSummary>[];
            final gardenNamesById = data?.gardenNamesById ?? const <String, String>{};

            final weeklyVisits = visits.where((visit) {
              final date = _parseVisitDate(visit);
              return date != null && _isInCurrentWeek(date);
            }).toList();

            final totalWeeklyMinutes = weeklyVisits.fold<int>(
              0,
              (total, visit) => total + visit.durationMinutes,
            );

            final query = _searchQuery.trim().toLowerCase();
            final filteredVisits = query.isEmpty
                ? visits
                : visits.where((visit) {
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
                  weeklyHoursLabel: _formatHours(totalWeeklyMinutes),
                ),
                const SizedBox(height: 10),
                TextField(
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
                for (final visit in filteredVisits) ...[
                  _VisitSummaryCard(
                    visit: visit,
                    gardenName: gardenNamesById[visit.gardenId] ?? 'Jardin visitado',
                    durationLabel: _formatVisitDuration(visit.durationMinutes),
                    onTap: () async {
                      try {
                        final snapshot = await widget.repository.openCompletedVisitForEditing(
                          visitId: visit.id,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GardenerVisitDetailsScreen(
                              garden: snapshot.garden,
                              repository: widget.repository,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {});
                        }
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo abrir la visita: $e')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                if (filteredVisits.isEmpty)
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

class _VisitSummaryCard extends StatelessWidget {
  const _VisitSummaryCard({
    required this.visit,
    required this.gardenName,
    required this.durationLabel,
    required this.onTap,
  });

  final VisitSummary visit;
  final String gardenName;
  final String durationLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVerified = visit.status == VisitVerificationStatus.verified;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
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
                  Text(visit.dayLabel, style: Theme.of(context).textTheme.titleLarge),
                  Text(visit.monthLabel, style: Theme.of(context).textTheme.labelMedium),
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
                          gardenName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        durationLabel,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    visit.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isVerified ? 'Verificada' : 'Manual',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isVerified ? const Color(0xFF2E7D32) : const Color(0xFF8A5A00),
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

class _GardenerBottomNavBar extends StatelessWidget {
  const _GardenerBottomNavBar({
    required this.visitsActive,
    required this.onVisitsTap,
    required this.onClientsTap,
    required this.onNewVisitTap,
    required this.onChatTap,
  });

  final bool visitsActive;
  final VoidCallback onVisitsTap;
  final VoidCallback onClientsTap;
  final VoidCallback onNewVisitTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home_rounded,
            label: 'Visita',
            active: visitsActive,
            onTap: onVisitsTap,
          ),
          _BottomItem(
            icon: Icons.people_alt_outlined,
            label: 'Clientes',
            active: !visitsActive,
            onTap: onClientsTap,
          ),
          _BottomItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Nueva Visita',
            emphasize: true,
            onTap: onNewVisitTap,
          ),
          _BottomItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat',
            dot: true,
            onTap: onChatTap,
          ),
          const _BottomItem(icon: Icons.settings_outlined, label: 'Config'),
        ],
      ),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
