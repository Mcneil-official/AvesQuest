import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bird_provider.dart';
import '../providers/quest_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/discovery_progress_ring.dart';
import '../widgets/game_background.dart';
import '../widgets/journey_stats_strip.dart';
import '../widgets/route_transitions.dart';
import '../widgets/recent_discovery_card.dart';
import '../widgets/streak_tracker.dart';

import 'bird_detail_screen.dart';

/// The journal home/dashboard screen — the "FOUND 142 OUT OF 500" view
/// with a discovery progress ring up top, a "Recent Discoveries" feed of
/// the latest catches, and a journey stats strip at the bottom.
///
/// Distinct from the Journal *Collection* grid screen: this is the
/// landing/overview tab, while the grid screen is the full browsable
/// AvesQuest. Both live under the "Journal" bottom-nav tab in the
/// reference designs, with this dashboard as the default view.
class JournalHomeScreen extends StatefulWidget {
  const JournalHomeScreen({super.key});

  /// Total species the game currently defines as catchable — drives the
  /// "OUT OF 500" denominator. Phase 1 doesn't have a master species
  /// list yet, so this is a placeholder constant until that exists.
  static const int totalCatchableSpecies = 500;

  @override
  State<JournalHomeScreen> createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends State<JournalHomeScreen> {
  final GlobalKey _recentSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Defer to after first frame so `context.read` is safe to call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BirdProvider>().loadBirds();
      context.read<QuestProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;

    return Consumer2<BirdProvider, QuestProvider>(
      builder: (context, birdProvider, questProvider, _) {
        final birds = birdProvider.birds;
        final found = birds.length;
        final level = questProvider.currentLevel;
        final xp = questProvider.xpInCurrentLevel;
        final xpTotal = questProvider.xpForLevel(level + 1) - questProvider.xpForLevel(level);

        // Most recent catches first — `birds` already comes back sorted
        // by caughtAt DESC from BirdProvider.loadBirds().
        final recent = birds.take(2).toList();

        // Distinct habitats stood in for "Regions" — a real region/area
        // system isn't part of Phase 1's scope (no GPS), so this counts
        // distinct non-empty habitat strings already on identified birds.
        final habitatsExplored = birds
            .map((b) => b.habitat)
            .where((h) => h.isNotEmpty)
            .toSet()
            .length;
        final distinctSpecies = birds
            .map((b) => b.species)
            .where((s) => s.isNotEmpty)
            .toSet()
            .length;

        if (birdProvider.isLoading && birds.isEmpty) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: GameBackground(
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: birdProvider.loadBirds,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.marginMobile,
                        AppSpacing.md,
                        AppSpacing.marginMobile,
                        AppSpacing.lg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _HomeIdentityCard(
                            level: level,
                            xp: xp,
                            xpTotal: xpTotal,
                            birdsCount: found,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _HomeQuestCard(
                            found: found,
                            isNarrow: isNarrow,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          StreakTracker(birds: birds),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Recent Discoveries',
                            style: AppTypography.headlineLgMobile().copyWith(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            key: _recentSectionKey,
                            child: recent.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.card,
                                      ),
                                      border: Border.all(
                                        color: AppColors.secondaryContainer,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.travel_explore,
                                          size: 32,
                                          color: AppColors.outline,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          'No catches yet — head outside and spot your first bird!',
                                          textAlign: TextAlign.center,
                                          style: AppTypography.bodyMd(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (final item in recent) ...[
                                        RecentDiscoveryCard(
                                          bird: item,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              ScaleFadeRoute(
                                                builder: (_) =>
                                                    BirdDetailScreen(
                                                      bird: item,
                                                      cardIndex:
                                                          birds.indexOf(item) +
                                                          1,
                                                      totalCount: found,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          JourneyStatsStrip(
                            habitatsExplored: habitatsExplored,
                            distinctSpecies: distinctSpecies,
                            totalCatches: found,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _BirderTier {
  rookie(1, 9, 'Birder Rookie', 'assets/pfp/rookie.png'),
  apprentice(10, 24, 'Birder Apprentice', 'assets/pfp/apprentice.png'),
  explorer(25, 44, 'Birder Explorer', 'assets/pfp/explorer.png'),
  tracker(45, 69, 'Birder Tracker', 'assets/pfp/tracker.png'),
  naturalist(70, 99, 'Birder Naturalist', 'assets/pfp/naturalist.png'),
  expert(100, 9999, 'Birder Expert', 'assets/pfp/expert.png');

  const _BirderTier(this.minLevel, this.maxLevel, this.title, this.assetPath);
  final int minLevel;
  final int maxLevel;
  final String title;
  final String assetPath;

  static _BirderTier fromLevel(int level) {
    return values.firstWhere(
      (t) => level >= t.minLevel && level <= t.maxLevel,
      orElse: () => _BirderTier.rookie,
    );
  }
}

Color _tierColor(_BirderTier tier) {
  return switch (tier) {
    _BirderTier.rookie => AppColors.rarityCommon,
    _BirderTier.apprentice => AppColors.rarityUncommon,
    _BirderTier.explorer => AppColors.rarityRare,
    _BirderTier.tracker => AppColors.rarityRare,
    _BirderTier.naturalist => AppColors.rarityLegendary,
    _BirderTier.expert => AppColors.sunnyYellow,
  };
}

class _HomeIdentityCard extends StatelessWidget {
  const _HomeIdentityCard({
    required this.level,
    required this.xp,
    required this.xpTotal,
    required this.birdsCount,
  });

  final int level;
  final int xp;
  final int xpTotal;
  final int birdsCount;

  _BirderTier get _tier => _BirderTier.fromLevel(level);

  @override
  Widget build(BuildContext context) {
    final xpPercent = xpTotal > 0 ? (xp / xpTotal).clamp(0.0, 1.0) : 1.0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6E9D0), Color(0xFFE8D4B0)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -4,
            left: -4,
            child: Icon(Icons.eco_rounded,
                size: 28,
                color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: Transform.flip(
              flipX: true,
              flipY: true,
              child: Icon(Icons.eco_rounded,
                  size: 28,
                  color: AppColors.primary.withValues(alpha: 0.08)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(_tier.assetPath, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _tier.title,
                                  style: AppTypography.titleMd().copyWith(fontSize: 22),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _tierColor(_tier).withValues(alpha: 0.2),
                                      _tierColor(_tier).withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded,
                                        size: 12, color: _tierColor(_tier)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Lv. $level',
                                      style: AppTypography.bodyMd(
                                              color: _tierColor(_tier))
                                          .copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _tierColor(_tier),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    return SizedBox(
                      height: 24,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            child: SizedBox(
                              height: 12,
                              child: Stack(
                                children: [
                                  Container(
                                    color: AppColors.surfaceContainerLowest,
                                  ),
                                  FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: xpPercent,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primaryContainer,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ...([0.25, 0.5, 0.75].map((pct) {
                            return Positioned(
                              left: barWidth * pct - 3,
                              top: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: barWidth * pct <= barWidth * xpPercent
                                      ? AppColors.primaryContainer
                                      : AppColors.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surfaceContainerLowest,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          })),
                          Positioned(
                            left: (barWidth * xpPercent - 8).clamp(0.0, barWidth - 16),
                            top: -2,
                            child: Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.sunnyYellow,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '$xp / $xpTotal XP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                            .copyWith(letterSpacing: 0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$birdsCount birds documented',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm(color: AppColors.primary)
                            .copyWith(letterSpacing: 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeQuestCard extends StatelessWidget {
  const _HomeQuestCard({
    required this.found,
    this.isNarrow = false,
  });

  final int found;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStacked = constraints.maxWidth < 320;
          return useStacked ? _buildStackedLayout() : _buildSideBySideLayout();
        },
      ),
    );
  }

  Widget _buildSideBySideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
                        DiscoveryProgressRing(found: found, total: JournalHomeScreen.totalCatchableSpecies, size: 180),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quest Progress',
                style: AppTypography.headlineLgMobile().copyWith(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keep exploring to grow your collection!',
                style: AppTypography.bodyLg(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              _QuestTip(
                icon: Icons.explore_rounded,
                text: 'Tap to start your next hunt.',
              ),
              const SizedBox(height: 8),
              _QuestTip(
                icon: Icons.park_rounded,
                text: 'New finds appear below.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStackedLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DiscoveryProgressRing(found: found, total: JournalHomeScreen.totalCatchableSpecies, size: 140),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Quest Progress',
          style: AppTypography.headlineLgMobile().copyWith(fontSize: 24),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Keep exploring to grow your collection!',
          style: AppTypography.bodyLg(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        _QuestTip(
          icon: Icons.explore_rounded,
          text: 'Tap to start your next hunt.',
        ),
        const SizedBox(height: 8),
        _QuestTip(
          icon: Icons.park_rounded,
          text: 'New finds appear below.',
        ),
      ],
    );
  }
}

class _QuestTip extends StatelessWidget {
  const _QuestTip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMd(
              color: AppColors.onSurfaceVariant,
            ).copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}


