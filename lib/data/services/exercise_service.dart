import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Exercise>> getAllExercises() async {
    try {
    final snapshot = await _firestore.collection('exercises').get();
    return snapshot.docs
        .map((doc) => Exercise.fromFirestore(doc))
        .toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<Exercise>> exercisesStream() {
    return _firestore
        .collection('exercises')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Exercise.fromFirestore(doc))
            .toList())
        .handleError((_) => <Exercise>[]);
  }

  Future<List<Exercise>> getExercisesByEquipment(List<String> equipment) async {
    try {
    final snapshot = await _firestore
        .collection('exercises')
        .where('equipment', whereIn: equipment)
        .get();

    return snapshot.docs
        .map((doc) => Exercise.fromFirestore(doc))
        .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) async {
    try {
    final snapshot = await _firestore
        .collection('exercises')
        .where('primaryMuscles', arrayContains: muscleGroup)
        .get();

    return snapshot.docs
        .map((doc) => Exercise.fromFirestore(doc))
        .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Exercise?> getExercise(String exerciseId) async {
    try {
    final doc = await _firestore.collection('exercises').doc(exerciseId).get();
    if (doc.exists) {
      return Exercise.fromFirestore(doc);
    }
    return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> seedExercises() async {
    final exercises = [
      {
        'id': 'squat_barbell',
        'name': 'Barbell Squat',
        'primaryMuscles': ['quadriceps', 'glutes'],
        'secondaryMuscles': ['hamstrings', 'core'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 3,
        'boneDensityScore': 85,
      },
      {
        'id': 'deadlift_barbell',
        'name': 'Barbell Deadlift',
        'primaryMuscles': ['hamstrings', 'glutes', 'back'],
        'secondaryMuscles': ['core', 'forearms'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 4,
        'boneDensityScore': 90,
      },
      {
        'id': 'lunge_dumbbell',
        'name': 'Dumbbell Lunges',
        'primaryMuscles': ['quadriceps', 'glutes'],
        'secondaryMuscles': ['hamstrings', 'calves'],
        'equipment': 'dumbbell',
        'movementType': 'compound',
        'difficulty': 2,
        'isUnilateral': true,
        'boneDensityScore': 70,
      },
      {
        'id': 'bench_press_barbell',
        'name': 'Barbell Bench Press',
        'primaryMuscles': ['chest', 'triceps'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 3,
        'boneDensityScore': 75,
      },
      {
        'id': 'row_dumbbell',
        'name': 'Dumbbell Row',
        'primaryMuscles': ['back', 'biceps'],
        'secondaryMuscles': ['core'],
        'equipment': 'dumbbell',
        'movementType': 'compound',
        'difficulty': 2,
        'isUnilateral': true,
        'boneDensityScore': 65,
      },
      {
        'id': 'overhead_press_dumbbell',
        'name': 'Dumbbell Overhead Press',
        'primaryMuscles': ['shoulders', 'triceps'],
        'secondaryMuscles': ['core'],
        'equipment': 'dumbbell',
        'movementType': 'compound',
        'difficulty': 2,
        'boneDensityScore': 70,
      },
      {
        'id': 'romanian_deadlift_dumbbell',
        'name': 'Dumbbell Romanian Deadlift',
        'primaryMuscles': ['hamstrings', 'glutes'],
        'secondaryMuscles': ['back'],
        'equipment': 'dumbbell',
        'movementType': 'compound',
        'difficulty': 2,
        'boneDensityScore': 75,
      },
      {
        'id': 'calf_raise',
        'name': 'Standing Calf Raise',
        'primaryMuscles': ['calves'],
        'secondaryMuscles': [],
        'equipment': 'bodyweight',
        'movementType': 'isolation',
        'difficulty': 1,
        'boneDensityScore': 40,
      },
      {
        'id': 'plank',
        'name': 'Plank',
        'primaryMuscles': ['core'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'bodyweight',
        'movementType': 'isolation',
        'difficulty': 1,
        'boneDensityScore': 30,
      },
      {
        'id': 'push_up',
        'name': 'Push-Up',
        'primaryMuscles': ['chest', 'triceps'],
        'secondaryMuscles': ['shoulders', 'core'],
        'equipment': 'bodyweight',
        'movementType': 'compound',
        'difficulty': 1,
        'boneDensityScore': 50,
      },
    ];

    for (final exercise in exercises) {
      await _firestore
          .collection('exercises')
          .doc(exercise['id'] as String)
          .set(exercise);
    }
  }
}
