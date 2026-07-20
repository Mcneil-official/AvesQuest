import 'rarity.dart';
export 'rarity.dart';

/// The core domain model for a single AvesQuest entry.
///
/// Field list follows the development plan exactly:
/// id, name, species, rarity, habitat, diet, funFacts, photoPath,
/// caughtAt, isSynced, confidence, length, weight, country.
///
/// A [Bird] can represent either:
///  - a fully identified, "caught" entry (confidence/rarity/etc. populated), or
///  - a placeholder row backing an entry still sitting in the pending queue
///    (name/species not yet known, isSynced = false).
class Bird {
  /// Local primary key. Null until inserted into SQLite (autoincrement).
  final int? id;

  /// Common name, e.g. "Golden Eagle". Empty/placeholder until identified.
  final String name;

  /// Scientific (binomial) name, e.g. "Aquila chrysaetos".
  final String species;

  /// App-assigned rarity tier — looked up from the static rarity table,
  /// never invented by the AI. See [Rarity].
  final Rarity rarity;

  /// Short habitat description, e.g. "Deep Canopy", "Wetland".
  final String habitat;

  /// Short diet description, e.g. "Small mammals, carrion".
  final String diet;

  /// A handful of fun facts about the species, shown on the card detail view.
  final List<String> funFacts;

  /// Local filesystem path to the user's own photo of the bird — this photo
  /// becomes the card art, per the core game loop.
  final String photoPath;

  /// When the photo was captured / the catch was logged.
  final DateTime caughtAt;

  /// Whether this entry has completed AI identification and synced into
  /// the main collection. `false` while sitting in the pending queue.
  final bool isSynced;

  /// AI confidence score for the identification, 0.0–1.0.
  /// Drives the "low confidence / best guess" UI flag from the
  /// Uncertainty Handling table. Null until an identification attempt
  /// has actually returned a result.
  final double? confidence;

  /// Body length in centimetres (nullable — not every species has data).
  final double? length;

  /// Body weight in grams (nullable — not every species has data).
  final double? weight;

  /// Country / region where this bird species is commonly found.
  final String country;

  const Bird({
    this.id,
    required this.name,
    required this.species,
    required this.rarity,
    required this.habitat,
    required this.diet,
    required this.funFacts,
    required this.photoPath,
    required this.caughtAt,
    required this.isSynced,
    this.confidence,
    this.length,
    this.weight,
    this.country = '',
  });

  /// Convenience constructor for a brand-new, not-yet-identified catch —
  /// i.e. the row created the moment a photo is queued (Phase 2/4 will
  /// populate this; Phase 1 just needs the shape to exist).
  factory Bird.pending({required String photoPath, required DateTime caughtAt}) {
    return Bird(
      name: '',
      species: '',
      rarity: Rarity.common,
      habitat: '',
      diet: '',
      funFacts: const [],
      photoPath: photoPath,
      caughtAt: caughtAt,
      isSynced: false,
      confidence: null,
      length: null,
      weight: null,
      country: '',
    );
  }

  /// Whether this bird has actually been identified yet (vs. still pending).
  bool get isIdentified => isSynced && name.isNotEmpty;

  /// Whether the identification is a "best guess" that should show the
  /// low-confidence flag in the UI (see Uncertainty Handling table —
  /// anything below this threshold gets visibly flagged).
  bool get isLowConfidence => confidence != null && confidence! < 0.6;

  Bird copyWith({
    int? id,
    String? name,
    String? species,
    Rarity? rarity,
    String? habitat,
    String? diet,
    List<String>? funFacts,
    String? photoPath,
    DateTime? caughtAt,
    bool? isSynced,
    double? confidence,
    double? length,
    double? weight,
    String? country,
  }) {
    return Bird(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      rarity: rarity ?? this.rarity,
      habitat: habitat ?? this.habitat,
      diet: diet ?? this.diet,
      funFacts: funFacts ?? this.funFacts,
      photoPath: photoPath ?? this.photoPath,
      caughtAt: caughtAt ?? this.caughtAt,
      isSynced: isSynced ?? this.isSynced,
      confidence: confidence ?? this.confidence,
      length: length ?? this.length,
      weight: weight ?? this.weight,
      country: country ?? this.country,
    );
  }

  /// Serializes for SQLite. funFacts is stored as a single TEXT column
  /// using a simple delimiter — no need for a join table at this scale,
  /// and it keeps BirdRepository's queries simple.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'rarity': rarity.toDbValue(),
      'habitat': habitat,
      'diet': diet,
      'fun_facts': funFacts.join(_factSeparator),
      'photo_path': photoPath,
      'caught_at': caughtAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'confidence': confidence,
      'length': length,
      'weight': weight,
      'country': country,
    };
  }

  factory Bird.fromMap(Map<String, Object?> map) {
    final rawFacts = map['fun_facts'] as String?;
    return Bird(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      species: map['species'] as String? ?? '',
      rarity: Rarity.fromDbValue(map['rarity'] as String? ?? Rarity.common.name),
      habitat: map['habitat'] as String? ?? '',
      diet: map['diet'] as String? ?? '',
      funFacts: (rawFacts == null || rawFacts.isEmpty)
          ? const []
          : rawFacts.split(_factSeparator),
      photoPath: map['photo_path'] as String? ?? '',
      caughtAt: DateTime.parse(map['caught_at'] as String),
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      confidence: (map['confidence'] as num?)?.toDouble(),
      length: (map['length'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      country: map['country'] as String? ?? '',
    );
  }

  static const String _factSeparator = '|||';

  @override
  String toString() => 'Bird(id: $id, name: $name, species: $species, rarity: ${rarity.label})';

  @override
  bool operator ==(Object other) => other is Bird && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
