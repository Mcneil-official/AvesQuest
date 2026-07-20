import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/bird.dart';
import '../repositories/bird_repository.dart';

/// Exposes the AvesQuest collection to the widget tree via `provider`,
/// per the Tech Stack's chosen state management approach.
///
/// This is the only place screens should reach for bird data — it owns
/// loading state and keeps an in-memory cache in sync with SQLite so the
/// grid screen doesn't need to re-query on every rebuild.
class BirdProvider extends ChangeNotifier {
  BirdProvider({BirdRepository? repository}) : _repository = repository ?? BirdRepository();

  final BirdRepository _repository;

  List<Bird> _birds = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _highlightedBirdId;

  List<Bird> get birds => List.unmodifiable(_birds);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get count => _birds.length;
  bool get isEmpty => _birds.isEmpty;
  int? get highlightedBirdId => _highlightedBirdId;

  void highlightBird(int id) {
    _highlightedBirdId = id;
    notifyListeners();
  }

  void clearHighlight() {
    _highlightedBirdId = null;
    notifyListeners();
  }

  /// Loads (or reloads) the full collection from SQLite.
  Future<void> loadBirds() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _birds = await _repository.getAllBirds();
    } catch (e) {
      _errorMessage = 'Could not load your AvesQuest collection: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-sorts the in-memory list using the given option, re-fetching from
  /// the repository so the SQL ORDER BY does the actual work.
  Future<void> sortBy(BirdSortOption option) async {
    _isLoading = true;
    notifyListeners();
    try {
      _birds = await _repository.getBirds(sortBy: option);
    } catch (e) {
      _errorMessage = 'Could not sort your AvesQuest collection: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new bird to the collection and refreshes local state.
  Future<Bird> addBird(Bird bird) async {
    final saved = await _repository.addBird(bird);
    _birds = [saved, ..._birds];
    notifyListeners();
    return saved;
  }

  Future<void> deleteBird(int id) async {
    final bird = _birds.firstWhere((b) => b.id == id, orElse: () => _birds.first);
    await _repository.deleteBird(id);
    _birds = _birds.where((b) => b.id != id).toList();
    _deletePhoto(bird.photoPath);
    notifyListeners();
  }

  void _deletePhoto(String path) {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
