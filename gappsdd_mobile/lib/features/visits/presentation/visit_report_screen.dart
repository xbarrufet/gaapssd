import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/domain/auth_state.dart';
import '../../chat/domain/chat_models.dart';
import '../../chat/presentation/chat_with_request_modes_screen.dart';
import '../domain/client_visits_data.dart';

class VisitReportScreen extends ConsumerWidget {
  const VisitReportScreen({
    super.key,
    required this.visit,
  });

  final VisitSummary visit;

  bool _isCupertino(BuildContext context) => Theme.of(context).platform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCupertino = _isCupertino(context);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<VisitReport>(
          future: ref.read(visitsRepositoryProvider).loadVisitReport(visit.id),
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
                    'No s\'ha pogut carregar el detall de la visita.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            final report = snapshot.data!;
            final isVerified = report.status == VisitVerificationStatus.verified;

            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceLow,
                            ),
                            icon: Icon(
                              isCupertino ? CupertinoIcons.back : Icons.arrow_back_rounded,
                            ),
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Visit Report',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: _ReportHero(report: report),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _VerificationBadge(isVerified: isVerified, isCupertino: isCupertino),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _LogisticsCard(report: report, isCupertino: isCupertino),
                    ),
                  ),
                  if (report.publicComment.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _CommentsCard(comment: report.publicComment),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Text(
                        'Visual Documentation',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final photo = report.photos[index];
                          return _PhotoTile(photo: photo, featured: photo.featured);
                        },
                        childCount: report.photos.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 150,
                      ),
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

class _ReportHero extends StatelessWidget {
  const _ReportHero({required this.report});

  final VisitReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF88AD74), Color(0xFF5E7E4B), AppColors.primary],
              ),
            ),
            child: Image.network(
              report.headerImageUrl,
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
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.locationContext.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.locationName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.isVerified, required this.isCupertino});

  final bool isVerified;
  final bool isCupertino;

  @override
  Widget build(BuildContext context) {
    final icon = isVerified
        ? (isCupertino ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle)
        : (isCupertino ? CupertinoIcons.info_circle : Icons.info_outline_rounded);
    final label = isVerified ? 'VERIFIED VISIT' : 'MANUAL ENTRY';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Telemetric Security',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogisticsCard extends ConsumerWidget {
  const _LogisticsCard({required this.report, required this.isCupertino});

  final VisitReport report;
  final bool isCupertino;

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final chatRepository = ref.read(chatRepositoryProvider);
    final auth = ref.read(authProvider);
    final userId = auth?.userId ?? 'client-001';

    try {
      final conversations = await chatRepository.loadConversations(
        userId: userId,
        limit: 20,
      );
      final matchingConversation = conversations.where((conversation) {
        return conversation.otherUserId == 'gardener-001';
      });
      final conversationId = matchingConversation.isNotEmpty
          ? matchingConversation.first.conversationId
          : 'conv-${report.visitId}';

      if (!context.mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatWithRequestModesScreen(
            repository: chatRepository,
            conversationId: conversationId,
            currentUserId: userId,
            currentUserRole: MessageRole.client,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DataBlock(label: 'Visit Date', value: report.visitDate),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DataBlock(label: 'Duration', value: report.duration, alignEnd: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DataBlock(label: 'Entry Time', value: report.entryTime),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DataBlock(label: 'Exit Time', value: report.exitTime, alignEnd: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
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
                  report.gardenerAvatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    isCupertino ? CupertinoIcons.person_fill : Icons.person_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.gardenerName, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(report.gardenerRole, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                icon: Icon(isCupertino ? CupertinoIcons.phone_fill : Icons.call_rounded),
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _openChat(context, ref),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                icon: Icon(
                  isCupertino ? CupertinoIcons.chat_bubble_2_fill : Icons.chat_bubble_outline,
                ),
                color: AppColors.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataBlock extends StatelessWidget {
  const _DataBlock({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        ),
      ],
    );
  }
}

class _CommentsCard extends StatelessWidget {
  const _CommentsCard({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comments', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.featured});

  final VisitPhoto photo;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8EB07A), Color(0xFF4F6E3D)],
              ),
            ),
            child: Image.network(
              photo.imageUrl,
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
                  Colors.black.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.38),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                photo.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                    ),
              ),
            ),
          ),
          if (featured)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'MAIN',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontSize: 9,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}