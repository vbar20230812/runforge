import '../data/models/workout.dart';
import '../data/models/progress_snapshot.dart';
import '../data/models/injury_risk_assessment.dart';
import '../core/constants/app_constants.dart';

class InjuryRiskCalculator {
  final List<Workout> recentWorkouts; // last 4+ weeks
  final List<ProgressSnapshot> recentSnapshots;
  final Map<String, int> muscleRecoveryStatus; // muscle -> hours since last trained

  InjuryRiskCalculator({
    required this.recentWorkouts,
    required this.recentSnapshots,
    required this.muscleRecoveryStatus,
  });

  /// Calculate current injury risk assessment.
  InjuryRiskAssessment calculate({required String userId}) {
    final factors = <RiskFactor>[];

    // 1. Training Load Spike (ACWR)
    final acwr = _calculateACWR();
    if (acwr > AppConstants.acwrDanger) {
      factors.add(RiskFactor(
        factor: 'training_load_spike',
        severity: 'high',
        value: acwr,
        message: 'Training load spike detected (ACWR: ${acwr.toStringAsFixed(2)}). High injury risk.',
      ));
    } else if (acwr > AppConstants.acwrSafeHigh) {
      factors.add(RiskFactor(
        factor: 'training_load_spike',
        severity: 'medium',
        value: acwr,
        message: 'Training load above optimal (ACWR: ${acwr.toStringAsFixed(2)}). Monitor closely.',
      ));
    }

    // 2. Muscle Imbalance
    final imbalances = _detectMuscleImbalances();
    if (imbalances.isNotEmpty) {
      final severity = imbalances.length > 2 ? 'high' : 'medium';
      factors.add(RiskFactor(
        factor: 'muscle_imbalance',
        severity: severity,
        value: imbalances.map((e) => '${e.key}: ${e.value}').join(', '),
        message: 'Muscle imbalances detected: ${imbalances.map((e) => e.key).join(", ")}',
      ));
    }

    // 3. Recovery Score
    final recoveryScore = _calculateRecoveryScore();
    if (recoveryScore < 40) {
      factors.add(RiskFactor(
        factor: 'inadequate_recovery',
        severity: 'high',
        value: recoveryScore,
        message: 'Recovery score is critically low ($recoveryScore/100)',
      ));
    } else if (recoveryScore < 60) {
      factors.add(RiskFactor(
        factor: 'inadequate_recovery',
        severity: 'medium',
        value: recoveryScore,
        message: 'Recovery score is below optimal ($recoveryScore/100)',
      ));
    }

    // 4. Rest Days
    final daysSinceRest = _daysSinceLastRestDay();
    if (daysSinceRest > 10) {
      factors.add(RiskFactor(
        factor: 'no_rest_day',
        severity: 'high',
        value: daysSinceRest,
        message: 'No rest day in $daysSinceRest days',
      ));
    } else if (daysSinceRest > 7) {
      factors.add(RiskFactor(
        factor: 'no_rest_day',
        severity: 'medium',
        value: daysSinceRest,
        message: 'No rest day in $daysSinceRest days',
      ));
    }

    final riskScore = _calculateOverallScore(factors);
    final riskLevel = _determineRiskLevel(riskScore);

    return InjuryRiskAssessment(
      id: '',
      userId: userId,
      assessmentDate: DateTime.now(),
      riskScore: riskScore,
      riskLevel: riskLevel,
      loadSpikeScore: acwr > AppConstants.acwrSafeHigh ? (acwr * 50).round().clamp(0, 100) : null,
      muscleImbalanceScore: imbalances.isNotEmpty ? (imbalances.length * 30).clamp(0, 100) : null,
      recoveryScore: recoveryScore,
      riskFactors: factors,
      recommendations: _generateRecommendations(factors),
      createdAt: DateTime.now(),
    );
  }

  /// Acute:Chronic Workload Ratio.
  double _calculateACWR() {
    if (recentWorkouts.length < 5) return 1.0; // Not enough data

    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final fourWeeksAgo = now.subtract(const Duration(days: 28));

    // Acute load: this week's completed workouts count (proxy for volume)
    final acuteWorkouts = recentWorkouts.where(
      (w) => w.completedAt != null && w.completedAt!.isAfter(oneWeekAgo),
    ).length;

    // Chronic load: average weekly workouts over 4 weeks
    final chronicWorkouts = recentWorkouts.where(
      (w) => w.completedAt != null && w.completedAt!.isAfter(fourWeeksAgo),
    ).length;
    final chronicAvg = chronicWorkouts / 4.0;

    if (chronicAvg == 0) return 1.0;
    return acuteWorkouts / chronicAvg;
  }

  /// Detect muscle imbalances by comparing antagonist pair volumes.
  List<MapEntry<String, double>> _detectMuscleImbalances() {
    final imbalances = <MapEntry<String, double>>[];
    final muscleVolume = <String, int>{};

    // Count how many times each muscle was trained recently
    for (final w in recentWorkouts.take(20)) {
      // Use workout type as proxy since we don't have exercise-level data here
      if (w.workoutType.contains('upper')) {
        muscleVolume['chest'] = (muscleVolume['chest'] ?? 0) + 1;
        muscleVolume['back'] = (muscleVolume['back'] ?? 0) + 1;
      }
      if (w.workoutType.contains('lower')) {
        muscleVolume['quadriceps'] = (muscleVolume['quadriceps'] ?? 0) + 1;
        muscleVolume['hamstrings'] = (muscleVolume['hamstrings'] ?? 0) + 1;
      }
    }

    // Check antagonist pairs
    final checked = <String>{};
    for (final entry in AppConstants.antagonistPairs.entries) {
      if (checked.contains(entry.key)) continue;
      checked.add(entry.key);
      checked.add(entry.value);

      final a = (muscleVolume[entry.key] ?? 0).toDouble();
      final b = (muscleVolume[entry.value] ?? 0).toDouble();

      if (a > 0 && b > 0) {
        final ratio = a > b ? a / b : b / a;
        if (ratio > 1.5) {
          final stronger = a > b ? entry.key : entry.value;
          imbalances.add(MapEntry('$stronger dominance', ratio));
        }
      }
    }

    return imbalances;
  }

  int _calculateRecoveryScore() {
    if (recentSnapshots.isEmpty) return 75; // Default moderate-good score

    final latest = recentSnapshots.first;
    // Base score on available metrics
    int score = 70;
    if (latest.sleepHours != null) {
      score += latest.sleepHours! >= 7 ? 15 : latest.sleepHours! >= 6 ? 5 : -10;
    }
    if (latest.restingHr != null) {
      score += latest.restingHr! < 60 ? 10 : latest.restingHr! < 70 ? 0 : -10;
    }
    return score.clamp(0, 100);
  }

  int _daysSinceLastRestDay() {
    if (recentWorkouts.isEmpty) return 0;

    final now = DateTime.now();
    final completedDates = recentWorkouts
        .where((w) => w.completedAt != null)
        .map((w) => DateTime(w.completedAt!.year, w.completedAt!.month, w.completedAt!.day))
        .toSet();

    for (int i = 0; i < 14; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (!completedDates.contains(date)) {
        return i; // Days since last rest day
      }
    }
    return 14;
  }

  int _calculateOverallScore(List<RiskFactor> factors) {
    const weights = {
      'training_load_spike': 0.25,
      'muscle_imbalance': 0.20,
      'inadequate_recovery': 0.20,
      'no_rest_day': 0.15,
    };

    double score = 0;
    for (final factor in factors) {
      final weight = weights[factor.factor] ?? 0.10;
      final severityScore = factor.severity == 'high' ? 100 : factor.severity == 'medium' ? 60 : 30;
      score += weight * severityScore;
    }

    return score.clamp(0, 100).round();
  }

  String _determineRiskLevel(int score) {
    if (score > 70) return 'high';
    if (score > 40) return 'moderate';
    return 'low';
  }

  List<String> _generateRecommendations(List<RiskFactor> factors) {
    final recs = <String>[];

    for (final factor in factors) {
      switch (factor.factor) {
        case 'training_load_spike':
          recs.add('Reduce training volume by 20% this week. Consider a deload week.');
          break;
        case 'muscle_imbalance':
          recs.add('Add exercises targeting your weaker muscle groups to restore balance.');
          break;
        case 'inadequate_recovery':
          recs.add('Prioritize sleep (aim for 7-8 hours). Consider an extra rest day.');
          break;
        case 'no_rest_day':
          recs.add('Take a full rest day. Active recovery (walking, stretching) is OK.');
          break;
      }
    }

    if (recs.isEmpty) {
      recs.add('Your training load looks balanced. Keep up the good work!');
    }

    return recs;
  }
}
