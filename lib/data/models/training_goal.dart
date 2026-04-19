import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingGoal {
  final String id;
  final String userId;
  final String goalType; // 'maintain', 'improve_time', 'race_prep'
  final String status; // 'active', 'achieved', 'abandoned'
  final int? target10kTimeSec;
  final int? targetPaceSecKm;
  final DateTime? raceDate;
  final int? baseline10kTimeSec;
  final int? baselinePaceSecKm;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime? achievedAt;
  final DateTime? lastRecalculation;
  final bool isDefault;

  TrainingGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    this.status = 'active',
    this.target10kTimeSec,
    this.targetPaceSecKm,
    this.raceDate,
    this.baseline10kTimeSec,
    this.baselinePaceSecKm,
    this.targetDate,
    required this.createdAt,
    this.achievedAt,
    this.lastRecalculation,
    this.isDefault = false,
  });

  factory TrainingGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainingGoal(
      id: doc.id,
      userId: data['userId'] ?? '',
      goalType: data['goalType'] ?? '',
      status: data['status'] ?? 'active',
      target10kTimeSec: data['target10kTimeSec'],
      targetPaceSecKm: data['targetPaceSecKm'],
      raceDate: data['raceDate'] != null
          ? (data['raceDate'] as Timestamp).toDate()
          : null,
      baseline10kTimeSec: data['baseline10kTimeSec'],
      baselinePaceSecKm: data['baselinePaceSecKm'],
      targetDate: data['targetDate'] != null
          ? (data['targetDate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      achievedAt: data['achievedAt'] != null
          ? (data['achievedAt'] as Timestamp).toDate()
          : null,
      lastRecalculation: data['lastRecalculation'] != null
          ? (data['lastRecalculation'] as Timestamp).toDate()
          : null,
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'goalType': goalType,
      'status': status,
      'target10kTimeSec': target10kTimeSec,
      'targetPaceSecKm': targetPaceSecKm,
      'raceDate': raceDate != null ? Timestamp.fromDate(raceDate!) : null,
      'baseline10kTimeSec': baseline10kTimeSec,
      'baselinePaceSecKm': baselinePaceSecKm,
      'targetDate':
          targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'achievedAt':
          achievedAt != null ? Timestamp.fromDate(achievedAt!) : null,
      'lastRecalculation': lastRecalculation != null
          ? Timestamp.fromDate(lastRecalculation!)
          : null,
      'isDefault': isDefault,
    };
  }

  TrainingGoal copyWith({
    String? goalType,
    String? status,
    int? target10kTimeSec,
    int? targetPaceSecKm,
    DateTime? raceDate,
    int? baseline10kTimeSec,
    int? baselinePaceSecKm,
    DateTime? targetDate,
    DateTime? achievedAt,
    DateTime? lastRecalculation,
    bool? isDefault,
  }) {
    return TrainingGoal(
      id: id,
      userId: userId,
      createdAt: createdAt,
      goalType: goalType ?? this.goalType,
      status: status ?? this.status,
      target10kTimeSec: target10kTimeSec ?? this.target10kTimeSec,
      targetPaceSecKm: targetPaceSecKm ?? this.targetPaceSecKm,
      raceDate: raceDate ?? this.raceDate,
      baseline10kTimeSec: baseline10kTimeSec ?? this.baseline10kTimeSec,
      baselinePaceSecKm: baselinePaceSecKm ?? this.baselinePaceSecKm,
      targetDate: targetDate ?? this.targetDate,
      achievedAt: achievedAt ?? this.achievedAt,
      lastRecalculation: lastRecalculation ?? this.lastRecalculation,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
