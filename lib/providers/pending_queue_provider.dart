import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/pending_queue_item.dart';
import '../repositories/pending_queue_repository.dart';

class PendingQueueProvider extends ChangeNotifier {
  PendingQueueProvider({PendingQueueRepository? repository})
      : _repository = repository ?? PendingQueueRepository() {
    loadQueue();
  }

  final PendingQueueRepository _repository;

  List<PendingQueueItem> _queue = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PendingQueueItem> get queue => List.unmodifiable(_queue);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get count => _queue.length;
  int get activeCount => _queue.where((item) => item.status != QueueStatus.done).length;
  int get waitingCount => _queue.where((item) => item.status == QueueStatus.waiting).length;
  int get failedCount => _queue.where((item) => item.status == QueueStatus.failed).length;

  List<PendingQueueItem> get waitingItems =>
      _queue.where((item) => item.status == QueueStatus.waiting).toList();

  List<PendingQueueItem> get failedItems =>
      _queue.where((item) => item.status == QueueStatus.failed).toList();

  Future<void> loadQueue() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _queue = await _repository.getQueue();
    } catch (e) {
      _errorMessage = 'Could not load pending queue: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PendingQueueItem> addToQueue(PendingQueueItem item) async {
    final saved = await _repository.addItem(item);
    _queue = [saved, ..._queue];
    notifyListeners();
    return saved;
  }

  Future<void> removeFromQueue(int id) async {
    final match = _queue.where((e) => e.id == id).toList();
    await _repository.deleteItem(id);
    _queue = _queue.where((item) => item.id != id).toList();
    if (match.isNotEmpty) _deletePhoto(match.first.photoPath);
    notifyListeners();
  }

  void _deletePhoto(String path) {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  Future<void> updateItem(PendingQueueItem item) async {
    await _repository.updateItem(item);
    _queue = _queue.map((e) => e.id == item.id ? item : e).toList();
    notifyListeners();
  }
}
