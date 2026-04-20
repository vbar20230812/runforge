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
///
/// Uses the search endpoint per-exercise instead of loading the full catalog,
/// which is much more reliable from localhost.
class ExerciseImageService {
  static const _baseUrl = 'https://wger.de/api/v2';
  static const _timeout = Duration(seconds: 8);
  static const _maxRetries = 3;

  // Cache: exercise name → ExerciseInfoResult
  final Map<String, ExerciseInfoResult> _cache = {};

  /// Returns image URL and short description for the given exercise name.
  ///
  /// Uses the wger search endpoint to find the exercise by name, then fetches
  /// its images via the exerciseinfo endpoint.
  Future<ExerciseInfoResult> getExerciseInfo(String exerciseName) async {
    final key = exerciseName.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final searchTerm = _mapToWgerSearch(exerciseName);

      // Step 1: Search for the exercise by name using the search endpoint
      final matchedId = await _searchExerciseByName(searchTerm);
      if (matchedId == null) {
        debugPrint('No wger match for "$exerciseName" (searched: "$searchTerm")');
        return _cacheAndReturn(key, ExerciseInfoResult());
      }

      // Step 2: Fetch full exercise info for the matched ID (includes images)
      final infoJson = await _getWithRetry(
        Uri.parse('$_baseUrl/exerciseinfo/$matchedId/')
            .replace(queryParameters: {'format': 'json', 'language': '2'}),
      );
      if (infoJson == null) {
        return _cacheAndReturn(key, ExerciseInfoResult());
      }

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

      debugPrint('wger: "$exerciseName" -> image=${imageUrl != null}');
      return _cacheAndReturn(key, ExerciseInfoResult(
        imageUrl: imageUrl,
        shortDescription: shortDescription,
      ));
    } catch (e) {
      debugPrint('getExerciseInfo error for "$exerciseName": $e');
      return _cacheAndReturn(key, ExerciseInfoResult());
    }
  }

  /// Search the wger /api/v2/exercise/ endpoint by name.
  /// Returns the exerciseinfo ID of the best match, or null.
  Future<int?> _searchExerciseByName(String searchTerm) async {
    final json = await _getWithRetry(
      Uri.parse('$_baseUrl/exercise/')
          .replace(queryParameters: {
            'format': 'json',
            'language': '2',
            'name': searchTerm,
          }),
    );
    if (json == null) return null;

    final results = json['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) return null;

    // Pick the first result — wger returns best matches first
    final firstResult = results.first as Map<String, dynamic>;
    final exerciseId = firstResult['id'] as int?;

    if (exerciseId == null) return null;

    // The /exercise/ endpoint returns the base exercise ID.
    // We need the exerciseinfo ID which may differ.
    // Fetch exerciseinfo filtered by this exercise ID.
    final infoJson = await _getWithRetry(
      Uri.parse('$_baseUrl/exerciseinfo/')
          .replace(queryParameters: {
            'format': 'json',
            'language': '2',
            'exercise': '$exerciseId',
          }),
    );
    if (infoJson == null) return null;

    final infoResults = infoJson['results'] as List<dynamic>? ?? [];
    if (infoResults.isEmpty) return exerciseId; // fallback to base ID

    return (infoResults.first as Map<String, dynamic>)['id'] as int?;
  }

  /// HTTP GET with retry and exponential backoff.
  Future<Map<String, dynamic>?> _getWithRetry(Uri url) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http.get(url).timeout(_timeout);
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        if (response.statusCode == 429) {
          // Rate limited — wait longer
          final delay = Duration(seconds: 2 * (attempt + 1));
          debugPrint('Rate limited, retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          continue;
        }
        // Non-retryable status
        debugPrint('wger HTTP ${response.statusCode} for $url');
        return null;
      } catch (e) {
        if (attempt < _maxRetries - 1) {
          final delay = Duration(seconds: 1 << attempt); // 1s, 2s, 4s
          debugPrint('wger attempt ${attempt + 1} failed: $e, retrying in ${delay.inSeconds}s');
          await Future.delayed(delay);
        } else {
          debugPrint('wger all retries exhausted for $url: $e');
        }
      }
    }
    return null;
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
