import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../providers/identification_provider.dart';
import '../providers/pending_queue_provider.dart';

/// Listens for connectivity changes and automatically processes waiting
/// queue items when the device comes online.
///
/// Connectivity is treated as a *hint only* — the actual identification
/// call wraps itself in timeout and error handling regardless.
class AutoSyncService {
  AutoSyncService({
    required PendingQueueProvider pendingQueueProvider,
    required IdentificationProvider identificationProvider,
  })  : _pendingQueueProvider = pendingQueueProvider,
        _identificationProvider = identificationProvider;

  final PendingQueueProvider _pendingQueueProvider;
  final IdentificationProvider _identificationProvider;

  StreamSubscription? _subscription;
  bool _wasOffline = false;

  void start() {
    _checkAndSync();
    _subscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChange);
  }

  Future<void> _onConnectivityChange(List<ConnectivityResult> result) async {
    final isOffline = result.contains(ConnectivityResult.none);
    if (_wasOffline && !isOffline) {
      await _pendingQueueProvider.loadQueue();
      await _identificationProvider.processAllWaiting();
    }
    _wasOffline = isOffline;
  }

  Future<void> _checkAndSync() async {
    final result = await Connectivity().checkConnectivity();
    _wasOffline = result.contains(ConnectivityResult.none);
    if (!_wasOffline) {
      await _pendingQueueProvider.loadQueue();
      if (_pendingQueueProvider.waitingCount > 0) {
        await _identificationProvider.processAllWaiting();
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
