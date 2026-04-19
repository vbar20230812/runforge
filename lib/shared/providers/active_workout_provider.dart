import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/services/workout_service.dart';
import '../../data/services/baseline_service.dart';

class SetLog {
  final int reps;
  final double? weight;
  final bool completed;
  SetLog({required this.reps, this.weight, this.completed = false});
  SetLog copyWith({int? reps, double? weight, bool? completed}) =>
      SetLog(reps: reps ?? this.reps, weight: weight ?? this.weight, completed: completed ?? this.completed);
}

/// Group of exercises (solo, superset pair, or cardio burst)
class ExerciseGroup {
  final List<WorkoutExercise> exercises;
  final bool isCardioBurst;
  ExerciseGroup({required this.exercises, this.isCardioBurst = false});
  bool get isSuperset => !isCardioBurst && exercises.length > 1;
}

class ActiveWorkoutState {
  final Workout workout;
  final List<ExerciseGroup> groups;
  final int currentGroupIndex;
  final int currentSet;
  final Map<int, List<SetLog>> setLogs; // exercise order -> list of set logs
  final DateTime startedAt;
  final bool isTimerRunning;
  final int timerSeconds;

  ActiveWorkoutState({
    required this.workout,
    required this.groups,
    this.currentGroupIndex = 0,
    this.currentSet = 0,
    this.setLogs = const {},
    required this.startedAt,
    this.isTimerRunning = false,
    this.timerSeconds = 0,
  });

  ActiveWorkoutState copyWith({
    Workout? workout,
    List<ExerciseGroup>? groups,
    int? currentGroupIndex,
    int? currentSet,
    Map<int, List<SetLog>>? setLogs,
    DateTime? startedAt,
    bool? isTimerRunning,
    int? timerSeconds,
  }) {
    return ActiveWorkoutState(
      workout: workout ?? this.workout,
      groups: groups ?? this.groups,
      currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
      currentSet: currentSet ?? this.currentSet,
      setLogs: setLogs ?? this.setLogs,
      startedAt: startedAt ?? this.startedAt,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      timerSeconds: timerSeconds ?? this.timerSeconds,
    );
  }

  ExerciseGroup? get currentGroup =>
      currentGroupIndex < groups.length ? groups[currentGroupIndex] : null;

  bool get isLastGroup => currentGroupIndex >= groups.length - 1;
  int get elapsedSeconds => DateTime.now().difference(startedAt).inSeconds;
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final WorkoutService _workoutService;
  final BaselineService _baselineService;

  ActiveWorkoutNotifier(this._workoutService, this._baselineService) : super(null);

  void startWorkout(Workout workout, List<WorkoutExercise> exercises) {
    // Sort by order and group: preserve interleaved cardio bursts
    final sorted = List<WorkoutExercise>.from(exercises)
      ..sort((a, b) => a.order.compareTo(b.order));

    final groups = <ExerciseGroup>[];
    final supersetMap = <String, List<WorkoutExercise>>{};
    final processed = <String>{};

    // First pass: group superset pairs
    for (final ex in sorted) {
      if (ex.supersetPairId != null && !processed.contains(ex.supersetPairId)) {
        final pair = sorted.where((e) => e.supersetPairId == ex.supersetPairId).toList();
        if (pair.length >= 2) {
          supersetMap[ex.supersetPairId!] = pair;
          processed.add(ex.supersetPairId!);
        }
      }
    }

    // Second pass: build groups in order
    final seen = <String>{};
    for (final ex in sorted) {
      if (seen.contains(ex.exerciseId) && ex.supersetPairId == null) continue;

      if (ex.exerciseType == 'cardio_burst') {
        groups.add(ExerciseGroup(exercises: [ex], isCardioBurst: true));
        seen.add(ex.exerciseId);
      } else if (ex.supersetPairId != null && !seen.contains(ex.supersetPairId)) {
        final pair = supersetMap[ex.supersetPairId] ?? [ex];
        groups.add(ExerciseGroup(exercises: pair));
        seen.add(ex.supersetPairId!);
        for (final p in pair) {
          seen.add(p.exerciseId);
        }
      } else if (ex.supersetPairId == null) {
        groups.add(ExerciseGroup(exercises: [ex]));
        seen.add(ex.exerciseId);
      }
    }

    // Initialize set logs (only for strength exercises)
    final setLogs = <int, List<SetLog>>{};
    for (final ex in exercises) {
      if (ex.exerciseType != 'cardio_burst') {
        setLogs[ex.order] = List.generate(
          ex.sets,
          (_) => SetLog(reps: ex.repsPerSet, weight: ex.weightKg),
        );
      }
    }

    state = ActiveWorkoutState(
      workout: workout,
      groups: groups,
      setLogs: setLogs,
      startedAt: DateTime.now(),
    );
  }

  void completeSet(int exerciseOrder, int setIndex, {int? reps, double? weight}) {
    if (state == null) return;
    final logs = Map<int, List<SetLog>>.from(state!.setLogs);
    final exerciseLogs = logs[exerciseOrder]?.toList() ?? [];
    if (setIndex < exerciseLogs.length) {
      exerciseLogs[setIndex] = exerciseLogs[setIndex].copyWith(
        reps: reps ?? exerciseLogs[setIndex].reps,
        weight: weight ?? exerciseLogs[setIndex].weight,
        completed: true,
      );
      logs[exerciseOrder] = exerciseLogs;
    }

    // Start rest timer
    state = state!.copyWith(
      setLogs: logs,
      isTimerRunning: true,
      timerSeconds: 60,
    );
  }

  /// Start the cardio burst countdown
  void startCardioBurst(int durationSeconds) {
    if (state == null) return;
    state = state!.copyWith(
      isTimerRunning: true,
      timerSeconds: durationSeconds,
    );
  }

  void nextGroup() {
    if (state == null) return;
    if (state!.isLastGroup) return;
    state = state!.copyWith(
      currentGroupIndex: state!.currentGroupIndex + 1,
      currentSet: 0,
      isTimerRunning: false,
    );
  }

  void previousGroup() {
    if (state == null || state!.currentGroupIndex == 0) return;
    state = state!.copyWith(
      currentGroupIndex: state!.currentGroupIndex - 1,
      currentSet: 0,
      isTimerRunning: false,
    );
  }

  void tickTimer() {
    if (state == null || !state!.isTimerRunning) return;
    if (state!.timerSeconds <= 0) {
      state = state!.copyWith(isTimerRunning: false, timerSeconds: 0);
      return;
    }
    state = state!.copyWith(timerSeconds: state!.timerSeconds - 1);
  }

  Future<String?> completeWorkout({String? notes}) async {
    if (state == null) return null;
    try {
      final duration = state!.elapsedSeconds ~/ 60;
      final workoutId = state!.workout.id;
      final setLogs = state!.setLogs;
      final userId = state!.workout.userId;

      // Mark workout complete
      await _workoutService.completeWorkout(
        workoutId,
        actualDurationMin: duration,
        userNotes: notes,
      );

      // Persist actual set data and update baselines
      for (final entry in setLogs.entries) {
        final order = entry.key;
        final logs = entry.value;
        final completedLogs = logs.where((l) => l.completed).toList();
        if (completedLogs.isEmpty) continue;

        // Find the exercise for this order
        final exercise = state!.groups
            .expand((g) => g.exercises)
            .where((e) => e.order == order)
            .firstOrNull;
        if (exercise == null) continue;

        final actualReps = completedLogs.map((l) => l.reps).toList();
        final actualWeight = completedLogs.map((l) => l.weight ?? 0.0).toList();

        // Write actual data to Firestore
        await _workoutService.updateExerciseActuals(
          workoutId,
          exercise.id,
          actualSets: completedLogs.length,
          actualReps: actualReps,
          actualWeight: actualWeight,
        );

        // Update baseline
        final avgWeight = actualWeight.isNotEmpty
            ? actualWeight.reduce((a, b) => a + b) / actualWeight.length
            : 0.0;
        final avgReps = actualReps.isNotEmpty
            ? (actualReps.reduce((a, b) => a + b) / actualReps.length).round()
            : 0;
        if (avgWeight > 0) {
          await _baselineService.updateBaselineFromSession(
            userId, exercise.exerciseId, avgWeight, avgReps);
        }
      }

      state = null;
      return workoutId;
    } catch (e) {
      debugPrint('completeWorkout error: $e');
      return null;
    }
  }

  void cancelWorkout() {
    state = null;
  }
}

final activeWorkoutProvider = StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>((ref) {
  return ActiveWorkoutNotifier(WorkoutService(), BaselineService());
});
