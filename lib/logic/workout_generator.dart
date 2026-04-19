import 'dart:math';
import '../data/models/exercise.dart';
import '../data/models/workout.dart';
import '../data/models/workout_exercise.dart';
import '../data/models/user_profile.dart';
import '../data/models/exercise_baseline.dart';
import '../data/models/training_goal.dart';
import '../core/constants/app_constants.dart';

class WorkoutGenerator {
  final List<Exercise> exerciseCatalog;
  final UserProfile user;
  final TrainingGoal? goal;
  Map<String, ExerciseBaseline> baselines;

  WorkoutGenerator({
    required this.exerciseCatalog,
    required this.user,
    this.goal,
    this.baselines = const {},
  });

  /// Generate a strength workout with 4-8 supersets and cardio bursts.
  ({Workout workout, List<WorkoutExercise> exercises}) generateStrengthWorkout({
    required String type, // 'upper', 'lower', 'full'
    required DateTime scheduledDate,
    required int weekNumber,
    required int sessionIndex,
    List<String>? previouslyUsedIds,
  }) {
    final usedIds = <String>{...?previouslyUsedIds};
    final random = Random(weekNumber * 31 + sessionIndex * 17);

    // Filter by user equipment + workout type
    final available = exerciseCatalog
        .where((e) =>
            user.availableEquipment.contains(e.equipment) ||
            e.equipment == 'bodyweight')
        .where((e) => e.movementType != 'cardio')
        .toList();

    final targetMuscles = type == 'upper'
        ? AppConstants.upperBodyMuscles
        : type == 'lower'
            ? AppConstants.lowerBodyMuscles
            : AppConstants.muscleGroups;

    final filtered = available
        .where((e) => e.primaryMuscles.any((m) => targetMuscles.contains(m)))
        .toList();

    // Split into easy and hard pools
    final easyPool = filtered
        .where((e) =>
            e.movementType == 'isolation' && e.difficulty <= AppConstants.easyDifficultyMax)
        .toList();
    final hardPool = filtered
        .where((e) =>
            e.movementType == 'compound' && e.difficulty >= AppConstants.hardDifficultyMin)
        .toList();

    // Determine superset count
    final totalSupersets = AppConstants.minSupersetsPerWorkout +
        random.nextInt(AppConstants.maxSupersetsPerWorkout -
            AppConstants.minSupersetsPerWorkout +
            1);

    // Get antagonist pair rotations for this workout type
    final pairs = _getAntagonistPairsForType(type);
    final shuffledPairs = List<List<String>>.from(pairs)..shuffle(random);

    final allExercises = <WorkoutExercise>[];
    var order = 0;

    for (var i = 0; i < totalSupersets; i++) {
      final isEasy = i < AppConstants.easySupersetCount;
      final pool = isEasy ? easyPool : hardPool;
      final sets = isEasy ? AppConstants.easySets : AppConstants.hardSets;
      final reps = isEasy
          ? AppConstants.easyMinReps +
              random.nextInt(AppConstants.easyMaxReps - AppConstants.easyMinReps + 1)
          : AppConstants.hardMinReps +
              random.nextInt(AppConstants.hardMaxReps - AppConstants.hardMinReps + 1);
      final restSeconds =
          isEasy ? AppConstants.defaultSupersetRestSeconds : AppConstants.defaultSetRestSeconds;

      // Pick antagonist muscle pair (rotating)
      final musclePair = shuffledPairs[i % shuffledPairs.length];

      // Pick one exercise for each muscle in the pair
      final exerciseA = _pickExerciseForMuscle(
        pool, musclePair[0], usedIds, random, weekNumber + i * 7);
      final exerciseB = _pickExerciseForMuscle(
        pool, musclePair[1], usedIds, random, weekNumber + i * 13);

      if (exerciseA != null && exerciseB != null) {
        final pairId = 'superset_$i';
        final weightA = _getSuggestedWeight(exerciseA.id, reps);
        final weightB = _getSuggestedWeight(exerciseB.id, reps);

        allExercises.add(WorkoutExercise(
          id: '',
          exerciseId: exerciseA.id,
          order: order++,
          supersetPairId: pairId,
          sets: sets,
          repsPerSet: reps,
          weightKg: weightA,
          restSeconds: restSeconds,
          primaryMusclesTargeted: exerciseA.primaryMuscles,
          estimatedLoadScore: _calculateLoadScore(exerciseA, sets, reps),
        ));
        allExercises.add(WorkoutExercise(
          id: '',
          exerciseId: exerciseB.id,
          order: order++,
          supersetPairId: pairId,
          sets: sets,
          repsPerSet: reps,
          weightKg: weightB,
          restSeconds: restSeconds,
          primaryMusclesTargeted: exerciseB.primaryMuscles,
          estimatedLoadScore: _calculateLoadScore(exerciseB, sets, reps),
        ));

        usedIds.add(exerciseA.id);
        usedIds.add(exerciseB.id);
      } else if (exerciseA != null) {
        // Couldn't find a pair partner, add as solo
        allExercises.add(WorkoutExercise(
          id: '',
          exerciseId: exerciseA.id,
          order: order++,
          sets: sets,
          repsPerSet: reps,
          weightKg: _getSuggestedWeight(exerciseA.id, reps),
          restSeconds: restSeconds,
          primaryMusclesTargeted: exerciseA.primaryMuscles,
          estimatedLoadScore: _calculateLoadScore(exerciseA, sets, reps),
        ));
        usedIds.add(exerciseA.id);
      }

      // Insert cardio burst between supersets (not after the last one)
      if (i < totalSupersets - 1) {
        final cardioId = AppConstants.cardioBurstExercises[
            random.nextInt(AppConstants.cardioBurstExercises.length)];
        final duration = AppConstants.cardioBurstMinSeconds +
            random.nextInt(
                AppConstants.cardioBurstMaxSeconds - AppConstants.cardioBurstMinSeconds + 1);

        allExercises.add(WorkoutExercise(
          id: '',
          exerciseId: cardioId,
          order: order++,
          sets: 1,
          repsPerSet: 0,
          restSeconds: 0,
          primaryMusclesTargeted: ['cardiovascular'],
          estimatedLoadScore: 20,
          exerciseType: 'cardio_burst',
          durationSeconds: duration,
        ));
      }
    }

    final duration = _estimateDuration(allExercises);

    final workout = Workout(
      id: '',
      userId: user.id,
      scheduledDate: scheduledDate,
      workoutType: 'strength_$type',
      estimatedDurationMin: duration,
      createdAt: DateTime.now(),
    );

    return (workout: workout, exercises: allExercises);
  }

  /// Pick an exercise for a target muscle, preferring unused ones, with randomization.
  Exercise? _pickExerciseForMuscle(
    List<Exercise> pool,
    String targetMuscle,
    Set<String> usedIds,
    Random random,
    int seed,
  ) {
    // Prefer unused exercises
    var candidates = pool
        .where((e) => e.primaryMuscles.contains(targetMuscle) && !usedIds.contains(e.id))
        .toList();

    // Fallback: allow repeats if pool exhausted
    if (candidates.isEmpty) {
      candidates = pool
          .where((e) => e.primaryMuscles.contains(targetMuscle))
          .toList();
    }

    if (candidates.isEmpty) return null;

    // Shuffle deterministically and pick first
    final shuffled = List<Exercise>.from(candidates)
      ..shuffle(Random(seed + targetMuscle.hashCode));
    return shuffled.first;
  }

  /// Get antagonist muscle pairs appropriate for the workout type.
  List<List<String>> _getAntagonistPairsForType(String type) {
    if (type == 'upper') {
      return [
        ['chest', 'back'],
        ['biceps', 'triceps'],
        ['shoulders', 'back'],
        ['chest', 'back'],
      ];
    } else if (type == 'lower') {
      return [
        ['quadriceps', 'hamstrings'],
        ['glutes', 'quadriceps'],
        ['hamstrings', 'calves'],
        ['quadriceps', 'hamstrings'],
      ];
    } else {
      // Full body — mix upper and lower pairs
      return [
        ['chest', 'back'],
        ['quadriceps', 'hamstrings'],
        ['biceps', 'triceps'],
        ['glutes', 'shoulders'],
        ['chest', 'back'],
        ['quadriceps', 'hamstrings'],
      ];
    }
  }

  /// Get suggested weight from baseline if available.
  double? _getSuggestedWeight(String exerciseId, int targetReps) {
    final baseline = baselines[exerciseId];
    if (baseline == null) return null;
    // Use last week average if available, otherwise baseline
    return baseline.lastWeekAvgWeight ?? baseline.baselineWeightKg;
  }

  int _calculateLoadScore(Exercise exercise, int sets, int reps) {
    return (exercise.difficulty *
            sets *
            reps *
            exercise.boneDensityScore /
            100)
        .round()
        .clamp(0, 100);
  }

  int _estimateDuration(List<WorkoutExercise> exercises) {
    int totalSeconds = 0;
    for (final ex in exercises) {
      if (ex.exerciseType == 'cardio_burst') {
        totalSeconds += ex.durationSeconds ?? 30;
      } else {
        final setTime = ex.repsPerSet * AppConstants.avgRepDurationSeconds;
        totalSeconds += ex.sets * (setTime + ex.restSeconds);
      }
    }
    // Supersets share rest time, reduce by ~30%
    final hasSupersets = exercises.any((e) => e.supersetPairId != null);
    if (hasSupersets) totalSeconds = (totalSeconds * 0.7).round();
    return (totalSeconds / 60).round().clamp(1, 120);
  }
}
