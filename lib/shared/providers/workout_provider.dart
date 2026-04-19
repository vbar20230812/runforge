import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/services/workout_service.dart';
import 'auth_provider.dart';

final workoutServiceProvider = Provider<WorkoutService>((ref) => WorkoutService());

/// Date range parameter for workout queries
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          start.year == other.start.year &&
          start.month == other.start.month &&
          start.day == other.start.day &&
          end.year == other.end.year &&
          end.month == other.end.month &&
          end.day == other.end.day;

  @override
  int get hashCode => Object.hash(start.year, start.month, start.day, end.year, end.month, end.day);
}

final workoutListProvider = StreamProvider.family<List<Workout>, DateRange>((ref, range) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(workoutServiceProvider).getWorkoutsByDateRange(userId, range.start, range.end);
});

final workoutByIdProvider = StreamProvider.family<Workout?, String>((ref, workoutId) {
  return ref.watch(workoutServiceProvider).workoutStream(workoutId);
});

final workoutExercisesProvider = FutureProvider.family<List<WorkoutExercise>, String>((ref, workoutId) {
  return ref.watch(workoutServiceProvider).getWorkoutExercises(workoutId);
});
