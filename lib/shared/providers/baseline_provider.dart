import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exercise_baseline.dart';
import '../../data/services/baseline_service.dart';

final baselineServiceProvider = Provider<BaselineService>((ref) => BaselineService());

final userBaselinesProvider = FutureProvider.family<List<ExerciseBaseline>, String>((ref, userId) {
  return ref.watch(baselineServiceProvider).getAllBaselines(userId);
});
