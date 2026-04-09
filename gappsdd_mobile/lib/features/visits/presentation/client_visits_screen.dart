import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/client_visits_data.dart';

class ClientVisitsScreen extends ConsumerWidget {
  const ClientVisitsScreen({super.key});

  bool _isCupertino(BuildContext context) => Theme.of(context).platform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCupertino = _isCupertino(context);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ClientVisitsData>(
          future: ref.read(visitsRepositoryProvider).loadClientVisitsData(),
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
                    'No s\'han pogut carregar les visites.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _TopBar(profile: data.profile),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                      child: _HeroCard(profile: data.profile),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverList.separated(
                      itemCount: data.visits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _VisitCard(
                          index: index,
                          isCupertino: isCupertino,
                          visit: data.visits[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.profile});

  final ClientProfile profile;

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: AppColors.surfaceHigh,
            shape: BoxShape.circle,
          ),
          child: Image.network(
            profile.gardenerAvatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(
              isCupertino ? CupertinoIcons.person_fill : Icons.person_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            profile.appTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F120C),
                blurRadius: 18,
                spreadRadius: -6,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            onPressed: null,
            icon: Icon(
              isCupertino ? CupertinoIcons.bell : Icons.notifications_none_rounded,
            ),
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile});

  final ClientProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1C1C17),
            blurRadius: 28,
            spreadRadius: -10,
            offset: Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF92B47D),
                  Color(0xFF587946),
                  AppColors.primaryContainer,
                ],
              ),
            ),
            child: Image.network(
              profile.heroImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  profile.clientName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 14,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.index,
    required this.isCupertino,
    required this.visit,
  });

  final int index;
  final bool isCupertino;
  final VisitSummary visit;

  @override
  Widget build(BuildContext context) {
    final isVerified = visit.status == VisitVerificationStatus.verified;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 220 + (index * 45).clamp(0, 220)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 74,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        visit.dayLabel,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visit.monthLabel,
                        style: Theme.of(context).textTheme.labelMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _StatusBadge(isVerified: isVerified),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              visit.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          if (visit.photoCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCupertino ? CupertinoIcons.photo_fill_on_rectangle_fill : Icons.image_rounded,
                                color: AppColors.onPrimary,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _PrimaryActionChip(
                            isCupertino: isCupertino,
                            label: 'View Details',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push(AppRoutes.clientVisitReport, extra: visit);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final icon = isVerified ? Icons.check_circle : Icons.info_outline_rounded;
    final label = isVerified ? 'Verified Visit' : 'Manual Entry';
    final background = isVerified
      ? AppColors.primaryContainer.withValues(alpha: 0.10)
      : const Color(0xFFFFDAD6);
    final foreground = isVerified ? AppColors.primary : const Color(0xFFBA1A1A);

    return Container(
      constraints: const BoxConstraints.tightFor(width: 74),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionChip extends StatelessWidget {
  const _PrimaryActionChip({
    required this.isCupertino,
    required this.label,
    required this.onTap,
  });

  final bool isCupertino;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(
        onPressed: onTap,
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onPrimary,
              ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onPrimary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

