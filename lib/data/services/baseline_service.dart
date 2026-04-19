import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise_baseline.dart';
import '../../core/constants/app_constants.dart';

class BaselineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ExerciseBaseline?> getBaseline(String userId, String exerciseId) async {
    try {
      final snapshot = await _firestore
          .collection('exercise_baselines')
          .where('userId', isEqualTo: userId)
          .where('exerciseId', isEqualTo: exerciseId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ExerciseBaseline.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('getBaseline error: $e');
      return null;
    }
  }

  Future<List<ExerciseBaseline>> getAllBaselines(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('exercise_baselines')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => ExerciseBaseline.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('getAllBaselines error: $e');
      return [];
    }
  }

  Future<void> upsertBaseline(ExerciseBaseline baseline) async {
    try {
      final snapshot = await _firestore
          .collection('exercise_baselines')
          .where('userId', isEqualTo: baseline.userId)
          .where('exerciseId', isEqualTo: baseline.exerciseId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        await _firestore.collection('exercise_baselines').add(baseline.toFirestore());
      } else {
        await snapshot.docs.first.reference.update(baseline.toFirestore());
      }
    } catch (e) {
      debugPrint('upsertBaseline error: $e');
    }
  }

  /// Update baseline from a completed session using exponential moving average.
  Future<void> updateBaselineFromSession(
    String userId,
    String exerciseId,
    double avgWeight,
    int avgReps,
  ) async {
    final existing = await getBaseline(userId, exerciseId);
    final alpha = AppConstants.baselineSmoothingFactor;
    final now = DateTime.now();

    if (existing == null) {
      // First session — establish baseline directly
      await upsertBaseline(ExerciseBaseline(
        id: '',
        userId: userId,
        exerciseId: exerciseId,
        baselineWeightKg: avgWeight,
        baselineReps: avgReps,
        baselineDate: now,
        lastWeekAvgWeight: avgWeight,
        lastWeekAvgReps: avgReps,
        updatedAt: now,
      ));
    } else {
      // EMA update
      final newWeight = (existing.baselineWeightKg ?? avgWeight) * (1 - alpha) + avgWeight * alpha;
      final newReps = ((existing.baselineReps ?? avgReps) * (1 - alpha) + avgReps * alpha).round();
      await upsertBaseline(existing.copyWith(
        baselineWeightKg: newWeight,
        baselineReps: newReps,
        lastWeekAvgWeight: avgWeight,
        lastWeekAvgReps: avgReps,
      ));
    }
  }
}
