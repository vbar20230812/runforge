import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalRecord {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final String recordType; // 'max_weight', 'max_reps', 'max_volume', 'fastest_pace', 'longest_distance'
  final double value;
  final String unit;
  final DateTime achievedAt;
  final double? previousValue;

  PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.recordType,
    required this.value,
    required this.unit,
    required this.achievedAt,
    this.previousValue,
  });

  factory PersonalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonalRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      exerciseId: data['exerciseId'] ?? '',
      exerciseName: data['exerciseName'] ?? '',
      recordType: data['recordType'] ?? '',
      value: (data['value'] as num).toDouble(),
      unit: data['unit'] ?? '',
      achievedAt: (data['achievedAt'] as Timestamp).toDate(),
      previousValue: (data['previousValue'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'recordType': recordType,
      'value': value,
      'unit': unit,
      'achievedAt': Timestamp.fromDate(achievedAt),
      'previousValue': previousValue,
    };
  }
}
