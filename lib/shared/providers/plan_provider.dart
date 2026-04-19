import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/services/plan_service.dart';
import 'auth_provider.dart';

final planServiceProvider = Provider<PlanService>((ref) => PlanService());

final currentWeekPlanProvider = StreamProvider<WeeklyPlan?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(planServiceProvider).currentWeekPlanStream(userId);
});
