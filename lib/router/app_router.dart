import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/app_shell.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/calendar/calendar_page.dart';
import '../features/progress/progress_page.dart';
import '../features/workout/workout_detail_page.dart';
import '../features/workout/workout_edit_page.dart';
import '../features/workout/active_workout_page.dart';
import '../features/workout/workout_complete_page.dart';
import '../features/exercise/exercise_detail_page.dart';
import '../features/injury_prevention/injury_prevention_page.dart';
import '../features/goals/goals_page.dart';
import '../features/settings/settings_page.dart';
import '../features/settings/profile_edit_page.dart';
import '../features/settings/training_preferences_page.dart';
import '../features/settings/goal_settings_page.dart';
import '../features/settings/exercise_types_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/calendar', builder: (context, state) => const CalendarPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/progress', builder: (context, state) => const ProgressPage()),
        ]),
      ],
    ),
    GoRoute(path: '/workout/:id', builder: (context, state) {
      return WorkoutDetailPage(workoutId: state.pathParameters['id']!);
    }),
    GoRoute(path: '/workout/:id/edit', builder: (context, state) {
      return WorkoutEditPage(workoutId: state.pathParameters['id']!);
    }),
    GoRoute(path: '/workout/:id/active', builder: (context, state) {
      return ActiveWorkoutPage(workoutId: state.pathParameters['id']!);
    }),
    GoRoute(path: '/workout/:id/complete', builder: (context, state) {
      return WorkoutCompletePage(workoutId: state.pathParameters['id']!);
    }),
    GoRoute(path: '/exercise/:id', builder: (context, state) {
      return ExerciseDetailPage(exerciseId: state.pathParameters['id']!);
    }),
    GoRoute(path: '/injury', builder: (context, state) => const InjuryPreventionPage()),
    GoRoute(path: '/goals', builder: (context, state) => const GoalsPage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(path: '/settings/profile', builder: (context, state) => const ProfileEditPage()),
    GoRoute(path: '/settings/preferences', builder: (context, state) => const TrainingPreferencesPage()),
    GoRoute(path: '/settings/goals', builder: (context, state) => const GoalSettingsPage()),
    GoRoute(path: '/settings/exercises', builder: (context, state) => const ExerciseTypesPage()),
  ],
);
