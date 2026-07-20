import 'dart:io';

import 'package:flutter/material.dart';

import '../models/bird.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'oriented_image.dart';

/// The large, full-bleed photo card used in the "Recent Discoveries"
/// list on the journal dashboard — bird photo behind a bottom gradient,
/// with the name, habitat/location line, and a rarity pill overlaid.
///
/// This is visually distinct from [BirdGridCard] (the compact grid tile
/// used on the Journal Collection screen) — this one is the larger,
/// hero-style presentation used for the dashboard's highlight feed.
class RecentDiscoveryCard extends StatelessWidget {
  const RecentDiscoveryCard({
    super.key,
    required this.bird,
    this.onTap,
  });

  final Bird bird;
  final VoidCallback? onTap;

  Color get _pillColor {
    switch (bird.rarity) {
      case Rarity.common:
        return AppColors.onTertiaryContainer;
      case Rarity.uncommon:
        return AppColors.onTertiaryContainer;
      case Rarity.rare:
        return AppColors.secondaryContainer;
      case Rarity.legendary:
        return AppColors.secondaryContainer;
    }
  }

  Color get _pillTextColor {
    switch (bird.rarity) {
      case Rarity.common:
      case Rarity.uncommon:
        return AppColors.primary;
      case Rarity.rare:
      case Rarity.legendary:
        return AppColors.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AspectRatio(
            aspectRatio: 0.92,
            child: Stack(
            fit: StackFit.expand,
            children: [
              _Photo(photoPath: bird.photoPath),
              // Bottom gradient so white text stays legible over any photo.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.55, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bird.name.isEmpty ? 'Unidentified' : bird.name,
                            style: AppTypography.titleMd(color: Colors.white).copyWith(fontSize: 22),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (bird.habitat.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    bird.habitat,
                                    style: AppTypography.bodyMd(color: Colors.white70).copyWith(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _pillColor,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        bird.rarity.label,
                        style: AppTypography.bodyMd(color: _pillTextColor).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final file = File(photoPath);
    if (photoPath.isEmpty || !file.existsSync()) {
      return Container(
        color: AppColors.surfaceContainerHigh,
        child: const Icon(Icons.image_outlined, size: 40, color: AppColors.outline),
      );
    }
    return OrientedImage(
      file: file,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceContainerHigh,
        child: const Icon(Icons.broken_image, size: 40, color: AppColors.outline),
      ),
    );
  }
}
