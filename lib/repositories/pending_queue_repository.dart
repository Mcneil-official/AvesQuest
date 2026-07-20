import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/pending_queue_item.dart';

/// Abstracts every database operation involving the `pending_queue` table.
///
/// Phase 1 only needs this table and its basic CRUD to exist alongside
/// `BirdRepository` — the actual capture flow (Phase 2), AI sync
/// (Phase 3), and retry UI (Phase 4) build on top of this later.
class PendingQueueRepository {
  PendingQueueRepository({AppDatabase? database}) : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  /// Adds a new item to the pending queue and returns it with its id.
  Future<PendingQueueItem> addItem(PendingQueueItem item) async {
    final db = await _db;
    final id = await db.insert(
      AppDatabase.pendingQueueTable,
      item.toMap()..remove('id'),
    );
    return item.copyWith(id: id);
  }

  /// Returns every item currently in the queue, oldest first (FIFO —
  /// matches how a "Retry All" action should process the backlog).
  Future<List<PendingQueueItem>> getQueue() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.pendingQueueTable,
      orderBy: 'queued_at ASC',
    );
    return rows.map(PendingQueueItem.fromMap).toList();
  }

  /// Returns only items that still need attention (not yet [QueueStatus.done]).
  Future<List<PendingQueueItem>> getActiveQueue() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.pendingQueueTable,
      where: 'status != ?',
      whereArgs: [QueueStatus.done.toDbValue()],
      orderBy: 'queued_at ASC',
    );
    return rows.map(PendingQueueItem.fromMap).toList();
  }

  /// Count of active (not-yet-done) items — backs the pending counter
  /// badge called for in Phase 4.
  Future<int> getActiveCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${AppDatabase.pendingQueueTable} WHERE status != ?',
      [QueueStatus.done.toDbValue()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateItem(PendingQueueItem item) async {
    assert(item.id != null, 'Cannot update a PendingQueueItem with a null id');
    final db = await _db;
    await db.update(
      AppDatabase.pendingQueueTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Deletes an item by id (e.g. once it's been turned into a Bird and no
  /// longer needs to occupy a queue slot).
  Future<int> deleteItem(int id) async {
    final db = await _db;
    return db.delete(
      AppDatabase.pendingQueueTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Removes every row from the pending_queue table. Debug/dev use only.
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete(AppDatabase.pendingQueueTable);
  }
}
