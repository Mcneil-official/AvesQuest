import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bird.dart';
import '../models/quest.dart';
import 'bird_provider.dart';

class QuestProvider extends ChangeNotifier {
  QuestProvider({required BirdProvider birdProvider})
      : _birdProvider = birdProvider {
    birdProvider.addListener(_onBirdsChanged);
  }

  final BirdProvider _birdProvider;
  SharedPreferences? _prefs;
  final List<QuestDefinition> _definitions = allQuestDefinitions();
  final Map<String, QuestState> _states = {};
  bool _isLoading = false;
  int _totalXp = 0;

  List<QuestDefinition> get definitions => List.unmodifiable(_definitions);
  bool get isLoading => _isLoading;
  int get totalXp => _totalXp;

  List<Bird> get _birds => _birdProvider.birds;

  void _onBirdsChanged() {
    notifyListeners();
  }

  List<QuestDefinition> questsFor(QuestPeriod period) =>
      _definitions.where((q) => q.period == period).toList();

  int progressFor(QuestDefinition quest) {
    final now = DateTime.now();
    return quest.computeProgress(_birds, now).clamp(0, quest.target);
  }

  bool isAtTarget(QuestDefinition quest) =>
      progressFor(quest) >= quest.target;

  bool isClaimed(QuestDefinition quest) {
    final state = _states[quest.id];
    if (state == null) return false;
    if (!_isCurrentPeriod(quest.period, state.periodStart)) return false;
    return state.claimed;
  }

  bool canClaim(QuestDefinition quest) =>
      !isClaimed(quest) && isAtTarget(quest);

  int completedCount(QuestPeriod period) =>
      questsFor(period).where((q) => isClaimed(q)).length;

  int totalCount(QuestPeriod period) => questsFor(period).length;

  static final List<int> _cumulativeXp = _buildCumulativeXp();

  static List<int> _buildCumulativeXp() {
    final list = <int>[0];
    int xp = 100;
    for (int level = 2; level <= 1000; level++) {
      list.add(list.last + xp);
      if (level < 10) {
        xp += 20;
      } else if (level < 25) {
        xp += 30;
      } else if (level < 45) {
        xp += 40;
      } else if (level < 70) {
        xp += 50;
      } else if (level < 100) {
        xp += 60;
      }
    }
    return list;
  }

  int levelFromXp(int xp) {
    if (xp < 0) return 0;
    for (int i = 0; i < _cumulativeXp.length; i++) {
      if (xp < _cumulativeXp[i]) return i;
    }
    return _cumulativeXp.length;
  }

  int xpForLevel(int level) {
    if (level <= 1) return 0;
    if (level > _cumulativeXp.length) return _cumulativeXp.last;
    return _cumulativeXp[level - 1];
  }

  int get currentLevel => levelFromXp(_totalXp);

  int get xpInCurrentLevel => _totalXp - xpForLevel(currentLevel);

  int get xpNeededForNextLevel {
    final next = xpForLevel(currentLevel + 1);
    return next - _totalXp;
  }

  bool _isCurrentPeriod(QuestPeriod period, DateTime storedStart) {
    final currentStart = periodStartFor(period, DateTime.now());
    return storedStart.year == currentStart.year &&
        storedStart.month == currentStart.month &&
        storedStart.day == currentStart.day;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();

    _totalXp = _prefs!.getInt('totalXp') ?? 0;

    final statesJson = _prefs!.getString('questStates');
    if (statesJson != null && statesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(statesJson) as List<dynamic>;
        _states.clear();
        for (final entry in decoded) {
          final state = QuestState.fromJson(Map<String, dynamic>.from(entry));
          _states[state.questId] = state;
        }
      } catch (_) {
        _states.clear();
      }
    }

    _checkPeriodReset();

    _isLoading = false;
    notifyListeners();
  }

  void _checkPeriodReset() {
    for (final period in QuestPeriod.values) {
      for (final quest in questsFor(period)) {
        final state = _states[quest.id];
        if (state != null && !_isCurrentPeriod(period, state.periodStart)) {
          _states.remove(quest.id);
        }
      }
    }
  }

  Future<void> claimQuest(String questId) async {
    final quest = _definitions.firstWhere((q) => q.id == questId);
    _totalXp += quest.xpReward;

    final now = DateTime.now();
    _states[questId] = QuestState(
      questId: questId,
      lastClaimed: now,
      periodStart: periodStartFor(quest.period, now),
    );

    await _persist();
    notifyListeners();
  }

  Future<void> claimAll(QuestPeriod period) async {
    for (final quest in questsFor(period)) {
      if (canClaim(quest)) {
        _totalXp += quest.xpReward;

        final now = DateTime.now();
        _states[quest.id] = QuestState(
          questId: quest.id,
          lastClaimed: now,
          periodStart: periodStartFor(quest.period, now),
        );
      }
    }

    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _prefs!.setInt('totalXp', _totalXp);
    final statesList = _states.values.map((s) => s.toJson()).toList();
    await _prefs!.setString('questStates', jsonEncode(statesList));
  }

  @override
  void dispose() {
    _birdProvider.removeListener(_onBirdsChanged);
    super.dispose();
  }
}
