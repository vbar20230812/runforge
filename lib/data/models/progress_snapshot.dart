import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressSnapshot {
  final String id;
  final String userId;
  final DateTime snapshotDate;
  // Running metrics
  final double? weeklyDistanceKm;
  final int? avgPaceSecKm;
  final int? avgHr;
  final int runSessionsWeek;
  // Strength metrics
  final int strengthSessionsWeek;
  final double? totalVolumeLoad;
  final double? boneDensityWeekly;
  // Health metrics
  final double? weightKg;
  final int? restingHr;
  final double? sleepHours;
  final int? dailySteps;
  // Calculated scores
  final int? recoveryScore; // 0-100
  final int? injuryRiskScore; // 0-100
  final int? progressScore; // 0-100
  final DateTime createdAt;

  ProgressSnapshot({
    required this.id,
    required this.userId,
    required this.snapshotDate,
    this.weeklyDistanceKm,
    this.avgPaceSecKm,
    this.avgHr,
    this.runSessionsWeek = 0,
    this.strengthSessionsWeek = 0,
    this.totalVolumeLoad,
    this.boneDensityWeekly,
    this.weightKg,
    this.restingHr,
    this.sleepHours,
    this.dailySteps,
    this.recoveryScore,
    this.injuryRiskScore,
    this.progressScore,
    required this.createdAt,
  });

  factory ProgressSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgressSnapshot(
      id: doc.id,
      userId: data['userId'] ?? '',
      snapshotDate: (data['snapshotDate'] as Timestamp).toDate(),
      weeklyDistanceKm: (data['weeklyDistanceKm'] as num?)?.toDouble(),
      avgPaceSecKm: data['avgPaceSecKm'],
      avgHr: data['avgHr'],
      runSessionsWeek: data['runSessionsWeek'] ?? 0,
      strengthSessionsWeek: data['strengthSessionsWeek'] ?? 0,
      totalVolumeLoad: (data['totalVolumeLoad'] as num?)?.toDouble(),
      boneDensityWeekly: (data['boneDensityWeekly'] as num?)?.toDouble(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      restingHr: data['restingHr'],
      sleepHours: (data['sleepHours'] as num?)?.toDouble(),
      dailySteps: data['dailySteps'],
      recoveryScore: data['recoveryScore'],
      injuryRiskScore: data['injuryRiskScore'],
      progressScore: data['progressScore'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'snapshotDate': Timestamp.fromDate(snapshotDate),
      'weeklyDistanceKm': weeklyDistanceKm,
      'avgPaceSecKm': avgPaceSecKm,
      'avgHr': avgHr,
      'runSessionsWeek': runSessionsWeek,
      'strengthSessionsWeek': strengthSessionsWeek,
      'totalVolumeLoad': totalVolumeLoad,
      'boneDensityWeekly': boneDensityWeekly,
      'weightKg': weightKg,
      'restingHr': restingHr,
      'sleepHours': sleepHours,
      'dailySteps': dailySteps,
      'recoveryScore': recoveryScore,
      'injuryRiskScore': injuryRiskScore,
      'progressScore': progressScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ProgressSnapshot copyWith({
    DateTime? snapshotDate,
    double? weeklyDistanceKm,
    int? avgPaceSecKm,
    int? avgHr,
    int? runSessionsWeek,
    int? strengthSessionsWeek,
    double? totalVolumeLoad,
    double? boneDensityWeekly,
    double? weightKg,
    int? restingHr,
    double? sleepHours,
    int? dailySteps,
    int? recoveryScore,
    int? injuryRiskScore,
    int? progressScore,
  }) {
    return ProgressSnapshot(
      id: id,
      userId: userId,
      createdAt: createdAt,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      weeklyDistanceKm: weeklyDistanceKm ?? this.weeklyDistanceKm,
      avgPaceSecKm: avgPaceSecKm ?? this.avgPaceSecKm,
      avgHr: avgHr ?? this.avgHr,
      runSessionsWeek: runSessionsWeek ?? this.runSessionsWeek,
      strengthSessionsWeek: strengthSessionsWeek ?? this.strengthSessionsWeek,
      totalVolumeLoad: totalVolumeLoad ?? this.totalVolumeLoad,
      boneDensityWeekly: boneDensityWeekly ?? this.boneDensityWeekly,
      weightKg: weightKg ?? this.weightKg,
      restingHr: restingHr ?? this.restingHr,
      sleepHours: sleepHours ?? this.sleepHours,
      dailySteps: dailySteps ?? this.dailySteps,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      injuryRiskScore: injuryRiskScore ?? this.injuryRiskScore,
      progressScore: progressScore ?? this.progressScore,
    );
  }
}
