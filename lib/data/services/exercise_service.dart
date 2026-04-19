import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      final doc =
          await _firestore.collection('exercises').doc(exerciseId).get();
      if (doc.exists) {
        return Exercise.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> seedExercises() async {
    final exercises = <Map<String, dynamic>>[
      // === CHEST (5) ===
      {
        'id': 'bench_press_barbell',
        'name': 'Barbell Bench Press',
        'primaryMuscles': ['chest', 'triceps'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 75,
      },
      {
        'id': 'incline_dumbbell_press',
        'name': 'Incline Dumbbell Press',
        'primaryMuscles': ['chest', 'shoulders'],
        'secondaryMuscles': ['triceps'],
        'equipment': 'dumbbell',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 70,
      },
      {
        'id': 'dumbbell_fly',
        'name': 'Dumbbell Fly',
        'primaryMuscles': ['chest'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'dumbbell',
        'movementType': 'isolation',
        'difficulty': 2,
        'isUnilateral': false,
        'boneDensityScore': 40,
      },
      {
        'id': 'push_up',
        'name': 'Push-Up',
        'primaryMuscles': ['chest', 'triceps'],
        'secondaryMuscles': ['shoulders', 'core'],
        'equipment': 'bodyweight',
        'movementType': 'compound',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 50,
      },
      {
        'id': 'chest_dip',
        'name': 'Chest Dip',
        'primaryMuscles': ['chest', 'triceps'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'bodyweight',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 60,
      },

      // === BACK (5) ===
      {
        'id': 'barbell_row',
        'name': 'Barbell Row',
        'primaryMuscles': ['back', 'biceps'],
        'secondaryMuscles': ['core'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 70,
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
        'id': 'lat_pulldown',
        'name': 'Lat Pulldown',
        'primaryMuscles': ['back', 'biceps'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'cable',
        'movementType': 'compound',
        'difficulty': 2,
        'isUnilateral': false,
        'boneDensityScore': 50,
      },
      {
        'id': 'pull_up',
        'name': 'Pull-Up',
        'primaryMuscles': ['back', 'biceps'],
        'secondaryMuscles': ['core'],
        'equipment': 'bodyweight',
        'movementType': 'compound',
        'difficulty': 4,
        'isUnilateral': false,
        'boneDensityScore': 65,
      },
      {
        'id': 'seated_cable_row',
        'name': 'Seated Cable Row',
        'primaryMuscles': ['back', 'biceps'],
        'secondaryMuscles': ['core'],
        'equipment': 'cable',
        'movementType': 'compound',
        'difficulty': 2,
        'isUnilateral': false,
        'boneDensityScore': 50,
      },

      // === SHOULDERS (4) ===
      {
        'id': 'overhead_press_barbell',
        'name': 'Overhead Press Barbell',
        'primaryMuscles': ['shoulders', 'triceps'],
        'secondaryMuscles': ['core'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 75,
      },
      {
        'id': 'dumbbell_lateral_raise',
        'name': 'Dumbbell Lateral Raise',
        'primaryMuscles': ['shoulders'],
        'secondaryMuscles': ['traps'],
        'equipment': 'dumbbell',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 30,
      },
      {
        'id': 'face_pull',
        'name': 'Face Pull',
        'primaryMuscles': ['shoulders', 'rear_delts'],
        'secondaryMuscles': ['upper_back'],
        'equipment': 'cable',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 25,
      },
      {
        'id': 'arnold_press',
        'name': 'Arnold Press',
        'primaryMuscles': ['shoulders', 'triceps'],
        'secondaryMuscles': ['core'],
        'equipment': 'dumbbell',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 65,
      },

      // === BICEPS (4) ===
      {
        'id': 'barbell_curl',
        'name': 'Barbell Curl',
        'primaryMuscles': ['biceps'],
        'secondaryMuscles': ['forearms'],
        'equipment': 'barbell',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 30,
      },
      {
        'id': 'dumbbell_curl',
        'name': 'Dumbbell Curl',
        'primaryMuscles': ['biceps'],
        'secondaryMuscles': ['forearms'],
        'equipment': 'dumbbell',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': true,
        'boneDensityScore': 30,
      },
      {
        'id': 'hammer_curl',
        'name': 'Hammer Curl',
        'primaryMuscles': ['biceps', 'brachialis'],
        'secondaryMuscles': ['forearms'],
        'equipment': 'dumbbell',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': true,
        'boneDensityScore': 30,
      },
      {
        'id': 'concentration_curl',
        'name': 'Concentration Curl',
        'primaryMuscles': ['biceps'],
        'secondaryMuscles': ['forearms'],
        'equipment': 'dumbbell',
        'movementType': 'isolation',
        'difficulty': 2,
        'isUnilateral': true,
        'boneDensityScore': 25,
      },

      // === TRICEPS (4) ===
      {
        'id': 'tricep_dip',
        'name': 'Tricep Dip',
        'primaryMuscles': ['triceps', 'chest'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'bodyweight',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 55,
      },
      {
        'id': 'skull_crusher',
        'name': 'Skull Crusher',
        'primaryMuscles': ['triceps'],
        'secondaryMuscles': ['elbows'],
        'equipment': 'barbell',
        'movementType': 'isolation',
        'difficulty': 2,
        'isUnilateral': false,
        'boneDensityScore': 40,
      },
      {
        'id': 'tricep_pushdown',
        'name': 'Tricep Pushdown',
        'primaryMuscles': ['triceps'],
        'secondaryMuscles': ['forearms'],
        'equipment': 'cable',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 25,
      },
      {
        'id': 'overhead_tricep_extension',
        'name': 'Overhead Tricep Extension',
        'primaryMuscles': ['triceps'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'dumbbell',
        'movementType': 'isolation',
        'difficulty': 2,
        'isUnilateral': false,
        'boneDensityScore': 35,
      },

      // === QUADRICEPS (4) ===
      {
        'id': 'squat_barbell',
        'name': 'Barbell Squat',
        'primaryMuscles': ['quadriceps', 'glutes'],
        'secondaryMuscles': ['hamstrings', 'core'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 85,
      },
      {
        'id': 'leg_press',
        'name': 'Leg Press',
        'primaryMuscles': ['quadriceps'],
        'secondaryMuscles': ['glutes'],
        'equipment': 'machine',
        'movementType': 'compound',
        'difficulty': 2,
        'isUnilateral': false,
        'boneDensityScore': 75,
      },
      {
        'id': 'bulgarian_split_squat',
        'name': 'Bulgarian Split Squat',
        'primaryMuscles': ['quadriceps', 'glutes'],
        'secondaryMuscles': ['hamstrings'],
        'equipment': 'dumbbell',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': true,
        'boneDensityScore': 70,
      },
      {
        'id': 'leg_extension',
        'name': 'Leg Extension',
        'primaryMuscles': ['quadriceps'],
        'secondaryMuscles': [],
        'equipment': 'machine',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 40,
      },

      // === HAMSTRINGS (4) ===
      {
        'id': 'deadlift_barbell',
        'name': 'Barbell Deadlift',
        'primaryMuscles': ['hamstrings', 'glutes', 'back'],
        'secondaryMuscles': ['core', 'forearms'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 4,
        'isUnilateral': false,
        'boneDensityScore': 90,
      },
      {
        'id': 'romanian_deadlift_dumbbell',
        'name': 'Dumbbell Romanian Deadlift',
        'primaryMuscles': ['hamstrings', 'glutes'],
        'secondaryMuscles': ['back'],
        'equipment': 'dumbbell',
        'movementType': 'compound',
        'difficulty': 2,
        'isUnilateral': false,
        'boneDensityScore': 75,
      },
      {
        'id': 'leg_curl',
        'name': 'Leg Curl',
        'primaryMuscles': ['hamstrings'],
        'secondaryMuscles': ['calves'],
        'equipment': 'machine',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 35,
      },
      {
        'id': 'glute_bridge',
        'name': 'Glute Bridge',
        'primaryMuscles': ['glutes', 'hamstrings'],
        'secondaryMuscles': ['core'],
        'equipment': 'bodyweight',
        'movementType': 'compound',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 60,
      },

      // === GLUTES (2) ===
      {
        'id': 'hip_thrust',
        'name': 'Hip Thrust',
        'primaryMuscles': ['glutes'],
        'secondaryMuscles': ['hamstrings', 'core'],
        'equipment': 'barbell',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 80,
      },
      {
        'id': 'glute_kickback',
        'name': 'Glute Kickback',
        'primaryMuscles': ['glutes'],
        'secondaryMuscles': ['hamstrings'],
        'equipment': 'cable',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 30,
      },

      // === CALVES (2) ===
      {
        'id': 'calf_raise_standing',
        'name': 'Standing Calf Raise',
        'primaryMuscles': ['calves'],
        'secondaryMuscles': [],
        'equipment': 'bodyweight',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 45,
      },
      {
        'id': 'calf_raise_seated',
        'name': 'Seated Calf Raise',
        'primaryMuscles': ['calves'],
        'secondaryMuscles': [],
        'equipment': 'machine',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 40,
      },

      // === CORE (4) ===
      {
        'id': 'plank',
        'name': 'Plank',
        'primaryMuscles': ['core'],
        'secondaryMuscles': ['shoulders'],
        'equipment': 'bodyweight',
        'movementType': 'isolation',
        'difficulty': 1,
        'isUnilateral': false,
        'boneDensityScore': 30,
      },
      {
        'id': 'russian_twist',
        'name': 'Russian Twist',
        'primaryMuscles': ['core', 'obliques'],
        'secondaryMuscles': ['hip_flexors'],
        'equipment': 'bodyweight',
        'movementType': 'isolation',
        'difficulty': 2,
        'isUnilateral': false,
        'boneDensityScore': 30,
      },
      {
        'id': 'hanging_leg_raise',
        'name': 'Hanging Leg Raise',
        'primaryMuscles': ['core', 'hip_flexors'],
        'secondaryMuscles': ['forearms'],
        'equipment': 'bodyweight',
        'movementType': 'compound',
        'difficulty': 3,
        'isUnilateral': false,
        'boneDensityScore': 45,
      },
      {
        'id': 'ab_wheel_rollout',
        'name': 'Ab Wheel Rollout',
        'primaryMuscles': ['core'],
        'secondaryMuscles': ['shoulders', 'latissimus'],
        'equipment': 'bodyweight',
        'movementType': 'compound',
        'difficulty': 4,
        'isUnilateral': false,
        'boneDensityScore': 50,
      },
    ];

    for (final exercise in exercises) {
      try {
        await _firestore
            .collection('exercises')
            .doc(exercise['id'] as String)
            .set(exercise);
      } catch (e) {
        debugPrint('seedExercises error seeding ${exercise['id']}: $e');
      }
    }
  }
}
