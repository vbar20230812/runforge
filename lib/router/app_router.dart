import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/auth_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/calendar/calendar_page.dart';
import '../features/workout/workout_detail_page.dart';
import '../features/workout/workout_edit_page.dart';
import '../features/workout/active_workout_page.dart';
import '../features/exercise/exercise_detail_page.dart';
import '../features/progress/progress_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/profile_edit_page.dart';
import '../features/settings/training_preferences_page.dart';
import '../features/settings/goal_settings_page.dart';
import '../features/settings/exercise_types_page.dart';

final appRouter = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isGoingToLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }

    if (isLoggedIn && isGoingToLogin) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarPage(),
    ),
    GoRoute(
      path: '/workout/:id',
      builder: (context, state) {
        final workoutId = state.pathParameters['id']!;
        return WorkoutDetailPage(workoutId: workoutId);
      },
    ),
    GoRoute(
      path: '/workout/:id/edit',
      builder: (context, state) {
        final workoutId = state.pathParameters['id']!;
        return WorkoutEditPage(workoutId: workoutId);
      },
    ),
    GoRoute(
      path: '/workout/:id/active',
      builder: (context, state) {
        final workoutId = state.pathParameters['id']!;
        return ActiveWorkoutPage(workoutId: workoutId);
      },
    ),
    GoRoute(
      path: '/exercise/:id',
      builder: (context, state) {
        final exerciseId = state.pathParameters['id']!;
        return ExerciseDetailPage(exerciseId: exerciseId);
      },
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/settings/profile',
      builder: (context, state) => const ProfileEditPage(),
    ),
    GoRoute(
      path: '/settings/preferences',
      builder: (context, state) => const TrainingPreferencesPage(),
    ),
    GoRoute(
      path: '/settings/goals',
      builder: (context, state) => const GoalSettingsPage(),
    ),
    GoRoute(
      path: '/settings/exercises',
      builder: (context, state) => const ExerciseTypesPage(),
    ),
  ],
);
