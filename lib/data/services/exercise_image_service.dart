import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result from fetching exercise info from wger.de API.
class ExerciseInfoResult {
  final String? imageUrl;
  final String? shortDescription;

  ExerciseInfoResult({this.imageUrl, this.shortDescription});
}

/// Fetches exercise images and descriptions from the free wger.de REST API.
/// No API key required — reads are public.
class ExerciseImageService {
  static const _baseUrl = 'https://wger.de/api/v2';

  // Cache: exercise name → ExerciseInfoResult
  final Map<String, ExerciseInfoResult> _cache = {};

  // Lazy-loaded full catalog from wger.de: wger exercise name → id
  Map<String, int>? _wgerNameToId;

  /// Returns image URL and short description for the given exercise name.
  Future<ExerciseInfoResult> getExerciseInfo(String exerciseName) async {
    final key = exerciseName.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      // Ensure the full wger catalog is loaded
      await _ensureCatalogLoaded();

      final searchTerm = _mapToWgerSearch(exerciseName);

      // Find matching exercise in the full catalog
      int? matchedId;
      final lowerSearch = searchTerm.toLowerCase();

      // Exact match first
      if (_wgerNameToId!.containsKey(lowerSearch)) {
        matchedId = _wgerNameToId![lowerSearch];
      }

      // Partial match fallback
      if (matchedId == null) {
        for (final entry in _wgerNameToId!.entries) {
          if (entry.key.contains(lowerSearch) || lowerSearch.contains(entry.key)) {
            matchedId = entry.value;
            break;
          }
        }
      }

      if (matchedId == null) {
        return _cacheAndReturn(key, ExerciseInfoResult());
      }

      // Fetch full exercise info for the matched ID (includes images)
      final infoUrl = Uri.parse('$_baseUrl/exerciseinfo/$matchedId/')
          .replace(queryParameters: {'format': 'json', 'language': '2'});

      final infoResponse = await http.get(infoUrl);
      if (infoResponse.statusCode != 200) {
        return _cacheAndReturn(key, ExerciseInfoResult());
      }

      final infoJson = jsonDecode(infoResponse.body) as Map<String, dynamic>;

      // Extract image URL
      String? imageUrl;
      final images = infoJson['images'] as List<dynamic>? ?? [];
      if (images.isNotEmpty) {
        for (final img in images) {
          if (img['is_main'] == true) {
            imageUrl = img['image'] as String?;
            break;
          }
        }
        imageUrl ??= images.first['image'] as String?;
      }

      // Extract short description
      String? shortDescription;
      final translations = infoJson['translations'] as List<dynamic>? ?? [];
      for (final t in translations) {
        if (t['language'] == 2) {
          final desc = t['description'] as String? ?? '';
          shortDescription = _stripHtml(desc);
          if (shortDescription.trim().isEmpty) shortDescription = null;
          break;
        }
      }

      return _cacheAndReturn(key, ExerciseInfoResult(
        imageUrl: imageUrl,
        shortDescription: shortDescription,
      ));
    } catch (e) {
      debugPrint('getExerciseInfo error for "$exerciseName": $e');
      return _cacheAndReturn(key, ExerciseInfoResult());
    }
  }

  /// Load the full wger.de exercise catalog by paginating through all results.
  Future<void> _ensureCatalogLoaded() async {
    if (_wgerNameToId != null) return;
    _wgerNameToId = {};

    var url = Uri.parse('$_baseUrl/exerciseinfo/')
        .replace(queryParameters: {'format': 'json', 'language': '2', 'limit': '200'});

    while (url != Uri()) {
      final response = await http.get(url);
      if (response.statusCode != 200) break;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>;

      for (final result in results) {
        final id = result['id'] as int?;
        final translations = result['translations'] as List<dynamic>? ?? [];
        for (final t in translations) {
          if (t['language'] == 2) {
            final name = (t['name'] as String? ?? '').toLowerCase().trim();
            if (name.isNotEmpty && id != null) {
              _wgerNameToId![name] = id;
            }
          }
        }
      }

      final next = json['next'] as String?;
      url = next != null ? Uri.parse(next) : Uri();
    }

    debugPrint('Loaded ${_wgerNameToId!.length} exercises from wger.de');
  }

  /// Map our exercise names to wger.de search terms.
  String _mapToWgerSearch(String name) {
    final lower = name.toLowerCase().replaceAll('_', ' ');

    // Direct mappings to wger exercise names
    const nameMap = <String, String>{
      'barbell bench press': 'bench press',
      'incline dumbbell press': 'incline bench press',
      'dumbbell fly': 'flyes',
      'push up': 'push-ups',
      'push-up': 'push-ups',
      'chest dip': 'dips',
      'barbell row': 'barbell row',
      'dumbbell row': 'dumbbell row',
      'lat pulldown': 'lat pulldown',
      'pull up': 'pull-ups',
      'pull-up': 'pull-ups',
      'seated cable row': 'cable row',
      'overhead press': 'overhead press',
      'barbell overhead press': 'overhead press',
      'dumbbell lateral raise': 'lateral raise',
      'face pull': 'face pull',
      'arnold press': 'arnold press',
      'barbell curl': 'barbell curl',
      'dumbbell curl': 'dumbbell curl',
      'hammer curl': 'hammer curl',
      'concentration curl': 'concentration curl',
      'tricep dip': 'dips',
      'skull crusher': 'skull crusher',
      'tricep pushdown': 'tricep pushdown',
      'overhead tricep extension': 'overhead triceps',
      'barbell squat': 'barbell squat',
      'squat': 'barbell squat',
      'leg press': 'leg press',
      'bulgarian split squat': 'bulgarian split squat',
      'leg extension': 'leg extension',
      'deadlift': 'deadlift',
      'barbell deadlift': 'deadlift',
      'romanian deadlift': 'romanian deadlift',
      'leg curl': 'leg curl',
      'glute bridge': 'glute bridge',
      'hip thrust': 'hip thrust',
      'glute kickback': 'kickback',
      'calf raise': 'calf raise',
      'plank': 'plank',
      'russian twist': 'russian twist',
      'hanging leg raise': 'hanging leg raises',
      'ab wheel rollout': 'ab wheel roll-out',
      'cable crossover': 'cable crossover',
      'decline dumbbell press': 'decline bench press',
      'dumbbell pullover': 'pullover',
      't bar row': 't-bar row',
      'straight arm pulldown': 'straight arm pulldown',
      'dumbbell overhead press': 'dumbbell shoulder press',
      'reverse fly': 'reverse flyes',
      'upright row': 'upright row',
      'preacher curl': 'preacher curl',
      'cable curl': 'cable curl',
      'ez bar curl': 'ez-bar curl',
      'incline dumbbell curl': 'incline dumbbell curl',
      'close grip bench press': 'close grip bench press',
      'bench dip': 'bench dips',
      'goblet squat': 'goblet squat',
      'front squat': 'front squat',
      'hack squat': 'hack squat',
      'kettlebell swing': 'kettlebell swing',
      'good morning': 'good mornings',
      'nordic curl': 'nordic curl',
      'single leg rdl': 'single leg romanian deadlift',
      'cable pull through': 'cable pull-through',
      'sumo deadlift': 'sumo deadlift',
      'donkey calf raise': 'donkey calf raises',
      'bicycle crunch': 'bicycle crunches',
      'dead bug': 'dead bug',
      'pallof press': 'pallof press',
      'mountain climber': 'mountain climbers',
      'mountain climber core': 'mountain climbers',
      'renegade row': 'renegade row',
      'squeeze press': 'squeeze press',
      'machine chest press': 'chest press',
      'inverted row': 'inverted row',
      'single arm cable row': 'single arm cable row',
      'cuban press': 'cuban press',
      'trx tricep press': 'overhead triceps',
      'sissy squat': 'sissy squat',
      'banded lateral walk': 'lateral band walk',
      'frog pump': 'frog pumps',
      'single leg calf raise': 'single leg calf raise',
      'decline bench press': 'decline bench press',
      'latissimus': 'lat pulldown',
    };

    for (final entry in nameMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Fallback: use significant words
    final words = lower.split(RegExp(r'[\s_]+')).where((w) => w.length > 2).toList();
    return words.join(' ');
  }

  Future<String?> searchImageByName(String exerciseName) async {
    final info = await getExerciseInfo(exerciseName);
    return info.imageUrl;
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  ExerciseInfoResult _cacheAndReturn(String key, ExerciseInfoResult value) {
    _cache[key] = value;
    return value;
  }
}
