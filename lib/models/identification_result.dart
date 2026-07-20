enum IdentificationStatus { identified, lowConfidence, notABird, unclear }

class IdentificationResult {
  final IdentificationStatus status;
  final String? commonName;
  final String? scientificName;
  final double? confidence;
  final String? habitat;
  final String? diet;
  final List<String> funFacts;
  final String? errorMessage;

  const IdentificationResult({
    required this.status,
    this.commonName,
    this.scientificName,
    this.confidence,
    this.habitat,
    this.diet,
    this.funFacts = const [],
    this.errorMessage,
  });

  bool get isIdentified => status == IdentificationStatus.identified;
  bool get isLowConfidence => status == IdentificationStatus.lowConfidence;
  bool get isNotABird => status == IdentificationStatus.notABird;
  bool get isUnclear => status == IdentificationStatus.unclear;
  bool get isFailure => isNotABird || isUnclear;

  factory IdentificationResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'unclear';
    final status = switch (rawStatus) {
      'identified' => IdentificationStatus.identified,
      'low_confidence' => IdentificationStatus.lowConfidence,
      'not_a_bird' => IdentificationStatus.notABird,
      _ => IdentificationStatus.unclear,
    };

    return IdentificationResult(
      status: status,
      commonName: json['common_name'] as String?,
      scientificName: json['scientific_name'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      habitat: json['habitat'] as String?,
      diet: json['diet'] as String?,
      funFacts: json['fun_facts'] != null
          ? List<String>.from(json['fun_facts'] as List)
          : const [],
      errorMessage: json['errorMessage'] as String?,
    );
  }

  factory IdentificationResult.error(String message) {
    return IdentificationResult(
      status: IdentificationStatus.unclear,
      errorMessage: message,
    );
  }
}
