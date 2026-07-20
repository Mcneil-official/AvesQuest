import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The three-stat strip ("Regions", "Species", and "Caught") that sits just
/// above the bottom nav bar on the journal dashboard.
class JourneyStatsStrip extends StatelessWidget {
  const JourneyStatsStrip({
    super.key,
    required this.habitatsExplored,
    required this.distinctSpecies,
    required this.totalCatches,
  });

  final int habitatsExplored;
  final int distinctSpecies;
  final int totalCatches;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: _Stat(icon: Icons.forest, value: '$habitatsExplored', label: 'Regions')),
          _divider(),
          Expanded(child: _Stat(icon: Icons.biotech_rounded, value: '$distinctSpecies', label: 'Species')),
          _divider(),
          Expanded(child: _Stat(icon: Icons.confirmation_number_outlined, value: '$totalCatches', label: 'Caught')),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.outlineVariant);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.secondary),
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleMd().copyWith(fontSize: 18)),
        Text(
          label,
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
