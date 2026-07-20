/// Status of a single pending-queue entry.
///
/// Phase 1 only needs the shape of this table to exist (gallery/camera
/// capture lands in Phase 2, AI identification in Phase 3, and retry
/// handling in Phase 4) — but the statuses are defined now so the schema
/// doesn't need to change shape later.
enum QueueStatus {
  /// Waiting to be sent for identification (e.g. captured while offline,
  /// or just not synced yet).
  waiting,

  /// Currently being sent to the identification proxy.
  syncing,

  /// The proxy/API call failed (network, timeout, etc.) — stays in the
  /// queue per the plan's "never silently drop a queued photo" rule.
  failed,

  /// Identification finished and a Bird row now exists for this photo.
  done;

  String toDbValue() => name;

  static QueueStatus fromDbValue(String value) {
    return QueueStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => QueueStatus.waiting,
    );
  }
}

/// A single entry in the `pending_queue` table — one row per photo that's
/// been captured/selected but not yet successfully identified.
///
/// This is intentionally separate from [Bird]: a queue item doesn't have
/// a species, rarity, etc. yet. Once identification succeeds, a Bird row
/// is created/updated and this queue item's status flips to [QueueStatus.done].
class PendingQueueItem {
  final int? id;

  /// Local filesystem path to the captured/selected photo.
  final String photoPath;

  /// When the photo was captured or added to the queue.
  final DateTime queuedAt;

  final QueueStatus status;

  /// Number of sync attempts made so far — useful for surfacing
  /// "tried 3 times" style messaging and for backoff logic in Phase 4.
  final int retryCount;

  /// Last error message, if the most recent attempt failed. Null otherwise.
  final String? lastError;

  const PendingQueueItem({
    this.id,
    required this.photoPath,
    required this.queuedAt,
    this.status = QueueStatus.waiting,
    this.retryCount = 0,
    this.lastError,
  });

  PendingQueueItem copyWith({
    int? id,
    String? photoPath,
    DateTime? queuedAt,
    QueueStatus? status,
    int? retryCount,
    String? lastError,
  }) {
    return PendingQueueItem(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
      queuedAt: queuedAt ?? this.queuedAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'photo_path': photoPath,
      'queued_at': queuedAt.toIso8601String(),
      'status': status.toDbValue(),
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory PendingQueueItem.fromMap(Map<String, Object?> map) {
    return PendingQueueItem(
      id: map['id'] as int?,
      photoPath: map['photo_path'] as String? ?? '',
      queuedAt: DateTime.parse(map['queued_at'] as String),
      status: QueueStatus.fromDbValue(map['status'] as String? ?? QueueStatus.waiting.name),
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  @override
  String toString() => 'PendingQueueItem(id: $id, status: $status, retries: $retryCount)';
}
