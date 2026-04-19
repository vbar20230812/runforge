class AppConstants {
  // App info
  static const String appName = 'RunForge';
  static const String appVersion = '1.0.0';

  // Default goal
  static const int default10kGoalSeconds = 3600; // 60 minutes

  // Training defaults
  static const int defaultStrengthFrequency = 3;
  static const int defaultRunFrequency = 2;

  // Workout constraints
  static const int minStrengthFrequency = 3;
  static const int maxStrengthFrequency = 5;
  static const int minRunFrequency = 2;
  static const int maxRunFrequency = 3;

  // Duration estimates
  static const int avgRepDurationSeconds = 4;
  static const int defaultRestSeconds = 60;
  static const int maxWorkoutDurationMinutes = 60;

  // Superset configuration
  static const int minSupersetsPerWorkout = 4;
  static const int maxSupersetsPerWorkout = 8;
  static const int easySupersetCount = 3; // first 1-3 are easier
  static const int hardSupersetCount = 2; // last 1-2 are harder

  // Difficulty tiers
  static const int easyDifficultyMax = 2; // difficulty <= 2 for easy supersets
  static const int hardDifficultyMin = 3; // difficulty >= 3 for hard supersets

  // Rep ranges per difficulty tier
  static const int easyMinReps = 12;
  static const int easyMaxReps = 15;
  static const int hardMinReps = 6;
  static const int hardMaxReps = 8;

  // Sets per difficulty tier
  static const int easySets = 3;
  static const int hardSets = 4;

  // Cardio burst between supersets
  static const int cardioBurstMinSeconds = 30;
  static const int cardioBurstMaxSeconds = 60;
  static const List<String> cardioBurstExercises = [
    'cardio_jump_rope',
    'cardio_high_knees',
    'cardio_burpees',
    'cardio_jumping_jacks',
    'cardio_mountain_climbers',
    'cardio_box_step_ups',
  ];

  // Baseline smoothing factor (EMA: newBaseline = (1-a)*old + a*session)
  static const double baselineSmoothingFactor = 0.3;

  // Muscle groups
  static const List<String> muscleGroups = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'core', 'quadriceps', 'hamstrings', 'glutes', 'calves',
  ];

  // Equipment types
  static const List<String> equipmentTypes = [
    'barbell', 'dumbbell', 'cable machine', 'bodyweight', 'kettlebell', 'machine',
  ];

  // Antagonist pairs for superset grouping
  static const Map<String, String> antagonistPairs = {
    'chest': 'back',
    'back': 'chest',
    'quadriceps': 'hamstrings',
    'hamstrings': 'quadriceps',
    'biceps': 'triceps',
    'triceps': 'biceps',
  };

  // Upper body muscles
  static const List<String> upperBodyMuscles = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
  ];

  // Lower body muscles
  static const List<String> lowerBodyMuscles = [
    'quadriceps', 'hamstrings', 'glutes', 'calves',
  ];

  // Run workout types
  static const List<String> runWorkoutTypes = [
    'run_easy', 'run_tempo', 'run_interval', 'run_long',
  ];

  // Strength workout types
  static const List<String> strengthWorkoutTypes = [
    'strength_upper', 'strength_lower', 'strength_full',
  ];

  // Periodization phases
  static const List<String> periodizationPhases = ['base', 'build', 'peak', 'recover'];

  // ACWR thresholds
  static const double acwrSafeLow = 0.8;
  static const double acwrSafeHigh = 1.3;
  static const double acwrDanger = 1.5;

  // Bone density
  static const int boneDensityHighThreshold = 70;

  // Superset rest (between paired exercises)
  static const int defaultSupersetRestSeconds = 60;
  // Rest between sets of same exercise
  static const int defaultSetRestSeconds = 90;

  // Mesocycle length (weeks)
  static const int mesocycleLength = 4;

  // Periodization schedule (week within mesocycle -> phase)
  static String getPhaseForWeek(int weekNumber) {
    final mesoWeek = ((weekNumber - 1) % mesocycleLength) + 1;
    if (mesoWeek <= 2) return 'base';
    if (mesoWeek == 3) return 'build';
    return 'peak'; // week 4 is peak, then next mesocycle starts with recover logic
  }

  // Default strength days (Mon=1, Wed=3, Fri=5)
  static const List<int> defaultStrengthDays = [1, 3, 5];
  // Default run days (Tue=2, Thu=4)
  static const List<int> defaultRunDays = [2, 4];
}
