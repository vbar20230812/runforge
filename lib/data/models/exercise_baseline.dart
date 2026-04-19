import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseBaseline {
  final String id;
  final String userId;
  final String exerciseId;
  final double? baselineWeightKg;
  final int? baselineReps;
  final DateTime? baselineDate;
  final double? lastWeekAvgWeight;
  final int? lastWeekAvgReps;
  final DateTime updatedAt;

  ExerciseBaseline({
    required this.id,
    required this.userId,
    required this.exerciseId,
    this.baselineWeightKg,
    this.baselineReps,
    this.baselineDate,
    this.lastWeekAvgWeight,
    this.lastWeekAvgReps,
    required this.updatedAt,
  });

  factory ExerciseBaseline.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseBaseline(
      id: doc.id,
      userId: data['userId'] ?? '',
      exerciseId: data['exerciseId'] ?? '',
      baselineWeightKg: (data['baselineWeightKg'] as num?)?.toDouble(),
      baselineReps: data['baselineReps'],
      baselineDate: data['baselineDate'] != null
          ? (data['baselineDate'] as Timestamp).toDate()
          : null,
      lastWeekAvgWeight: (data['lastWeekAvgWeight'] as num?)?.toDouble(),
      lastWeekAvgReps: data['lastWeekAvgReps'],
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'baselineWeightKg': baselineWeightKg,
      'baselineReps': baselineReps,
      'baselineDate': baselineDate != null
          ? Timestamp.fromDate(baselineDate!)
          : null,
      'lastWeekAvgWeight': lastWeekAvgWeight,
      'lastWeekAvgReps': lastWeekAvgReps,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ExerciseBaseline copyWith({
    double? baselineWeightKg,
    int? baselineReps,
    DateTime? baselineDate,
    double? lastWeekAvgWeight,
    int? lastWeekAvgReps,
  }) {
    return ExerciseBaseline(
      id: id,
      userId: userId,
      exerciseId: exerciseId,
      baselineWeightKg: baselineWeightKg ?? this.baselineWeightKg,
      baselineReps: baselineReps ?? this.baselineReps,
      baselineDate: baselineDate ?? this.baselineDate,
      lastWeekAvgWeight: lastWeekAvgWeight ?? this.lastWeekAvgWeight,
      lastWeekAvgReps: lastWeekAvgReps ?? this.lastWeekAvgReps,
      updatedAt: DateTime.now(),
    );
  }
}
