import '../data/models/user_profile.dart';
import '../data/models/injury_risk_assessment.dart';
import '../data/models/progress_snapshot.dart';
import '../data/models/workout.dart';
import '../core/constants/app_constants.dart';

class Recommendation {
  final String type;     // 'deload', 'volume_adjust', 'exercise_swap', 'rest', 'taper'
  final String priority; // 'high', 'medium', 'low'
  final String message;
  final String? suggestedAction;

  Recommendation({
    required this.type,
    required this.priority,
    required this.message,
    this.suggestedAction,
  });
}

class RecommendationEngine {
  final UserProfile user;
  final InjuryRiskAssessment? injuryRisk;
  final List<ProgressSnapshot> recentProgress;
  final List<Workout> recentWorkouts;

  RecommendationEngine({
    required this.user,
    this.injuryRisk,
    required this.recentProgress,
    required this.recentWorkouts,
  });

  /// Generate personalized training recommendations.
  List<Recommendation> generate() {
    final recs = <Recommendation>[];

    // 1. Injury risk-based recommendations
    if (injuryRisk != null) {
      if (injuryRisk!.riskScore > 70) {
        recs.add(Recommendation(
          type: 'deload',
          priority: 'high',
          message: 'High injury risk detected. Schedule a deload week.',
          suggestedAction: 'reduce_volume_40',
        ));
      } else if (injuryRisk!.riskScore > 40) {
        recs.add(Recommendation(
          type: 'volume_adjust',
          priority: 'medium',
          message: 'Moderate injury risk. Reduce intensity by 10-15%.',
          suggestedAction: 'reduce_volume_15',
        ));
      }

      // Check for specific risk factors
      for (final factor in injuryRisk!.riskFactors) {
        if (factor.factor == 'no_rest_day') {
          recs.add(Recommendation(
            type: 'rest',
            priority: 'high',
            message: factor.message,
            suggestedAction: 'add_rest_day',
          ));
        }
      }
    }

    // 2. Deload week detection
    final now = DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    final weekNumber = ((now.difference(jan1).inDays + jan1.weekday) / 7).ceil();
    final mesoWeek = ((weekNumber - 1) % AppConstants.mesocycleLength) + 1;

    if (mesoWeek == AppConstants.mesocycleLength) {
      recs.add(Recommendation(
        type: 'deload',
        priority: 'medium',
        message: 'Deload week approaching. Next week should be reduced volume.',
        suggestedAction: 'next_week_deload',
      ));
    }

    // 3. Progress plateau detection
    if (recentProgress.length >= 6) {
      final recent = recentProgress.take(3).map((s) => s.progressScore ?? 50).reduce((a, b) => a + b) / 3;
      final older = recentProgress.skip(3).take(3).map((s) => s.progressScore ?? 50).reduce((a, b) => a + b) / 3;

      if (recent <= older) {
        recs.add(Recommendation(
          type: 'exercise_swap',
          priority: 'medium',
          message: 'Progress has plateaued. Consider changing your exercise selection.',
          suggestedAction: 'rotate_exercises',
        ));
      }
    }

    // 4. Fatigue-based adjustment
    final completedThisWeek = recentWorkouts.where((w) {
      if (w.completedAt == null) return false;
      final weekAgo = now.subtract(const Duration(days: 7));
      return w.completedAt!.isAfter(weekAgo);
    }).length;

    final plannedPerWeek = user.strengthFrequency + user.runFrequency;
    if (completedThisWeek > plannedPerWeek) {
      recs.add(Recommendation(
        type: 'volume_adjust',
        priority: 'low',
        message: 'You\'ve trained more than planned this week. Watch for fatigue accumulation.',
        suggestedAction: 'monitor_fatigue',
      ));
    }

    // Sort by priority
    const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
    recs.sort((a, b) => (priorityOrder[a.priority] ?? 2).compareTo(priorityOrder[b.priority] ?? 2));

    return recs;
  }
}
