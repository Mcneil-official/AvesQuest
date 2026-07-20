import 'package:flutter/material.dart';

import 'bird.dart';

enum QuestPeriod { daily, weekly, seasonal }

class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.period,
    required this.title,
    required this.description,
    required this.target,
    required this.xpReward,
    required this.icon,
    required this.computeProgress,
  });

  final String id;
  final QuestPeriod period;
  final String title;
  final String description;
  final int target;
  final int xpReward;
  final IconData icon;
  final int Function(List<Bird>, DateTime) computeProgress;

  bool get isDaily => period == QuestPeriod.daily;
  bool get isWeekly => period == QuestPeriod.weekly;
  bool get isSeasonal => period == QuestPeriod.seasonal;
}

class QuestState {
  QuestState({
    required this.questId,
    this.lastClaimed,
    required this.periodStart,
  });

  final String questId;
  DateTime? lastClaimed;
  DateTime periodStart;

  bool get claimed => lastClaimed != null;

  Map<String, dynamic> toJson() => {
        'questId': questId,
        'lastClaimed': lastClaimed?.toIso8601String(),
        'periodStart': periodStart.toIso8601String(),
      };

  factory QuestState.fromJson(Map<String, dynamic> json) => QuestState(
        questId: json['questId'] as String,
        lastClaimed: json['lastClaimed'] != null
            ? DateTime.parse(json['lastClaimed'] as String)
            : null,
        periodStart: DateTime.parse(json['periodStart'] as String),
      );
}

DateTime periodStartFor(QuestPeriod period, DateTime now) {
  switch (period) {
    case QuestPeriod.daily:
      return DateTime(now.year, now.month, now.day);
    case QuestPeriod.weekly:
      final monday = now.subtract(Duration(days: now.weekday - 1));
      return DateTime(monday.year, monday.month, monday.day);
    case QuestPeriod.seasonal:
      final quarter = ((now.month - 1) ~/ 3) + 1;
      final startMonth = (quarter - 1) * 3 + 1;
      return DateTime(now.year, startMonth, 1);
  }
}

List<QuestDefinition> allQuestDefinitions() {
  return [
    // Daily
    QuestDefinition(
      id: 'Morning Watch',
      period: QuestPeriod.daily,
      title: 'Morning Watch',
      description: 'Catch a bird before 10 AM',
      target: 1,
      xpReward: 150,
      icon: Icons.wb_twilight_rounded,
      computeProgress: (birds, now) {
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final todayBirds = birds
            .where((b) => b.caughtAt.isAfter(today) && b.caughtAt.isBefore(tomorrow))
            .toList();
        return todayBirds.any((b) => b.caughtAt.hour < 10) ? 1 : 0;
      },
    ),
    QuestDefinition(
      id: 'Photo Hunter',
      period: QuestPeriod.daily,
      title: 'Photo Hunter',
      description: 'Catch 3 birds today',
      target: 3,
      xpReward: 175,
      icon: Icons.camera_alt_rounded,
      computeProgress: (birds, now) {
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        return birds
            .where((b) => b.caughtAt.isAfter(today) && b.caughtAt.isBefore(tomorrow))
            .length
            .clamp(0, 3);
      },
    ),
    QuestDefinition(
      id: 'Golden Hour',
      period: QuestPeriod.daily,
      title: 'Golden Hour',
      description: 'Catch a bird between 4 PM and 8 PM',
      target: 1,
      xpReward: 100,
      icon: Icons.wb_sunny_rounded,
      computeProgress: (birds, now) {
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final todayBirds = birds
            .where((b) => b.caughtAt.isAfter(today) && b.caughtAt.isBefore(tomorrow))
            .toList();
        return todayBirds.any((b) => b.caughtAt.hour >= 16 && b.caughtAt.hour < 20) ? 1 : 0;
      },
    ),
    QuestDefinition(
      id: 'Rarity Spotter',
      period: QuestPeriod.daily,
      title: 'Rarity Spotter',
      description: 'Catch an uncommon, rare, or legendary bird',
      target: 1,
      xpReward: 125,
      icon: Icons.auto_awesome_rounded,
      computeProgress: (birds, now) {
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final todayBirds = birds
            .where((b) => b.caughtAt.isAfter(today) && b.caughtAt.isBefore(tomorrow))
            .toList();
        return todayBirds.any((b) => b.rarity != Rarity.common) ? 1 : 0;
      },
    ),
    QuestDefinition(
      id: 'Rapid Fire',
      period: QuestPeriod.daily,
      title: 'Rapid Fire',
      description: 'Catch 2 birds within 30 minutes',
      target: 1,
      xpReward: 100,
      icon: Icons.timer_rounded,
      computeProgress: (birds, now) {
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final todayBirds = birds
            .where((b) => b.caughtAt.isAfter(today) && b.caughtAt.isBefore(tomorrow))
            .toList()
          ..sort((a, b) => a.caughtAt.compareTo(b.caughtAt));
        for (var i = 1; i < todayBirds.length; i++) {
          if (todayBirds[i].caughtAt.difference(todayBirds[i - 1].caughtAt).inMinutes < 30) {
            return 1;
          }
        }
        return 0;
      },
    ),
    // Weekly
    QuestDefinition(
      id: 'Weekend Birder',
      period: QuestPeriod.weekly,
      title: 'Weekend Birder',
      description: 'Catch birds on 3 different days this week',
      target: 3,
      xpReward: 250,
      icon: Icons.calendar_view_week_rounded,
      computeProgress: (birds, now) {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(monday.year, monday.month, monday.day);
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekBirds = birds
            .where((b) => b.caughtAt.isAfter(weekStart) && b.caughtAt.isBefore(weekEnd))
            .toList();
        return weekBirds
            .where((b) => b.caughtAt.weekday >= 6)
            .map((b) => DateTime(b.caughtAt.year, b.caughtAt.month, b.caughtAt.day))
            .toSet()
            .length
            .clamp(0, 3);
      },
    ),
    QuestDefinition(
      id: 'Rare Collector',
      period: QuestPeriod.weekly,
      title: 'Rare Collector',
      description: 'Find a rare or legendary bird',
      target: 1,
      xpReward: 400,
      icon: Icons.star_rounded,
      computeProgress: (birds, now) {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(monday.year, monday.month, monday.day);
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekBirds = birds
            .where((b) => b.caughtAt.isAfter(weekStart) && b.caughtAt.isBefore(weekEnd))
            .toList();
        return weekBirds
                .any((b) => b.rarity == Rarity.rare || b.rarity == Rarity.legendary)
            ? 1
            : 0;
      },
    ),
    QuestDefinition(
      id: 'Species Collector',
      period: QuestPeriod.weekly,
      title: 'Species Collector',
      description: 'Catch 10 different species this week',
      target: 10,
      xpReward: 350,
      icon: Icons.biotech_rounded,
      computeProgress: (birds, now) {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(monday.year, monday.month, monday.day);
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekBirds = birds
            .where((b) => b.caughtAt.isAfter(weekStart) && b.caughtAt.isBefore(weekEnd))
            .toList();
        return weekBirds
            .map((b) => b.species)
            .where((s) => s.isNotEmpty)
            .toSet()
            .length
            .clamp(0, 10);
      },
    ),
    QuestDefinition(
      id: 'Steady Birder',
      period: QuestPeriod.weekly,
      title: 'Steady Birder',
      description: 'Catch birds on 5 different days this week',
      target: 5,
      xpReward: 400,
      icon: Icons.how_to_reg_rounded,
      computeProgress: (birds, now) {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(monday.year, monday.month, monday.day);
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekBirds = birds
            .where((b) => b.caughtAt.isAfter(weekStart) && b.caughtAt.isBefore(weekEnd))
            .toList();
        return weekBirds
            .map((b) => DateTime(b.caughtAt.year, b.caughtAt.month, b.caughtAt.day))
            .toSet()
            .length
            .clamp(0, 5);
      },
    ),
    QuestDefinition(
      id: 'Time Traveller',
      period: QuestPeriod.weekly,
      title: 'Time Traveller',
      description: 'Catch birds at 2 different times of day',
      target: 2,
      xpReward: 200,
      icon: Icons.access_time_rounded,
      computeProgress: (birds, now) {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(monday.year, monday.month, monday.day);
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekBirds = birds
            .where((b) => b.caughtAt.isAfter(weekStart) && b.caughtAt.isBefore(weekEnd))
            .toList();
        int timeOfDay(DateTime dt) {
          final h = dt.hour;
          if (h >= 5 && h < 12) return 0;
          if (h >= 12 && h < 17) return 1;
          if (h >= 17 && h < 21) return 2;
          return 3;
        }
        return weekBirds
            .map((b) => timeOfDay(b.caughtAt))
            .toSet()
            .length
            .clamp(0, 2);
      },
    ),
    // Seasonal
    QuestDefinition(
      id: 'Flock Builder',
      period: QuestPeriod.seasonal,
      title: 'Flock Builder',
      description: 'Catch 50 birds this season',
      target: 50,
      xpReward: 2000,
      icon: Icons.groups_rounded,
      computeProgress: (birds, now) {
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        final quarterStart = DateTime(now.year, startMonth, 1);
        final quarterEnd = quarterStart.add(const Duration(days: 92));
        return birds
            .where(
                (b) => b.caughtAt.isAfter(quarterStart) && b.caughtAt.isBefore(quarterEnd))
            .length
            .clamp(0, 50);
      },
    ),
    QuestDefinition(
      id: 'Volume Expert',
      period: QuestPeriod.seasonal,
      title: 'Volume Expert',
      description: 'Catch 100 birds this season',
      target: 100,
      xpReward: 3000,
      icon: Icons.speed_rounded,
      computeProgress: (birds, now) {
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        final quarterStart = DateTime(now.year, startMonth, 1);
        final quarterEnd = quarterStart.add(const Duration(days: 92));
        return birds
            .where(
                (b) => b.caughtAt.isAfter(quarterStart) && b.caughtAt.isBefore(quarterEnd))
            .length
            .clamp(0, 100);
      },
    ),
    QuestDefinition(
      id: 'Legendary Hunt',
      period: QuestPeriod.seasonal,
      title: 'Legendary Hunt',
      description: 'Find a legendary bird',
      target: 1,
      xpReward: 1000,
      icon: Icons.workspace_premium_rounded,
      computeProgress: (birds, now) {
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        final quarterStart = DateTime(now.year, startMonth, 1);
        final quarterEnd = quarterStart.add(const Duration(days: 92));
        return birds
                .where((b) =>
                    b.caughtAt.isAfter(quarterStart) && b.caughtAt.isBefore(quarterEnd))
                .any((b) => b.rarity == Rarity.legendary)
            ? 1
            : 0;
      },
    ),
  ];
}
