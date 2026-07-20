import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/bird.dart';

/// Sort options for the AvesQuest grid. Phase 1 only needs `caughtAt` (the
/// grid just needs to confirm data flows in and out), but the other two
/// are defined now since Phase 5 explicitly calls for "sorting by date,
/// rarity, or species name" on the same grid screen.
enum BirdSortOption { dateCaught, rarity, speciesName }

/// Abstracts every database operation involving the `birds` table so the
/// rest of the app (screens, widgets, future services) never touches
/// sqflite directly. Phase 1's job is just to get this layer right.
class BirdRepository {
  BirdRepository({AppDatabase? database}) : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  /// Inserts a new bird and returns it with its assigned [Bird.id].
  Future<Bird> addBird(Bird bird) async {
    final db = await _db;
    final id = await db.insert(
      AppDatabase.birdsTable,
      bird.toMap()..remove('id'),
    );
    return bird.copyWith(id: id);
  }

  /// Returns every bird in the collection, most-recently-caught first.
  Future<List<Bird>> getAllBirds() async {
    return getBirds(sortBy: BirdSortOption.dateCaught);
  }

  /// Returns birds sorted by the given [sortBy] option.
  Future<List<Bird>> getBirds({
    BirdSortOption sortBy = BirdSortOption.dateCaught,
  }) async {
    final db = await _db;
    final orderBy = switch (sortBy) {
      BirdSortOption.dateCaught => 'caught_at DESC',
      BirdSortOption.rarity => 'rarity DESC, caught_at DESC',
      BirdSortOption.speciesName => 'species ASC',
    };

    final rows = await db.query(AppDatabase.birdsTable, orderBy: orderBy);
    return rows.map(Bird.fromMap).toList();
  }

  /// Looks up a bird by its scientific name (species column).
  /// Returns null if no match is found.
  Future<Bird?> getBirdBySpecies(String species) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.birdsTable,
      where: 'species = ?',
      whereArgs: [species],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Bird.fromMap(rows.first);
  }

  /// Looks up a single bird by its local id, or null if it doesn't exist.
  Future<Bird?> getBirdById(int id) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.birdsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Bird.fromMap(rows.first);
  }

  /// Returns birds filtered to a single rarity tier — used by the stats
  /// screen's rarity breakdown (Phase 6) but harmless to have ready now.
  Future<List<Bird>> getBirdsByRarity(Rarity rarity) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.birdsTable,
      where: 'rarity = ?',
      whereArgs: [rarity.toDbValue()],
      orderBy: 'caught_at DESC',
    );
    return rows.map(Bird.fromMap).toList();
  }

  /// Total number of birds currently in the collection.
  Future<int> getBirdCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM ${AppDatabase.birdsTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Updates an existing bird. [bird.id] must be non-null.
  Future<void> updateBird(Bird bird) async {
    assert(bird.id != null, 'Cannot update a Bird with a null id');
    final db = await _db;
    await db.update(
      AppDatabase.birdsTable,
      bird.toMap(),
      where: 'id = ?',
      whereArgs: [bird.id],
    );
  }

  /// Deletes a bird by id. Returns the number of rows affected (0 or 1).
  Future<int> deleteBird(int id) async {
    final db = await _db;
    return db.delete(
      AppDatabase.birdsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Removes every row from the birds table. Intended for debug/dev use
  /// and tests only — never wired to a production UI action.
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete(AppDatabase.birdsTable);
  }
}
