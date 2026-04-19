import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/services/workout_service.dart';

class SetLog {
  final int reps;
  final double? weight;
  final bool completed;
  SetLog({required this.reps, this.weight, this.completed = false});
  SetLog copyWith({int? reps, double? weight, bool? completed}) =>
      SetLog(reps: reps ?? this.reps, weight: weight ?? this.weight, completed: completed ?? this.completed);
}

/// Group of exercises (solo or superset pair)
class ExerciseGroup {
  final List<WorkoutExercise> exercises;
  ExerciseGroup({required this.exercises});
  bool get isSuperset => exercises.length > 1;
}

class ActiveWorkoutState {
  final Workout workout;
  final List<ExerciseGroup> groups;
  final int currentGroupIndex;
  final int currentSet;          // current set within the group
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

  ActiveWorkoutNotifier(this._workoutService) : super(null);

  void startWorkout(Workout workout, List<WorkoutExercise> exercises) {
    // Group exercises by superset pair ID
    final groups = <ExerciseGroup>[];
    final soloExercises = <WorkoutExercise>[];
    final supersetMap = <String, List<WorkoutExercise>>{};

    for (final ex in exercises) {
      if (ex.supersetPairId != null) {
        supersetMap.putIfAbsent(ex.supersetPairId!, () => []).add(ex);
      } else {
        soloExercises.add(ex);
      }
    }

    // Add superset groups first, then solo exercises
    for (final pair in supersetMap.values) {
      groups.add(ExerciseGroup(exercises: pair));
    }
    for (final ex in soloExercises) {
      groups.add(ExerciseGroup(exercises: [ex]));
    }

    // Initialize set logs
    final setLogs = <int, List<SetLog>>{};
    for (final ex in exercises) {
      setLogs[ex.order] = List.generate(
        ex.sets,
        (_) => SetLog(reps: ex.repsPerSet, weight: ex.weightKg),
      );
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
      timerSeconds: 60, // default rest
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
      await _workoutService.completeWorkout(
        state!.workout.id,
        actualDurationMin: duration,
        userNotes: notes,
      );
      final workoutId = state!.workout.id;
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
  return ActiveWorkoutNotifier(WorkoutService());
});
