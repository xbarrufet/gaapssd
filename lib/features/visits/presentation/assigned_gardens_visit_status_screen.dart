import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_models.dart';
import '../../chat/presentation/chat_with_request_modes_screen.dart';
import '../data/visits_repository.dart';
import '../domain/client_visits_data.dart';
import 'gardener_visit_details_screen.dart';
import 'gardener_visits_list_screen.dart';
import 'new_visit_screen.dart';

class AssignedGardensVisitStatusScreen extends StatefulWidget {
  const AssignedGardensVisitStatusScreen({
    super.key,
    required this.repository,
  });

  final VisitsRepository repository;

  @override
  State<AssignedGardensVisitStatusScreen> createState() =>
      _AssignedGardensVisitStatusScreenState();
}

class _AssignedGardensVisitStatusScreenState extends State<AssignedGardensVisitStatusScreen> {
  int _refreshSeed = 0;

  void _refreshAfterDetail() {
    if (!mounted) {
      return;
    }
    setState(() {
      _refreshSeed++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _GardenerBottomNavBar(
        onVisitsTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => GardenerVisitsListScreen(repository: widget.repository),
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
        child: FutureBuilder<List<AssignedGardenVisitStatus>>(
          key: ValueKey(_refreshSeed),
          future: widget.repository.loadAssignedGardensVisitStatus(),
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
                const SliverToBoxAdapter(child: _GardenerTopBar()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: const _SearchAndActions(),
                ),
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
                        _SquareIcon(icon: Icons.filter_list_rounded, onTap: () {}),
                        const SizedBox(width: 6),
                        _SquareIcon(icon: Icons.sort_rounded, onTap: () {}),
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
                            final snapshot = await widget.repository.openLatestVisitForGarden(
                              gardenId: garden.id,
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

class _GardenerTopBar extends StatelessWidget {
  const _GardenerTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCzzn80WJSziuMbQ5S8aenLYWGhWqltbfeTh0C1nhJZk7xn9fF3qjlkq27w2yOliBEEWG-HANur3yHlhoG-azp1gTUel7SWBtAMnZNvOy3rS6mToueQiEtQWUE_kJRWb4Aw4elpEdmKhuMnC6Iq6SLu1LCciKfx-MJvjGtvP-1N-O9gR9FH2H7bP4TAUWr7Cau0v75bZQ2kN7bFLQOrynYAblMvilxRN4r8tgodHm8GDhBT55ROgvNGHKtDWfpm3-Wjntm0MQNBEYHq',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Daily Harvest',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _SearchAndActions extends StatelessWidget {
  const _SearchAndActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search gardens or clients...',
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
        ],
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}

class _GardenStatusCard extends StatelessWidget {
  const _GardenStatusCard({required this.garden, required this.onOpenDetails});

  final AssignedGardenVisitStatus garden;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final urgencyStyle = _urgencyChip(garden.urgency);
    final evidenceStyle = _evidence(garden.evidence);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            garden.gardenName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 17,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: urgencyStyle.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            urgencyStyle.label,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: urgencyStyle.foreground,
                                  fontSize: 9,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            garden.address,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    garden.lastVisitLabel.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    garden.lastVisitAge,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 13,
                          color: garden.urgency == GardenVisitUrgency.urgent
                              ? const Color(0xFFBA1A1A)
                              : AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        evidenceStyle.icon,
                        size: 12,
                        color: evidenceStyle.foreground,
                      ),
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: evidenceStyle.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          evidenceStyle.label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: evidenceStyle.foreground,
                                fontSize: 8,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onOpenDetails,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  child: Text(
                    garden.primaryActionLabel.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 10,
                          color: AppColors.onPrimary,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, Color background, Color foreground}) _urgencyChip(
    GardenVisitUrgency urgency,
  ) {
    switch (urgency) {
      case GardenVisitUrgency.urgent:
        return (
          label: 'Urgent',
          background: const Color(0xFFFFDAD6),
          foreground: const Color(0xFFBA1A1A),
        );
      case GardenVisitUrgency.upcoming:
        return (
          label: 'Upcoming',
          background: const Color(0xFFFFF0CC),
          foreground: const Color(0xFF8A5A00),
        );
      case GardenVisitUrgency.maintained:
        return (
          label: 'Maintained',
          background: const Color(0xFFD6EAB6),
          foreground: const Color(0xFF3C4C26),
        );
    }
  }

  ({String label, Color background, Color foreground, IconData icon}) _evidence(
    VisitEvidence evidence,
  ) {
    switch (evidence) {
      case VisitEvidence.verified:
        return (
          label: 'Verified',
          background: const Color(0xFFD6EAB6),
          foreground: const Color(0xFF3C4C26),
          icon: Icons.check_circle,
        );
      case VisitEvidence.manual:
        return (
          label: 'Manual',
          background: const Color(0xFFFFF0CC),
          foreground: const Color(0xFF8A5A00),
          icon: Icons.info,
        );
    }
  }
}

class _GardenerBottomNavBar extends StatelessWidget {
  const _GardenerBottomNavBar({
    required this.onVisitsTap,
    required this.onNewVisitTap,
    required this.onChatTap,
  });

  final VoidCallback onVisitsTap;
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
          _BottomItem(icon: Icons.home_rounded, label: 'Visita', onTap: onVisitsTap),
          const _BottomItem(icon: Icons.people_alt_outlined, label: 'Clientes', active: true),
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