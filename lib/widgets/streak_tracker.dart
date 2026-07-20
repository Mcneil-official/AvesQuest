import 'package:flutter/material.dart';

import '../models/bird.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class StreakTracker extends StatefulWidget {
  const StreakTracker({super.key, required this.birds});

  final List<Bird> birds;

  @override
  State<StreakTracker> createState() => _StreakTrackerState();
}

class _StreakTrackerState extends State<StreakTracker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = _computeStreak();
    final hasStreak = streak > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: hasStreak ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Icon(
              hasStreak
                  ? Icons.local_fire_department_rounded
                  : Icons.local_fire_department_outlined,
              color: hasStreak ? AppColors.rarityRare : AppColors.outline,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$streak',
            style: AppTypography.displayLg(
                    color: hasStreak ? AppColors.rarityRare : AppColors.outline)
                .copyWith(fontSize: 28),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'day streak',
            style: AppTypography.bodyMd(
                color: hasStreak ? AppColors.onSurface : AppColors.outline),
          ),
        ],
      ),
    );
  }

  int _computeStreak() {
    if (widget.birds.isEmpty) return 0;

    final dates = widget.birds
        .map((b) =>
            DateTime(b.caughtAt.year, b.caughtAt.month, b.caughtAt.day))
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
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
