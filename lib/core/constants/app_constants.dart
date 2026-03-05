class AppConstants {
  // App info
  static const String appName = 'RunForge';
  static const String appVersion = '1.0.0';

  // Default goal
  static const int default10kGoalSeconds = 3600; // 60 minutes

  // Training defaults
  static const int defaultStrengthFrequency = 3; // sessions per week
  static const int defaultRunFrequency = 2; // sessions per week

  // Workout constraints
  static const int minStrengthFrequency = 3;
  static const int maxStrengthFrequency = 5;
  static const int minRunFrequency = 2;
  static const int maxRunFrequency = 3;

  // Duration estimates
  static const int avgRepDurationSeconds = 4;
  static const int defaultRestSeconds = 60;
  static const int maxWorkoutDurationMinutes = 35;

  // Muscle groups
  static const List<String> muscleGroups = [
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'core',
    'quadriceps',
    'hamstrings',
    'glutes',
    'calves',
  ];

  // Equipment types
  static const List<String> equipmentTypes = [
    'barbell',
    'dumbbell',
    'cable',
    'bodyweight',
    'kettlebell',
    'machine',
  ];
}
