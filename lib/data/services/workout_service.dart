import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<List<Workout>> getWorkoutsForWeek(DateTime weekStart) async {
    final userId = _firestore.app.options.projectId;
    final weekEnd = weekStart.add(const Duration(days: 6));

    try {
    final snapshot = await _firestore
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
        .orderBy('scheduledDate')
        .get();

    return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> createWorkout(Workout workout) async {
    final docRef = await _firestore.collection('workouts').add(workout.toFirestore());
    return docRef.id;
  }

  Future<void> updateWorkout(String workoutId, Map<String, dynamic> data) async {
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
}
