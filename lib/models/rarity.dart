/// App-defined rarity tiers.
///
/// Per the development plan's Rarity Tier System: rarity is never generated
/// freely by the AI. Claude identifies a species name only; the app looks
/// that name up in a bundled, static table (see [RarityTable] in
/// `data/rarity_table.dart`) to assign a tier. If a species isn't in the
/// table yet, it defaults to [Rarity.common].
enum Rarity {
  common,
  uncommon,
  rare,
  legendary;

  /// Human-readable label used in the UI (e.g. card badges, journal grid).
  String get label {
    switch (this) {
      case Rarity.common:
        return 'Common';
      case Rarity.uncommon:
        return 'Uncommon';
      case Rarity.rare:
        return 'Rare';
      case Rarity.legendary:
        return 'Legendary';
    }
  }

  /// Short tag used on compact UI like the journal grid chips
  /// (mirrors the "Rare Sight" / "Common Friend" / "Epic Find" style
  /// copy seen in the reference designs).
  String get sightingTag {
    switch (this) {
      case Rarity.common:
        return 'Common Friend';
      case Rarity.uncommon:
        return 'Uncommon Sight';
      case Rarity.rare:
        return 'Rare Sight';
      case Rarity.legendary:
        return 'Legendary Find';
    }
  }

  /// Stored as plain text in SQLite (`TEXT` column) rather than an int
  /// index, so the database stays human-readable and resilient to enum
  /// reordering.
  String toDbValue() => name;

  static Rarity fromDbValue(String value) {
    return Rarity.values.firstWhere(
      (r) => r.name == value,
      orElse: () => Rarity.common,
    );
  }
}
