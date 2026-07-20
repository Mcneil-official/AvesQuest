import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the single SQLite database connection for AvesQuest and defines the
/// schema for Phase 1: the `birds` table and the `pending_queue` table.
///
/// This class is intentionally dumb — it knows how to open the database
/// and create tables, nothing about bird-shaped business logic. All actual
/// querying lives in `BirdRepository` / a future `PendingQueueRepository`,
/// which keeps the rest of the app from ever importing `sqflite` directly.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'birddex.db';
  static const int _dbVersion = 3;

  static const String birdsTable = 'birds';
  static const String pendingQueueTable = 'pending_queue';

  Database? _db;

  /// Returns the open database, opening (and creating tables on first
  /// run) if necessary. Safe to call repeatedly — the connection is
  /// cached after the first call.
  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final db = await _open();
    _db = db;
    return db;
  }

  Future<Database> _open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      final columns = await db.rawQuery("PRAGMA table_info($birdsTable)");
      final hasLength = columns.any((c) => c['name'] == 'length');
      final hasWeight = columns.any((c) => c['name'] == 'weight');
      final hasCountry = columns.any((c) => c['name'] == 'country');

      if (!hasLength) {
        await db.execute('ALTER TABLE $birdsTable ADD COLUMN length REAL');
      }
      if (!hasWeight) {
        await db.execute('ALTER TABLE $birdsTable ADD COLUMN weight REAL');
      }
      if (!hasCountry) {
        await db.execute(
            "ALTER TABLE $birdsTable ADD COLUMN country TEXT NOT NULL DEFAULT ''");
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $birdsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        rarity TEXT NOT NULL,
        habitat TEXT NOT NULL,
        diet TEXT NOT NULL,
        fun_facts TEXT NOT NULL DEFAULT '',
        photo_path TEXT NOT NULL,
        caught_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        confidence REAL,
        length REAL,
        weight REAL,
        country TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE $pendingQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        photo_path TEXT NOT NULL,
        queued_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'waiting',
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Helpful indexes for the queries the grid/log/stats screens will run.
    await db.execute('CREATE INDEX idx_birds_caught_at ON $birdsTable (caught_at)');
    await db.execute('CREATE INDEX idx_birds_rarity ON $birdsTable (rarity)');
    await db.execute('CREATE INDEX idx_queue_status ON $pendingQueueTable (status)');
  }

  /// Closes the database connection. Mainly useful for tests.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
