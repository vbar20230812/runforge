import '../data/models/user_profile.dart';
import '../data/models/training_goal.dart';
import '../data/models/workout.dart';
import '../data/models/workout_exercise.dart';
import '../data/models/weekly_plan.dart';
import '../data/models/exercise_baseline.dart';
import '../data/services/workout_service.dart';
import '../data/services/plan_service.dart';
import '../data/services/baseline_service.dart';
import '../core/constants/app_constants.dart';
import 'workout_generator.dart';

class PlanGenerator {
  final WorkoutGenerator workoutGenerator;
  final WorkoutService workoutService;
  final PlanService planService;
  final BaselineService baselineService;
  final UserProfile user;
  final TrainingGoal? goal;

  PlanGenerator({
    required this.workoutGenerator,
    required this.workoutService,
    required this.planService,
    required this.baselineService,
    required this.user,
    this.goal,
  });

  /// Generate a full weekly plan and save to Firestore.
  /// Workouts are scheduled from today onward (never in the past).
  Future<WeeklyPlan> generateWeek({
    required int weekNumber,
    required int year,
    required DateTime weekStart,
    List<String>? previouslyUsedExerciseIds,
  }) async {
    final phase = AppConstants.getPhaseForWeek(weekNumber);
    final workouts = <Workout>[];
    final allExercises = <List<WorkoutExercise>>[];
    final usedIds = previouslyUsedExerciseIds ?? <String>[];

    // Fetch baselines for weight suggestions
    final baselineList = await baselineService.getAllBaselines(user.id);
    final baselineMap = <String, ExerciseBaseline>{};
    for (final b in baselineList) {
      baselineMap[b.exerciseId] = b;
    }
    workoutGenerator.baselines = Map.unmodifiable(baselineMap);

    // Today — never schedule in the past
    final today = _dateOnly(DateTime.now());

    // Generate strength workouts
    for (var i = 0; i < user.strengthFrequency; i++) {
      final type = _getStrengthType(i, user.strengthFrequency);
      final date = _getNextDate(today, AppConstants.defaultStrengthDays, i);

      final result = workoutGenerator.generateStrengthWorkout(
        type: type,
        scheduledDate: date,
        weekNumber: weekNumber,
        sessionIndex: i,
        previouslyUsedIds: usedIds,
      );

      workouts.add(result.workout);
      allExercises.add(result.exercises);
      usedIds.addAll(
          result.exercises.where((e) => e.exerciseType == 'strength').map((e) => e.exerciseId));
    }

    // Generate running workouts
    for (var i = 0; i < user.runFrequency; i++) {
      final runType = _getRunType(i, phase);
      final date = _getNextDate(today, AppConstants.defaultRunDays, i);
      final workout = Workout(
        id: '',
        userId: user.id,
        scheduledDate: date,
        workoutType: 'run_$runType',
        estimatedDurationMin: _estimateRunDuration(runType),
        createdAt: DateTime.now(),
      );

      workouts.add(workout);
      allExercises.add([
        WorkoutExercise(
          id: '',
          exerciseId: 'run_${runType}_$i',
          order: 0,
          sets: 1,
          repsPerSet: 1,
          restSeconds: 0,
          primaryMusclesTargeted: ['legs', 'cardiovascular'],
          estimatedLoadScore: 50,
        ),
      ]);
    }

    // Sort workouts by scheduled date
    final indexed = List.generate(workouts.length, (i) => i);
    indexed.sort((a, b) => workouts[a].scheduledDate.compareTo(workouts[b].scheduledDate));

    final sortedWorkouts = indexed.map((i) => workouts[i]).toList();
    final sortedExercises = indexed.map((i) => allExercises[i]).toList();

    // Save all workouts with exercises
    final planId = await planService.createWeeklyPlan(WeeklyPlan(
      id: '',
      userId: user.id,
      weekNumber: weekNumber,
      year: year,
      phase: phase,
      mesocycle:
          ((weekNumber - 1) ~/ AppConstants.mesocycleLength) + 1,
      startDate: weekStart,
      endDate: weekStart.add(const Duration(days: 6)),
      workoutIds: [],
      createdAt: DateTime.now(),
    ));

    final workoutIds = <String>[];
    for (var i = 0; i < sortedWorkouts.length; i++) {
      final workoutWithPlan = Workout(
        id: sortedWorkouts[i].id,
        userId: sortedWorkouts[i].userId,
        weeklyPlanId: planId,
        scheduledDate: sortedWorkouts[i].scheduledDate,
        workoutType: sortedWorkouts[i].workoutType,
        estimatedDurationMin: sortedWorkouts[i].estimatedDurationMin,
        createdAt: sortedWorkouts[i].createdAt,
      );
      final workoutId = await workoutService.createWorkoutWithExercises(
        workoutWithPlan,
        sortedExercises[i],
      );
      workoutIds.add(workoutId);
    }

    // Update plan with workout IDs
    await planService.updateWeeklyPlan(planId, {'workoutIds': workoutIds});

    return WeeklyPlan(
      id: planId,
      userId: user.id,
      weekNumber: weekNumber,
      year: year,
      phase: phase,
      mesocycle:
          ((weekNumber - 1) ~/ AppConstants.mesocycleLength) + 1,
      startDate: weekStart,
      endDate: weekStart.add(const Duration(days: 6)),
      workoutIds: workoutIds,
      createdAt: DateTime.now(),
    );
  }

  String _getStrengthType(int index, int frequency) {
    if (frequency <= 3) {
      return ['upper', 'lower', 'upper'][index % 3];
    } else {
      return ['upper', 'lower', 'upper', 'lower', 'full'][index % 5];
    }
  }

  String _getRunType(int index, String phase) {
    final runTypesByPhase = {
      'base': ['easy', 'easy', 'long'],
      'build': ['easy', 'tempo', 'long'],
      'peak': ['tempo', 'interval', 'long'],
      'recover': ['easy', 'easy', 'easy'],
    };
    final types = runTypesByPhase[phase] ?? ['easy', 'easy'];
    return types[index % types.length];
  }

  /// Find the next available date starting from [afterDate].
  /// Iterates through [targetDays] cycling as needed.
  DateTime _getNextDate(DateTime afterDate, List<int> targetDays, int index) {
    final targetDay = targetDays[index % targetDays.length];
    // Find the next occurrence of targetDay on or after afterDate
    var candidate = afterDate;
    while (candidate.weekday != targetDay) {
      candidate = candidate.add(const Duration(days: 1));
    }
    // If we need a second/third occurrence of the same day, add weeks
    final weekOffset = index ~/ targetDays.length;
    return candidate.add(Duration(days: 7 * weekOffset));
  }

  int _estimateRunDuration(String runType) {
    switch (runType) {
      case 'easy':
        return 30;
      case 'tempo':
        return 35;
      case 'interval':
        return 40;
      case 'long':
        return 50;
      default:
        return 30;
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
