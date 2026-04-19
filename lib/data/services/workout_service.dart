import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import '../models/workout_exercise.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Workout>> getWorkoutsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _firestore
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Workout.fromFirestore(doc))
            .toList())
        .handleError((_) => <Workout>[]);
  }

  Future<List<Workout>> getWorkoutsForWeek(
    String userId,
    DateTime weekStart,
  ) async {
    final weekEnd = weekStart.add(const Duration(days: 6));

    try {
      final snapshot = await _firestore
          .collection('workouts')
          .where('userId', isEqualTo: userId)
          .where('scheduledDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('scheduledDate',
              isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
          .orderBy('scheduledDate')
          .get();

      return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('getWorkoutsForWeek error: $e');
      return [];
    }
  }

  Future<String> createWorkout(Workout workout) async {
    final docRef =
        await _firestore.collection('workouts').add(workout.toFirestore());
    return docRef.id;
  }

  Future<void> updateWorkout(
    String workoutId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('workouts').doc(workoutId).update(data);
  }

  Future<void> completeWorkout(
    String workoutId, {
    required int actualDurationMin,
    String? userNotes,
  }) async {
    await updateWorkout(workoutId, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'actualDurationMin': actualDurationMin,
      if (userNotes != null) 'userNotes': userNotes,
    });
  }

  Future<void> skipWorkout(String workoutId, {String? reason}) async {
    await updateWorkout(workoutId, {
      'status': 'skipped',
      if (reason != null) 'userNotes': reason,
    });
  }

  Future<List<WorkoutExercise>> getWorkoutExercises(String workoutId) async {
    try {
      final snapshot = await _firestore
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => WorkoutExercise.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('getWorkoutExercises error: $e');
      return [];
    }
  }

  Stream<Workout?> workoutStream(String workoutId) {
    return _firestore
        .collection('workouts')
        .doc(workoutId)
        .snapshots()
        .map((doc) => doc.exists ? Workout.fromFirestore(doc) : null)
        .handleError((_) => null);
  }

  /// Creates a workout document and its exercises subcollection in a single
  /// Firestore WriteBatch so everything succeeds or fails atomically.
  Future<String> createWorkoutWithExercises(
    Workout workout,
    List<WorkoutExercise> exercises,
  ) async {
    final batch = _firestore.batch();
    final workoutRef = _firestore.collection('workouts').doc();

    batch.set(workoutRef, workout.toFirestore());

    for (final exercise in exercises) {
      final exerciseRef =
          workoutRef.collection('exercises').doc(exercise.id);
      batch.set(exerciseRef, exercise.toFirestore());
    }

    await batch.commit();
    return workoutRef.id;
  }

  /// Deletes a workout document and all documents in its exercises
  /// subcollection.
  Future<void> deleteWorkout(String workoutId) async {
    final workoutRef = _firestore.collection('workouts').doc(workoutId);

    // Delete exercises subcollection first.
    final exercisesSnapshot =
        await workoutRef.collection('exercises').get();
    final batch = _firestore.batch();
    for (final doc in exercisesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(workoutRef);
    await batch.commit();
  }

  /// Returns the most recent [limit] workouts for the given user, ordered by
  /// scheduled date descending.
  Future<List<Workout>> getRecentWorkouts(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('workouts')
          .where('userId', isEqualTo: userId)
          .orderBy('scheduledDate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Workout.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('getRecentWorkouts error: $e');
      return [];
    }
  }

  /// Overwrites the exercises subcollection for the given workout by deleting
  /// all existing exercise documents and writing the new list in a single
  /// WriteBatch.
  Future<void> updateWorkoutExercises(
    String workoutId,
    List<WorkoutExercise> exercises,
  ) async {
    final workoutRef = _firestore.collection('workouts').doc(workoutId);
    final exercisesSnapshot =
        await workoutRef.collection('exercises').get();

    final batch = _firestore.batch();

    // Remove existing exercises.
    for (final doc in exercisesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Write new exercises.
    for (final exercise in exercises) {
      final exerciseRef =
          workoutRef.collection('exercises').doc(exercise.id);
      batch.set(exerciseRef, exercise.toFirestore());
    }

    await batch.commit();
  }
}
