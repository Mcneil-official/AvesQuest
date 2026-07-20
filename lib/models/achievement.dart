import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bird.dart';

enum AchievementId {
  firstCatch,
  flockOf10,
  century,
  rareFinder,
  earlyBird,
  nightOwl,
  weekendWarrior,
}

class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const all = [
    Achievement(
      id: AchievementId.firstCatch,
      title: 'First Catch',
      description: 'Record your first bird sighting',
      icon: Icons.emoji_events_rounded,
      color: AppColors.sunnyYellow,
    ),
    Achievement(
      id: AchievementId.flockOf10,
      title: 'Flock of 10',
      description: 'Catch 10 different birds',
      icon: Icons.emoji_events_rounded,
      color: AppColors.sunnyYellow,
    ),
    Achievement(
      id: AchievementId.century,
      title: 'Century',
      description: 'Catch 100 birds',
      icon: Icons.emoji_events_rounded,
      color: AppColors.rarityLegendary,
    ),
    Achievement(
      id: AchievementId.rareFinder,
      title: 'Rare Finder',
      description: 'Discover a rare or legendary bird',
      icon: Icons.star_rounded,
      color: AppColors.rarityRare,
    ),
    Achievement(
      id: AchievementId.earlyBird,
      title: 'Early Bird',
      description: 'Catch a bird before 7 AM',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.sunnyYellow,
    ),
    Achievement(
      id: AchievementId.nightOwl,
      title: 'Night Owl',
      description: 'Catch a bird after 8 PM',
      icon: Icons.nights_stay_rounded,
      color: AppColors.primaryContainer,
    ),
    Achievement(
      id: AchievementId.weekendWarrior,
      title: 'Weekend Warrior',
      description: 'Catch a bird on a weekend',
      icon: Icons.weekend_rounded,
      color: AppColors.tertiary,
    ),
  ];

  bool isUnlocked(List<Bird> birds) {
    return switch (id) {
      AchievementId.firstCatch => birds.isNotEmpty,
      AchievementId.flockOf10 => birds.length >= 10,
      AchievementId.century => birds.length >= 100,
      AchievementId.rareFinder => birds.any((b) => b.rarity == Rarity.rare || b.rarity == Rarity.legendary),
      AchievementId.earlyBird => birds.any((b) => b.caughtAt.hour < 7),
      AchievementId.nightOwl => birds.any((b) => b.caughtAt.hour >= 20),
      AchievementId.weekendWarrior => birds.any((b) => b.caughtAt.weekday == DateTime.saturday || b.caughtAt.weekday == DateTime.sunday),
    };
  }
}
