import 'package:flutter/material.dart';

import '../models/rarity.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A small pill-shaped rarity badge, matching the "LEGENDARY" / "Rare" /
/// chip styles seen on the catch-reveal and journal screens.
///
/// Two visual modes:
///  - [RarityBadgeStyle.dot] — a colored dot + short label, used in the
///    journal grid (e.g. "● Rare Sight").
///  - [RarityBadgeStyle.pill] — a solid colored pill with optional icon,
///    used on the bird card itself (e.g. "★ LEGENDARY").
enum RarityBadgeStyle { dot, pill }

class RarityBadge extends StatelessWidget {
  const RarityBadge({
    super.key,
    required this.rarity,
    this.style = RarityBadgeStyle.dot,
  });

  final Rarity rarity;
  final RarityBadgeStyle style;

  Color get _accentColor {
    switch (rarity) {
      case Rarity.common:
        return AppColors.rarityCommon;
      case Rarity.uncommon:
        return AppColors.rarityUncommon;
      case Rarity.rare:
        return AppColors.rarityRare;
      case Rarity.legendary:
        return AppColors.rarityLegendary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (style == RarityBadgeStyle.dot) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              rarity.sightingTag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant).copyWith(fontSize: 13),
            ),
          ),
        ],
      );
    }

    final isLegendary = rarity == Rarity.legendary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isLegendary ? AppColors.rarityLegendary : _accentColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _accentColor.withValues(alpha: isLegendary ? 0.6 : 0.3)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLegendary) ...[
            const Icon(Icons.star_outline, size: 14, color: AppColors.onTertiary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            rarity.label.toUpperCase(),
            style: AppTypography.labelSm(
              color: isLegendary ? AppColors.onTertiary : AppColors.surface,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
