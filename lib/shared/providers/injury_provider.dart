import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/injury_risk_assessment.dart';
import '../../data/models/progress_snapshot.dart';
import '../../data/services/injury_service.dart';
import '../../logic/injury_risk_calculator.dart';
import 'auth_provider.dart';
import 'workout_provider.dart';
import 'progress_provider.dart';

final injuryServiceProvider = Provider<InjuryService>((ref) => InjuryService());

final injuryRiskProvider = FutureProvider<InjuryRiskAssessment?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  // Try to get cached assessment first
  final cached = await ref.read(injuryServiceProvider).getLatestAssessment(userId);
  if (cached != null) {
    final age = DateTime.now().difference(cached.assessmentDate).inHours;
    if (age < 24) return cached; // Use cached if less than 24h old
  }

  // Compute fresh assessment
  final workouts = await ref.read(workoutServiceProvider).getRecentWorkouts(userId, limit: 30);
  final snapshots = await ref.read(progressServiceProvider).getLatestSnapshot(userId);
  final snapshotList = snapshots != null ? [snapshots] : <ProgressSnapshot>[];

  final calculator = InjuryRiskCalculator(
    recentWorkouts: workouts,
    recentSnapshots: snapshotList,
    muscleRecoveryStatus: {},
  );

  final assessment = calculator.calculate(userId: userId);

  // Save to Firestore
  await ref.read(injuryServiceProvider).saveAssessment(assessment);

  return assessment;
});
