import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bird.dart';
import '../models/pending_queue_item.dart';
import '../providers/bird_provider.dart';
import '../providers/identification_provider.dart';
import '../providers/pending_queue_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/bird_grid_card.dart';
import '../widgets/game_background.dart';
import '../widgets/oriented_image.dart';
import '../widgets/route_transitions.dart';
import 'bird_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BirdProvider>().loadBirds();
      context.read<PendingQueueProvider>().loadQueue();
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
        child: Stack(
          children: [
            const Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              width: 20,
              child: _SpiralBinding(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                children: [
                  _JournalHeader(controller: _tabController),
                  Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const _CollectionTab(),
                      _PendingTab(onBirdIdentified: (bird) {
                        final birdProvider = context.read<BirdProvider>();
                        birdProvider.loadBirds();
                        birdProvider.highlightBird(bird.id!);
                        _tabController.animateTo(0);
                      }),
                    ],
                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Spiral notebook binding ──────────────────────────────────────

class _SpiralBinding extends StatelessWidget {
  const _SpiralBinding();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _SpiralPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _SpiralPainter extends CustomPainter {
  const _SpiralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const ringSpacing = 28.0;
    const startY = 100.0;
    const ringWidth = 14.0;
    const ringHeight = 8.0;

    final centerX = size.width / 2;

    for (double y = startY; y < size.height - 40; y += ringSpacing) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, y),
          width: ringWidth,
          height: ringHeight,
        ),
        paint,
      );
      canvas.drawCircle(
        Offset(centerX - 4, y),
        1.5,
        Paint()..color = AppColors.outlineVariant.withValues(alpha: 0.4),
      );
      canvas.drawCircle(
        Offset(centerX + 4, y),
        1.5,
        Paint()..color = AppColors.outlineVariant.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Header ───────────────────────────────────────────────────────

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Consumer<BirdProvider>(
      builder: (context, _, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, AppSpacing.marginMobile, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AvesQuest',
                    style: AppTypography.headlineLgMobile().copyWith(
                      fontSize: 24,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 48,
                    height: 28,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 2,
                          child: Icon(Icons.eco_rounded,
                              size: 16,
                              color:
                                  AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        Positioned(
                          left: 8,
                          top: 6,
                          child: Icon(Icons.eco_rounded,
                              size: 14,
                              color:
                                  AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        Positioned(
                          left: 16,
                          top: 0,
                          child: Icon(Icons.eco_rounded,
                              size: 20,
                              color:
                                  AppColors.primary.withValues(alpha: 0.35)),
                        ),
                        Positioned(
                          left: 28,
                          top: 4,
                          child: Icon(Icons.eco_rounded,
                              size: 12,
                              color:
                                  AppColors.primary.withValues(alpha: 0.50)),
                        ),
                        Positioned(
                          left: 34,
                          top: 8,
                          child: Icon(Icons.eco_rounded,
                              size: 10,
                              color:
                                  AppColors.primary.withValues(alpha: 0.65)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _JournalTabToggle(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab toggle ───────────────────────────────────────────────────

class _JournalTabToggle extends StatelessWidget {
  const _JournalTabToggle({required this.controller});

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
            border:
                Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              _JournalSegment(
                label: 'Collection',
                icon: Icons.collections_bookmark_rounded,
                isSelected: controller.index == 0,
                onTap: () => controller.animateTo(0),
              ),
              const SizedBox(width: 4),
              _JournalSegment(
                label: 'Pending',
                icon: Icons.hourglass_empty_rounded,
                isSelected: controller.index == 1,
                onTap: () => controller.animateTo(1),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JournalSegment extends StatelessWidget {
  const _JournalSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.surface
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTypography.labelSm(
                      color: isSelected
                          ? AppColors.surface
                          : AppColors.onSurfaceVariant,
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

// ── Collection tab ───────────────────────────────────────────────

class _CollectionTab extends StatefulWidget {
  const _CollectionTab();

  @override
  State<_CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends State<_CollectionTab> {
  Rarity? _rarityFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterSegments(),
        Expanded(
          child: Consumer<BirdProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.birds.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary));
              }

              var birds = provider.birds;
              if (_rarityFilter != null) {
                birds =
                    birds.where((b) => b.rarity == _rarityFilter).toList();
              }
              if (_searchQuery.isNotEmpty) {
                birds = birds
                    .where((b) =>
                        b.name.toLowerCase().contains(_searchQuery) ||
                        b.species.toLowerCase().contains(_searchQuery) ||
                        b.habitat.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (birds.isEmpty) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppSpacing.marginMobile),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.collections_bookmark_rounded,
                            size: 48,
                            color: AppColors.outline
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('No birds collected yet',
                            style: AppTypography.titleMd(
                                color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Start catching to build your AvesQuest!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd(
                                color: AppColors.outline)),
                      ],
                    ),
                  ),
                );
              }

              final highlightedId =
                  context.watch<BirdProvider>().highlightedBirdId;
              return GridView.builder(
                padding:
                    const EdgeInsets.all(AppSpacing.marginMobile),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.71,
                ),
                itemCount: birds.length,
                itemBuilder: (context, index) {
                  final bird = birds[index];
                  return BirdGridCard(
                    bird: bird,
                    index: birds.length - index,
                    isHighlighted: bird.id == highlightedId,
                    onTap: () {
                      context.read<BirdProvider>().clearHighlight();
                      Navigator.of(context).push(
                          ScaleFadeRoute(
                            builder: (_) => BirdDetailScreen(
                              bird: bird,
                              cardIndex: birds.length - index,
                              totalCount: provider.count,
                            ),
                          ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile,
          AppSpacing.sm, AppSpacing.marginMobile, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search by name, species, or habitat...',
          hintStyle:
              AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.outline),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSegments() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile, AppSpacing.sm, AppSpacing.marginMobile, 0),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border:
              Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _RaritySegment(
                label: 'ALL',
                isSelected: _rarityFilter == null,
                onTap: () => setState(() => _rarityFilter = null),
              ),
              const SizedBox(width: 3),
              ...Rarity.values.map((r) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: _RaritySegment(
                      label: r.label,
                      color: switch (r) {
                        Rarity.common => AppColors.rarityCommon,
                        Rarity.uncommon => AppColors.rarityUncommon,
                        Rarity.rare => AppColors.rarityRare,
                        Rarity.legendary => AppColors.rarityLegendary,
                      },
                      isSelected: _rarityFilter == r,
                      onTap: () => setState(
                          () => _rarityFilter = _rarityFilter == r ? null : r),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RaritySegment extends StatelessWidget {
  const _RaritySegment({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? (color ?? AppColors.primary) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: (color ?? AppColors.primary).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surface : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (color != null) const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTypography.labelSm(
                    color: isSelected
                        ? AppColors.surface
                        : AppColors.onSurfaceVariant,
                  ).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pending tab ──────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  const _PendingTab({required this.onBirdIdentified});

  final void Function(Bird bird) onBirdIdentified;

  @override
  Widget build(BuildContext context) {
    return Consumer2<PendingQueueProvider, IdentificationProvider>(
      builder: (context, queue, ident, _) {
        final activeItems = queue.queue
            .where(
              (item) => item.status != QueueStatus.done,
            )
            .toList();

        if (activeItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 48,
                      color: AppColors.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('All caught up!',
                      style: AppTypography.titleMd(
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('No pending identifications.',
                      style: AppTypography.bodyMd(color: AppColors.outline)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (queue.failedCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile,
                    AppSpacing.sm, AppSpacing.marginMobile, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        ident.isProcessing ? null : () => ident.processAllWaiting(),
                    icon: ident.isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onPrimary),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                        ident.isProcessing ? 'Processing...' : 'Retry All'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                itemCount: activeItems.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = activeItems[index];
                  return _QueueCard(
                    item: item,
                    isProcessing: ident.currentlyProcessingId == item.id,
                    onRetry: () async {
                      final bird = await ident.processQueueItem(item);
                      if (bird != null && context.mounted) {
                        onBirdIdentified(bird);
                      }
                    },
                    onDelete: () => queue.removeFromQueue(item.id!),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.item,
    required this.isProcessing,
    required this.onRetry,
    required this.onDelete,
  });

  final PendingQueueItem item;
  final bool isProcessing;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.standard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.standard)),
            child: SizedBox(
              width: 72,
              height: 72,
              child: OrientedImage(
                file: File(item.photoPath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceContainerHighest,
                  child:
                      const Icon(Icons.broken_image, color: AppColors.outline),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(child: _StatusChip(status: item.status)),
                      if (item.retryCount > 0) ...[
                        const SizedBox(width: 6),
                        Text('x${item.retryCount}',
                            style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_formatDate(item.queuedAt),
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant)),
                  if (item.lastError != null) ...[
                    const SizedBox(height: 2),
                    Text(item.lastError!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm(color: AppColors.error)),
                  ],
                ],
              ),
            ),
          ),
          if (item.status == QueueStatus.failed)
            IconButton(
              onPressed: isProcessing ? null : onRetry,
              icon: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded,
                      color: AppColors.primary),
            ),
          IconButton(
            onPressed: item.status == QueueStatus.syncing ? null : onDelete,
            icon: Icon(Icons.close_rounded,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                size: 18),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final QueueStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      QueueStatus.waiting => (AppColors.tertiary, 'Waiting'),
      QueueStatus.syncing => (AppColors.sunnyYellow, 'Identifying...'),
      QueueStatus.failed => (AppColors.error, 'Failed'),
      QueueStatus.done => (AppColors.rarityCommon, 'Done'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label,
          style:
              AppTypography.labelSm(color: color).copyWith(fontSize: 10)),
    );
  }
}
