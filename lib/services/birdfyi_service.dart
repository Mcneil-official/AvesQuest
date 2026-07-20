import 'dart:convert';

import 'package:http/http.dart' as http;

class BirdFyiData {
  final String habitat;
  final String diet;
  final List<String> funFacts;
  final double? lengthCm;
  final double? weightG;
  final String geographicRange;

  const BirdFyiData({
    this.habitat = '',
    this.diet = '',
    this.funFacts = const [],
    this.lengthCm,
    this.weightG,
    this.geographicRange = '',
  });
}

class BirdFyiService {
  BirdFyiService({http.Client? client, String baseUrl = 'https://birdfyi.com'})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;
  static const _timeout = Duration(seconds: 10);

  final Map<String, BirdFyiData> _cache = {};

  Future<BirdFyiData?> enrichBird(String commonName, String scientificName) async {
    final cacheKey = scientificName.toLowerCase().trim();
    if (cacheKey.isNotEmpty && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }
    if (cacheKey.isEmpty && commonName.isEmpty) return null;

    Map<String, dynamic>? json;

    if (commonName.isNotEmpty) {
      json = await _fetchBySlug(_toSlug(commonName));
    }

    if (json == null && scientificName.isNotEmpty) {
      json = await _fetchBySlug(_toSlug(scientificName));
    }

    if (json == null && scientificName.isNotEmpty) {
      final results = await _search(scientificName);
      if (results != null && results.isNotEmpty) {
        json = await _fetchBySlug(results.first);
      }
    }

    if (json == null && commonName.isNotEmpty) {
      final results = await _search(commonName);
      if (results != null && results.isNotEmpty) {
        json = await _fetchBySlug(results.first);
      }
    }

    BirdFyiData? data;
    if (json != null) {
      data = _parse(json);
    }

    if (data == null || data.funFacts.isEmpty) {
      final wiki = await _fetchWikipedia(commonName, scientificName);
      if (wiki != null) {
        data = data != null
            ? data._mergeWithWikipedia(wiki)
            : BirdFyiData(funFacts: wiki);
      }
    }

    if (data == null) return null;

    if (cacheKey.isNotEmpty) {
      _cache[cacheKey] = data;
    }
    return data;
  }

  String _toSlug(String commonName) {
    return commonName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<Map<String, dynamic>?> _fetchBySlug(String slug) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/birds/$slug/');
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    return null;
  }

  Future<List<String>?> _search(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/search/').replace(
        queryParameters: {'q': query},
      );
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final results = body['results'] as Map<String, dynamic>?;
        final birds = results?['birds'] as List<dynamic>?;
        if (birds != null && birds.isNotEmpty) {
          return birds.map((r) {
            final item = r as Map<String, dynamic>;
            return item['slug'] as String? ?? '';
          }).where((s) => s.isNotEmpty).toList();
        }
      }
    } catch (_) {}

    return null;
  }

  BirdFyiData _parse(Map<String, dynamic> json) {
    final description = json['description'] as String? ?? '';

    String habitat = json['habitat_description'] as String? ?? '';
    if (habitat.isEmpty) {
      final habitats = json['habitats'] as List<dynamic>?;
      if (habitats != null && habitats.isNotEmpty) {
        habitat = habitats.map((h) => h.toString()).join(', ');
      }
    }

    return BirdFyiData(
      habitat: habitat,
      diet: json['diet'] as String? ?? '',
      funFacts: _extractFacts(description),
      lengthCm: (json['length_cm'] as num?)?.toDouble(),
      weightG: (json['weight_g'] as num?)?.toDouble(),
      geographicRange: json['geographic_range'] as String? ?? '',
    );
  }

  List<String> _extractFacts(String description) {
    if (description.isEmpty) return [];
    return description
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().length > 20)
        .take(3)
        .map((s) {
          final t = s.trim();
          if ((t.startsWith('"') && t.endsWith('"')) ||
              (t.startsWith("'") && t.endsWith("'"))) {
            return t.substring(1, t.length - 1);
          }
          return t;
        })
        .toList();
  }

  Future<List<String>?> _fetchWikipedia(String commonName, String scientificName) async {
    final titles = <String>[];
    if (commonName.isNotEmpty) {
      titles.add(commonName.replaceAll(' ', '_'));
    }
    if (scientificName.isNotEmpty) {
      titles.add(scientificName.replaceAll(' ', '_'));
    }

    for (final title in titles) {
      try {
        final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$title');
        final response = await _client.get(
          uri,
          headers: {'Accept': 'application/json'},
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final extract = body['extract'] as String?;
          if (extract != null && extract.isNotEmpty) {
            return _extractFacts(extract);
          }
        }
      } catch (_) {}
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}

extension _BirdFyiDataMerge on BirdFyiData {
  BirdFyiData _mergeWithWikipedia(List<String> wikiFacts) {
    return BirdFyiData(
      habitat: habitat,
      diet: diet,
      funFacts: funFacts.isNotEmpty ? funFacts : wikiFacts,
      lengthCm: lengthCm,
      weightG: weightG,
      geographicRange: geographicRange,
    );
  }
}
