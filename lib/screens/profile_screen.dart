import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../models/bird.dart';
import '../models/quest.dart';
import '../providers/bird_provider.dart';
import '../providers/quest_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/game_background.dart';

/// Birder tier progression — each tier spans a level range and has an associated badge image.
enum BirderTier {
  rookie(1, 9, 'Birder Rookie', 'assets/pfp/rookie.png'),
  apprentice(10, 24, 'Birder Apprentice', 'assets/pfp/apprentice.png'),
  explorer(25, 44, 'Birder Explorer', 'assets/pfp/explorer.png'),
  tracker(45, 69, 'Birder Tracker', 'assets/pfp/tracker.png'),
  naturalist(70, 99, 'Birder Naturalist', 'assets/pfp/naturalist.png'),
  expert(100, 9999, 'Birder Expert', 'assets/pfp/expert.png');

  const BirderTier(this.minLevel, this.maxLevel, this.title, this.assetPath);

  final int minLevel;
  final int maxLevel;
  final String title;
  final String assetPath;

  static BirderTier fromLevel(int level) {
    return values.firstWhere(
      (t) => level >= t.minLevel && level <= t.maxLevel,
      orElse: () => BirderTier.rookie,
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _ProfileTab(
      icon: Icons.dashboard_rounded,
      label: 'Overview',
    ),
    _ProfileTab(
      icon: Icons.emoji_events_rounded,
      label: 'Achievements',
    ),
    _ProfileTab(
      icon: Icons.assignment_rounded,
      label: 'Quests',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GameBackground(
        child: SafeArea(
        bottom: false,
        child: Consumer2<BirdProvider, QuestProvider>(
          builder: (context, birdProvider, questProvider, _) {
            if (birdProvider.isLoading && birdProvider.birds.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }
            final birds = birdProvider.birds;
            final level = questProvider.currentLevel;
            final xp = questProvider.xpInCurrentLevel;
            final xpTotal = questProvider.xpForLevel(level + 1) - questProvider.xpForLevel(level);

            return Column(
              children: [
                _ProfileTabBar(controller: _tabController),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OverviewTab(
                        birds: birds,
                        level: level,
                        xp: xp,
                        xpTotal: xpTotal,
                      ),
                      _AchievementsTab(birds: birds),
                      _QuestsTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

class _ProfileTab {
  const _ProfileTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: List.generate(_ProfileScreenState._tabs.length, (index) {
              final tab = _ProfileScreenState._tabs[index];
              return _ProfileTabSegment(
                icon: tab.icon,
                label: tab.label,
                isSelected: controller.index == index,
                onTap: () => controller.animateTo(index),
              );
            }),
          ),
        );
      },
    );
  }
}

class _ProfileTabSegment extends StatelessWidget {
  const _ProfileTabSegment({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.surface
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm(
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.birds,
    required this.level,
    required this.xp,
    required this.xpTotal,
  });

  final List<Bird> birds;
  final int level;
  final int xp;
  final int xpTotal;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
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
              _ProfileIdentityCard(
                level: level,
                xp: xp,
                xpTotal: xpTotal,
                birdsCount: birds.length,
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileStatsBlock(birds: birds),
              const SizedBox(height: AppSpacing.lg),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Achievements Tab ──────────────────────────────────────────────────────────

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({required this.birds});

  final List<Bird> birds;

  @override
  Widget build(BuildContext context) {
    final unlocked = Achievement.all.where((a) => a.isUnlocked(birds)).toList();
    final locked = Achievement.all.where((a) => !a.isUnlocked(birds)).toList();

    return CustomScrollView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text('Achievements',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd()),
                  ),
                  const SizedBox(width: 4),
                  Text('${unlocked.length}/${Achievement.all.length}',
                      style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...unlocked.map((a) => _AchievementCard(achievement: a, unlocked: true)),
              ...locked.map((a) => _AchievementCard(achievement: a, unlocked: false)),
              const SizedBox(height: AppSpacing.lg),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Identity Block ──────────────────────────────────────────────────────────

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.level,
    required this.xp,
    required this.xpTotal,
    required this.birdsCount,
  });

  final int level;
  final int xp;
  final int xpTotal;
  final int birdsCount;

  BirderTier get _tier => BirderTier.fromLevel(level);

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
          // Corner ornament: top-left
          Positioned(
            top: -4,
            left: -4,
            child: Icon(Icons.eco_rounded,
                size: 28,
                color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          // Corner ornament: bottom-right
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
                    // Milestone dots
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
                    // Star at current progress
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

  Color _tierColor(BirderTier tier) {
    return switch (tier) {
      BirderTier.rookie => AppColors.rarityCommon,
      BirderTier.apprentice => AppColors.rarityUncommon,
      BirderTier.explorer => AppColors.rarityRare,
      BirderTier.tracker => AppColors.rarityRare,
      BirderTier.naturalist => AppColors.rarityLegendary,
      BirderTier.expert => AppColors.sunnyYellow,
    };
  }
}

// ── Quests Tab ────────────────────────────────────────────────────────────────

class _QuestsTab extends StatelessWidget {
  const _QuestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<QuestProvider>(
      builder: (context, questProvider, _) {
        return _ProfileQuestsBlock(questProvider: questProvider);
      },
    );
  }
}

// ── Quests Block ────────────────────────────────────────────────────────────

class _ProfileQuestsBlock extends StatefulWidget {
  const _ProfileQuestsBlock({required this.questProvider});

  final QuestProvider questProvider;

  @override
  State<_ProfileQuestsBlock> createState() => _ProfileQuestsBlockState();
}

class _ProfileQuestsBlockState extends State<_ProfileQuestsBlock> {
  _QuestTab _activeTab = _QuestTab.daily;

  QuestPeriod get _period => switch (_activeTab) {
        _QuestTab.daily => QuestPeriod.daily,
        _QuestTab.weekly => QuestPeriod.weekly,
        _QuestTab.season => QuestPeriod.seasonal,
      };

  @override
  Widget build(BuildContext context) {
    final quests = widget.questProvider.questsFor(_period);
    final claimable = quests.where((q) => widget.questProvider.canClaim(q)).toList();

    return CustomScrollView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quests', style: AppTypography.titleMd()),
                  Text(
                    '${widget.questProvider.completedCount(_period)}/${widget.questProvider.totalCount(_period)}',
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuestTabToggle(
                activeTab: _activeTab,
                onChanged: (tab) => setState(() => _activeTab = tab),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (claimable.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _claimAll(context, claimable),
                      icon: const Icon(Icons.download_done_rounded, size: 18),
                      label: Text('Claim All (${claimable.length})'),
                    ),
                  ),
                ),
              ...quests.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _QuestRow(
                    definition: q,
                    progress: widget.questProvider.progressFor(q),
                    isClaimed: widget.questProvider.isClaimed(q),
                    canClaim: widget.questProvider.canClaim(q),
                    onClaim: () => _claimOne(context, q),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _claimAll(BuildContext context, List<QuestDefinition> quests) async {
    final xpBefore = widget.questProvider.totalXp;
    await widget.questProvider.claimAll(_period);
    final xpGained = widget.questProvider.totalXp - xpBefore;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Claimed ${quests.length} quests! +$xpGained XP'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _claimOne(BuildContext context, QuestDefinition quest) async {
    await widget.questProvider.claimQuest(quest.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+${quest.xpReward} XP for ${quest.title}!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Stats Block ─────────────────────────────────────────────────────────────

class _ProfileStatsBlock extends StatelessWidget {
  const _ProfileStatsBlock({required this.birds});

  final List<Bird> birds;

  @override
  Widget build(BuildContext context) {
    final total = birds.length;
    final streak = _computeStreak(birds);
    final habitats =
        birds.map((b) => b.habitat).where((h) => h.isNotEmpty).toSet().length;

    final rarityCounts = {
      Rarity.common:
          birds.where((b) => b.rarity == Rarity.common).length,
      Rarity.uncommon:
          birds.where((b) => b.rarity == Rarity.uncommon).length,
      Rarity.rare:
          birds.where((b) => b.rarity == Rarity.rare).length,
      Rarity.legendary:
          birds.where((b) => b.rarity == Rarity.legendary).length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stats', style: AppTypography.titleMd()),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Collected',
                value: '$total',
                icon: Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: 'Habitats',
                value: '$habitats',
                icon: Icons.explore_rounded,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: 'Streak',
                value: '$streak',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.rarityRare,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Rarity Breakdown', style: AppTypography.titleMd()),
        const SizedBox(height: AppSpacing.sm),
        ...rarityCounts.entries.map((entry) => _RarityBar(
              rarity: entry.key,
              count: entry.value,
              total: total,
            )),
      ],
    );
  }

  int _computeStreak(List<Bird> birds) {
    if (birds.isEmpty) return 0;
    final dates = birds
        .map((b) => DateTime(b.caughtAt.year, b.caughtAt.month, b.caughtAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    if (dates.first != todayDate && dates.first != yesterday) return 0;
    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      if (dates[i].difference(dates[i + 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: AppTypography.headlineLgMobile()
                  .copyWith(fontSize: 22, color: color)),
          Text(label,
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RarityBar extends StatelessWidget {
  const _RarityBar(
      {required this.rarity, required this.count, required this.total});

  final Rarity rarity;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    final color = switch (rarity) {
      Rarity.common => AppColors.rarityCommon,
      Rarity.uncommon => AppColors.rarityUncommon,
      Rarity.rare => AppColors.rarityRare,
      Rarity.legendary => AppColors.rarityLegendary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child:
                Text(rarity.label, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.surfaceContainerHighest,
                color: color,
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 36,
            child: Text('$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd(color: AppColors.onSurface)),
          ),
        ],
      ),
    );
  }
}

// ── Achievements Card (full-width style) ──────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.surfaceContainerLow : AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: unlocked ? achievement.color.withValues(alpha: 0.3) : AppColors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (unlocked)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      achievement.color,
                      achievement.color.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.sm),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 14, color: AppColors.surface),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Icon(
                    achievement.icon,
                    color: unlocked ? achievement.color : AppColors.outline,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: AppTypography.titleMd(
                            color: unlocked ? AppColors.onSurface : AppColors.outline,
                          ).copyWith(fontSize: 16),
                        ),
                        Text(
                          achievement.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMd(
                            color: unlocked ? AppColors.onSurfaceVariant : AppColors.outline.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                    color: unlocked ? achievement.color : AppColors.outline,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

// ── Medallion Badge (horizontal style - kept for reference) ──────────────────

// OLD: _ProfileAchievementsBlock and _MedallionBadge removed - using full-width _AchievementCard in AchievementsTab

enum _QuestTab { daily, weekly, season }

class _QuestTabToggle extends StatelessWidget {
  const _QuestTabToggle({
    required this.activeTab,
    required this.onChanged,
  });

  final _QuestTab activeTab;
  final ValueChanged<_QuestTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          _QuestTabSegment(
            label: 'Daily',
            isSelected: activeTab == _QuestTab.daily,
            onTap: () => onChanged(_QuestTab.daily),
          ),
          const SizedBox(width: 4),
          _QuestTabSegment(
            label: 'Weekly',
            isSelected: activeTab == _QuestTab.weekly,
            onTap: () => onChanged(_QuestTab.weekly),
          ),
          const SizedBox(width: 4),
          _QuestTabSegment(
            label: 'Season',
            isSelected: activeTab == _QuestTab.season,
            onTap: () => onChanged(_QuestTab.season),
          ),
        ],
      ),
    );
  }
}

class _QuestTabSegment extends StatelessWidget {
  const _QuestTabSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.labelSm(
                  color: isSelected
                      ? AppColors.surface
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.definition,
    required this.progress,
    required this.isClaimed,
    required this.canClaim,
    required this.onClaim,
  });

  final QuestDefinition definition;
  final int progress;
  final bool isClaimed;
  final bool canClaim;
  final VoidCallback onClaim;

  bool get _isComplete => progress >= definition.target;
  double get _fraction =>
      definition.target > 0 ? (progress / definition.target).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _isComplete
            ? AppColors.surfaceContainerLow
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: _isComplete
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isComplete
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              definition.icon,
              size: 20,
              color: _isComplete ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        definition.title,
                        style: AppTypography.titleMd().copyWith(
                          fontSize: 15,
                          color: _isComplete
                              ? AppColors.onSurface
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                    if (isClaimed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Claimed',
                          style: AppTypography.labelSm(
                            color: AppColors.primary,
                          ).copyWith(fontSize: 10),
                        ),
                      )
                    else if (canClaim)
                      GestureDetector(
                        onTap: onClaim,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            'Claim +${definition.xpReward}',
                            style: AppTypography.labelSm(
                              color: AppColors.surface,
                            ).copyWith(fontSize: 10),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sunnyYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '+${definition.xpReward} XP',
                          style: AppTypography.labelSm(
                            color: AppColors.tertiaryContainer,
                          ).copyWith(fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  definition.description,
                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: LinearProgressIndicator(
                          value: _fraction,
                          backgroundColor: AppColors.surfaceContainerHighest,
                          color: _isComplete
                              ? AppColors.primary
                              : AppColors.secondary,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$progress/${definition.target}',
                      style: AppTypography.labelSm(
                              color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 11),
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


