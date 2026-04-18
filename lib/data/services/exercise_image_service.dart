import 'dart:convert';
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

  /// Returns image URL and short description for the given exercise name.
  Future<ExerciseInfoResult> getExerciseInfo(String exerciseName) async {
    final key = exerciseName.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      // Step 1: Search exercises using /exerciseinfo/ which includes translations
      final searchTerms = _extractSearchTerms(exerciseName);

      // Fetch first page of exercise info (includes translations with names)
      final searchUrl = Uri.parse('$_baseUrl/exerciseinfo/')
          .replace(queryParameters: {'format': 'json', 'language': '2', 'limit': '20'});

      final searchResponse = await http.get(searchUrl);
      if (searchResponse.statusCode != 200) {
        return _cacheAndReturn(key, ExerciseInfoResult());
      }

      final searchJson = jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final results = searchJson['results'] as List<dynamic>;

      // Find matching exercise by name in translations
      int? matchedId;
      for (final result in results) {
        final translations = result['translations'] as List<dynamic>?;
        if (translations == null) continue;

        for (final translation in translations) {
          final name = (translation['name'] as String? ?? '').toLowerCase();
          for (final term in searchTerms) {
            if (name.contains(term)) {
              matchedId = result['id'] as int?;
              break;
            }
          }
          if (matchedId != null) break;
        }
        if (matchedId != null) break;
      }

      if (matchedId == null) {
        return _cacheAndReturn(key, ExerciseInfoResult());
      }

      // Step 2: Fetch full exercise info for the matched ID (includes images)
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
        // Prefer main image
        for (final img in images) {
          if (img['is_main'] == true) {
            imageUrl = img['image'] as String?;
            break;
          }
        }
        imageUrl ??= images.first['image'] as String?;
      }

      // Extract short description from translations
      String? shortDescription;
      final translations = infoJson['translations'] as List<dynamic>? ?? [];
      for (final t in translations) {
        if (t['language'] == 2) {
          final desc = t['description'] as String? ?? '';
          // Strip HTML tags for clean text
          shortDescription = _stripHtml(desc);
          if (shortDescription.trim().isEmpty) {
            shortDescription = null;
          }
          break;
        }
      }

      return _cacheAndReturn(key, ExerciseInfoResult(
        imageUrl: imageUrl,
        shortDescription: shortDescription,
      ));
    } catch (_) {
      return _cacheAndReturn(key, ExerciseInfoResult());
    }
  }

  /// Backward-compatible method: returns just the image URL.
  Future<String?> searchImageByName(String exerciseName) async {
    final info = await getExerciseInfo(exerciseName);
    return info.imageUrl;
  }

  /// Backward-compatible method: returns just the image URL.
  Future<String?> getImageUrl(String exerciseName) async {
    final info = await getExerciseInfo(exerciseName);
    return info.imageUrl;
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _extractSearchTerms(String name) {
    final termMap = <String, List<String>>{
      'barbell squat': ['squat'],
      'deadlift': ['deadlift'],
      'romanian deadlift': ['romanian deadlift'],
      'lunge': ['lunge'],
      'bench press': ['bench press'],
      'row': ['row'],
      'overhead press': ['overhead press'],
      'plank': ['plank'],
      'push-up': ['push'],
      'push up': ['push'],
      'calf raise': ['calf raise'],
    };

    final lower = name.toLowerCase();
    for (final entry in termMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default: split into words, filter short ones
    return lower
        .split(RegExp(r'[\s_]+'))
        .where((w) => w.length > 3)
        .toList();
  }

  ExerciseInfoResult _cacheAndReturn(String key, ExerciseInfoResult value) {
    _cache[key] = value;
    return value;
  }
}
