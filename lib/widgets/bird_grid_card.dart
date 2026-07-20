import 'dart:io';

import 'package:flutter/material.dart';

import '../models/bird.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'oriented_image.dart';
import 'rarity_badge.dart';

class BirdGridCard extends StatelessWidget {
  const BirdGridCard({
    super.key,
    required this.bird,
    required this.index,
    this.level,
    this.isHighlighted = false,
    this.onTap,
  });

  final Bird bird;
  final int index;
  final int? level;
  final bool isHighlighted;
  final VoidCallback? onTap;

  ({Color border, Color glow, double width, Color? bgTint}) get _rarityStyle {
    return switch (bird.rarity) {
      Rarity.common => (
        border: AppColors.outlineVariant,
        glow: Colors.transparent,
        width: 1.0,
        bgTint: null,
      ),
      Rarity.uncommon => (
        border: AppColors.primaryContainer.withValues(alpha: 0.6),
        glow: AppColors.primaryContainer.withValues(alpha: 0.15),
        width: 1.5,
        bgTint: AppColors.primary.withValues(alpha: 0.03),
      ),
      Rarity.rare => (
        border: AppColors.rarityRare.withValues(alpha: 0.6),
        glow: AppColors.rarityRare.withValues(alpha: 0.2),
        width: 1.5,
        bgTint: AppColors.rarityRare.withValues(alpha: 0.03),
      ),
      Rarity.legendary => (
        border: AppColors.rarityLegendary,
        glow: AppColors.rarityLegendary.withValues(alpha: 0.3),
        width: 2.0,
        bgTint: AppColors.rarityLegendary.withValues(alpha: 0.05),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _rarityStyle;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: style.bgTint ?? AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: style.border, width: style.width),
          boxShadow: [
            BoxShadow(
              color: style.glow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CardImage(photoPath: bird.photoPath),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '#${index.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (level != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _LevelChip(level: level!),
                      ),
                    if (isHighlighted)
                      Positioned(
                        top: level != null ? 26.0 : 4.0,
                        right: 4,
                        child: const _NewBadge(),
                      ),
                    if (bird.rarity == Rarity.legendary)
                      const Positioned.fill(
                        child: _LegendaryShimmer(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bird.name.isEmpty ? 'Unidentified' : bird.name,
              style: AppTypography.labelSm().copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            RarityBadge(
              rarity: bird.rarity,
              style: RarityBadgeStyle.dot,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatefulWidget {
  const _NewBadge();

  @override
  State<_NewBadge> createState() => _NewBadgeState();
}

class _NewBadgeState extends State<_NewBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'NEW',
          style: TextStyle(
            color: AppColors.surface,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final file = File(photoPath);
    if (photoPath.isEmpty || !file.existsSync()) {
      return Container(
        color: AppColors.surfaceContainerHigh,
        child: const Icon(Icons.image_outlined,
            size: 24, color: AppColors.outline),
      );
    }
    return OrientedImage(
      file: file,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceContainerHigh,
        child: const Icon(Icons.broken_image, size: 24, color: AppColors.outline),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'LV. ${level.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: AppColors.surface,
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegendaryShimmer extends StatefulWidget {
  const _LegendaryShimmer();

  @override
  State<_LegendaryShimmer> createState() => _LegendaryShimmerState();
}

class _LegendaryShimmerState extends State<_LegendaryShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [
                Colors.transparent,
                AppColors.rarityLegendary.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}
