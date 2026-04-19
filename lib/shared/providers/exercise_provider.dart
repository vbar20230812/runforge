import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exercise.dart';
import '../../data/services/exercise_service.dart';

final exerciseServiceProvider = Provider<ExerciseService>((ref) => ExerciseService());

final exerciseCatalogProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseServiceProvider).getAllExercises();
});

final exercisesByMuscleProvider = FutureProvider.family<List<Exercise>, String>((ref, muscle) {
  return ref.watch(exerciseServiceProvider).getExercisesByMuscleGroup(muscle);
});
