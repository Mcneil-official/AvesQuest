import 'package:flutter/foundation.dart';

import '../data/rarity_table.dart';
import '../models/bird.dart';
import '../models/identification_result.dart';
import '../models/pending_queue_item.dart';
import '../repositories/bird_repository.dart';
import '../services/ai_service.dart';
import '../services/birdfyi_service.dart';
import 'pending_queue_provider.dart';

class IdentificationProvider extends ChangeNotifier {
  IdentificationProvider({
    AiService? aiService,
    BirdRepository? birdRepository,
    PendingQueueProvider? pendingQueueProvider,
    BirdFyiService? birdFyiService,
  })  : _aiService = aiService ??
            AiService(proxyUrl: const String.fromEnvironment('BIRDDEX_PROXY_URL', defaultValue: 'https://birddex-proxy.birddex.workers.dev')),
        _birdRepository = birdRepository ?? BirdRepository(),
        _pendingQueueProvider = pendingQueueProvider ?? PendingQueueProvider(),
        _birdFyiService = birdFyiService ?? BirdFyiService();

  final AiService _aiService;
  final BirdRepository _birdRepository;
  final PendingQueueProvider _pendingQueueProvider;
  final BirdFyiService _birdFyiService;

  bool _isProcessing = false;
  int? _currentlyProcessingId;
  String? _lastResult;

  bool get isProcessing => _isProcessing;
  int? get currentlyProcessingId => _currentlyProcessingId;
  String? get lastResult => _lastResult;
  bool get isIdle => !_isProcessing;

  Future<Bird?> processQueueItem(PendingQueueItem item) async {
    _isProcessing = true;
    _currentlyProcessingId = item.id;
    _lastResult = null;
    notifyListeners();

    try {
      await _pendingQueueProvider.updateItem(
        item.copyWith(status: QueueStatus.syncing),
      );

      final result = await _aiService.identifyPhoto(item.photoPath);

      if (result.errorMessage != null) {
        await _failItem(item, _friendlyError(result.errorMessage!));
        _lastResult = 'error: ${result.errorMessage}';
        return null;
      }

      switch (result.status) {
        case IdentificationStatus.identified:
          return _handleIdentified(item, result, isLowConfidence: false);
        case IdentificationStatus.lowConfidence:
          return _handleIdentified(item, result, isLowConfidence: true);
        case IdentificationStatus.notABird:
          await _failItem(item, 'Unidentified Species — no bird detected in photo');
          _lastResult = 'not_a_bird';
          return null;
        case IdentificationStatus.unclear:
          await _failItem(item, 'Unclear photo — please retake with better lighting');
          _lastResult = 'unclear';
          return null;
      }
    } catch (e) {
      await _failItem(item, _friendlyError('$e'));
      _lastResult = 'error: $e';
      return null;
    } finally {
      _isProcessing = false;
      _currentlyProcessingId = null;
      notifyListeners();
    }
  }

  /// Processes all waiting items in FIFO order, one at a time,
  /// with a short delay between each to avoid rate limits.
  Future<void> processAllWaiting() async {
    if (_isProcessing) return;

    final items = List<PendingQueueItem>.from(_pendingQueueProvider.waitingItems);
    for (final item in items) {
      if (_isProcessing) break;
      await processQueueItem(item);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<Bird> _handleIdentified(
    PendingQueueItem item,
    IdentificationResult result, {
    required bool isLowConfidence,
  }) async {
    final speciesName = result.commonName ?? 'Unknown Bird';
    final scientificName = result.scientificName ?? '';

    if (scientificName.isNotEmpty) {
      final existing = await _birdRepository.getBirdBySpecies(scientificName);
      if (existing != null) {
        await _pendingQueueProvider.updateItem(
          item.copyWith(status: QueueStatus.done),
        );
        _lastResult = 'duplicate: $speciesName';
        notifyListeners();
        return existing;
      }
    }

    final rarity = RarityTable.rarityFor(scientificName.isNotEmpty ? scientificName : null,
        speciesName.isNotEmpty ? speciesName : null);

    final enrichment = scientificName.isNotEmpty
        ? await _birdFyiService.enrichBird(speciesName, scientificName)
        : null;

    final bird = await _birdRepository.addBird(Bird(
      name: speciesName,
      species: scientificName,
      rarity: rarity,
      habitat: enrichment?.habitat.isNotEmpty == true
          ? enrichment!.habitat
          : result.habitat ?? '',
      diet: enrichment?.diet.isNotEmpty == true
          ? enrichment!.diet
          : result.diet ?? '',
      funFacts: enrichment?.funFacts.isNotEmpty == true
          ? enrichment!.funFacts
          : result.funFacts,
      length: enrichment?.lengthCm,
      weight: enrichment?.weightG,
      country: enrichment?.geographicRange ?? '',
      photoPath: item.photoPath,
      caughtAt: item.queuedAt,
      isSynced: true,
      confidence: result.confidence,
    ));

    await _pendingQueueProvider.updateItem(
      item.copyWith(status: QueueStatus.done),
    );

    _lastResult = 'identified: $speciesName';
    notifyListeners();
    return bird;
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('quota') || lower.contains('exceeded') || lower.contains('billing') || lower.contains('429') || lower.contains('rate limit')) {
      return 'AI quota exceeded — wait a moment and try again';
    }
    if (lower.contains('api_key') || lower.contains('api key') || lower.contains('401') || lower.contains('unauthorized')) {
      return 'AI service not configured on the server';
    }
    if (lower.contains('network') || lower.contains('connection') || lower.contains('socket')) {
      return raw;
    }
    if (lower.contains('not configured')) {
      return 'AI service not configured on the server';
    }
    return 'Identification failed: $raw';
  }

  Future<void> _failItem(PendingQueueItem item, String error) async {
    await _pendingQueueProvider.updateItem(
      item.copyWith(
        status: QueueStatus.failed,
        retryCount: item.retryCount + 1,
        lastError: error,
      ),
    );
    notifyListeners();
  }
}
