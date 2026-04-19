import '../data/models/exercise.dart';
import '../data/models/workout.dart';
import '../data/models/workout_exercise.dart';
import '../data/models/user_profile.dart';
import '../data/models/training_goal.dart';
import '../core/constants/app_constants.dart';

class WorkoutGenerator {
  final List<Exercise> exerciseCatalog;
  final UserProfile user;
  final TrainingGoal? goal;

  WorkoutGenerator({
    required this.exerciseCatalog,
    required this.user,
    this.goal,
  });

  /// Generate a strength workout with superset pairing.
  /// Returns a tuple of (Workout, List<WorkoutExercise>).
  ({Workout workout, List<WorkoutExercise> exercises}) generateStrengthWorkout({
    required String type, // 'upper', 'lower', 'full'
    required DateTime scheduledDate,
    required int weekNumber,
    required int sessionIndex,
    List<String>? previouslyUsedIds,
  }) {
    final usedIds = previouslyUsedIds ?? <String>[];

    // Filter exercises by user's available equipment
    final available = exerciseCatalog
        .where((e) =>
            user.availableEquipment.contains(e.equipment) ||
            e.equipment == 'bodyweight')
        .toList();

    // Filter by workout type (upper/lower/full)
    final targetMuscles = type == 'upper'
        ? AppConstants.upperBodyMuscles
        : type == 'lower'
            ? AppConstants.lowerBodyMuscles
            : AppConstants.muscleGroups;

    final filtered = available
        .where((e) => e.primaryMuscles.any((m) => targetMuscles.contains(m)))
        .toList();

    // Select exercises using week-based rotation to avoid repeats
    final rotationOffset = (weekNumber * 7 + sessionIndex * 13) % 20;
    final selected = _selectExercises(filtered, usedIds, rotationOffset, type);

    // Create superset pairs
    final workoutExercises = _createSupersets(selected, weekNumber);

    // Calculate estimated duration
    final duration = _estimateDuration(workoutExercises);

    // If duration exceeds max, trim exercises
    var finalExercises = workoutExercises;
    if (duration > AppConstants.maxWorkoutDurationMinutes) {
      finalExercises =
          _trimToTime(workoutExercises, AppConstants.maxWorkoutDurationMinutes);
    }

    final workout = Workout(
      id: '',
      userId: user.id,
      scheduledDate: scheduledDate,
      workoutType: 'strength_$type',
      estimatedDurationMin: _estimateDuration(finalExercises),
      createdAt: DateTime.now(),
    );

    return (workout: workout, exercises: finalExercises);
  }

  /// Select exercises avoiding previously used IDs, with rotation.
  List<Exercise> _selectExercises(
    List<Exercise> available,
    List<String> usedIds,
    int rotationOffset,
    String type,
  ) {
    // Group available exercises by primary muscle
    final byMuscle = <String, List<Exercise>>{};
    for (final e in available) {
      for (final m in e.primaryMuscles) {
        if (targetMusclesForType(type).contains(m)) {
          byMuscle.putIfAbsent(m, () => []).add(e);
        }
      }
    }

    // For each muscle group, pick one exercise (rotating by offset)
    final selected = <Exercise>[];
    final selectedIds = <String>{};

    // Priority muscles: pick at least one compound for each major group
    final priorityMuscles = type == 'upper'
        ? ['chest', 'back', 'shoulders']
        : type == 'lower'
            ? ['quadriceps', 'hamstrings', 'glutes']
            : ['chest', 'back', 'quadriceps', 'hamstrings'];

    for (final muscle in priorityMuscles) {
      final candidates = (byMuscle[muscle] ?? [])
          .where(
              (e) => !usedIds.contains(e.id) && !selectedIds.contains(e.id))
          .toList();
      if (candidates.isEmpty) continue;

      final index = rotationOffset % candidates.length;
      final chosen = candidates[index];
      selected.add(chosen);
      selectedIds.add(chosen.id);
    }

    // Fill remaining slots with antagonist pairs
    final pairMuscles = type == 'upper'
        ? ['biceps', 'triceps']
        : type == 'lower'
            ? ['calves']
            : ['biceps', 'triceps', 'calves', 'core'];

    for (final muscle in pairMuscles) {
      if (selected.length >= 7) break;
      final candidates = (byMuscle[muscle] ?? [])
          .where(
              (e) => !usedIds.contains(e.id) && !selectedIds.contains(e.id))
          .toList();
      if (candidates.isEmpty) continue;

      final index = (rotationOffset + selected.length) % candidates.length;
      final chosen = candidates[index];
      selected.add(chosen);
      selectedIds.add(chosen.id);
    }

    return selected;
  }

  List<String> targetMusclesForType(String type) {
    return type == 'upper'
        ? AppConstants.upperBodyMuscles
        : type == 'lower'
            ? AppConstants.lowerBodyMuscles
            : AppConstants.muscleGroups;
  }

  /// Create superset pairs from selected exercises.
  List<WorkoutExercise> _createSupersets(
      List<Exercise> selected, int weekNumber) {
    final result = <WorkoutExercise>[];
    final paired = <String>{};

    // Determine sets/reps from periodization
    final phase = AppConstants.getPhaseForWeek(weekNumber);
    final (sets, reps) = _setsRepsForPhase(phase);

    var order = 0;
    var pairIndex = 0;

    // Try to pair antagonist muscles
    for (int i = 0; i < selected.length; i++) {
      if (paired.contains(selected[i].id)) continue;

      final exercise = selected[i];
      String? pairId;

      // Find an antagonist partner
      for (final muscle in exercise.primaryMuscles) {
        final antagonist = AppConstants.antagonistPairs[muscle];
        if (antagonist == null) continue;

        for (int j = i + 1; j < selected.length; j++) {
          if (paired.contains(selected[j].id)) continue;
          if (selected[j].primaryMuscles.contains(antagonist)) {
            pairId = 'superset_$pairIndex';
            paired.add(selected[j].id);

            // Add partner exercise
            result.add(WorkoutExercise(
              id: '',
              exerciseId: selected[j].id,
              order: order++,
              supersetPairId: pairId,
              sets: sets,
              repsPerSet: reps,
              restSeconds: AppConstants.defaultSupersetRestSeconds,
              primaryMusclesTargeted: selected[j].primaryMuscles,
              estimatedLoadScore:
                  _calculateLoadScore(selected[j], sets, reps),
            ));
            pairIndex++;
            break;
          }
        }
        if (pairId != null) break;
      }

      // Add the exercise itself
      result.add(WorkoutExercise(
        id: '',
        exerciseId: exercise.id,
        order: order++,
        supersetPairId: pairId,
        sets: sets,
        repsPerSet: reps,
        restSeconds: pairId != null
            ? AppConstants.defaultSupersetRestSeconds
            : AppConstants.defaultSetRestSeconds,
        primaryMusclesTargeted: exercise.primaryMuscles,
        estimatedLoadScore: _calculateLoadScore(exercise, sets, reps),
      ));

      paired.add(exercise.id);
    }

    return result;
  }

  (int sets, int reps) _setsRepsForPhase(String phase) {
    switch (phase) {
      case 'base':
        return (3, 12);
      case 'build':
        return (4, 10);
      case 'peak':
        return (4, 8);
      default:
        return (3, 12);
    }
  }

  int _calculateLoadScore(Exercise exercise, int sets, int reps) {
    // Load score: difficulty * sets * reps / 10, scaled by bone density
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
      final setTime = ex.repsPerSet * AppConstants.avgRepDurationSeconds;
      totalSeconds += ex.sets * (setTime + ex.restSeconds);
    }
    // Supersets share rest time, so reduce by ~30%
    final hasSupersets = exercises.any((e) => e.supersetPairId != null);
    if (hasSupersets) totalSeconds = (totalSeconds * 0.7).round();
    return (totalSeconds / 60).round();
  }

  List<WorkoutExercise> _trimToTime(
      List<WorkoutExercise> exercises, int maxMinutes) {
    var totalSeconds = 0;
    final result = <WorkoutExercise>[];
    final maxSeconds = maxMinutes * 60;

    for (final ex in exercises) {
      final setTime = ex.repsPerSet * AppConstants.avgRepDurationSeconds;
      final exSeconds = ex.sets * (setTime + ex.restSeconds);
      if (totalSeconds + exSeconds > maxSeconds) break;
      totalSeconds += exSeconds;
      result.add(ex);
    }
    return result;
  }
}
