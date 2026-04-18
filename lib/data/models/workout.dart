import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final String userId;
  final String? weeklyPlanId;
  final DateTime scheduledDate;
  final String workoutType;
  final String status;
  final int estimatedDurationMin;
  final int? actualDurationMin;
  final DateTime? completedAt;
  final String? userNotes;
  final String? recommendationType;
  final String? recommendationReason;
  final DateTime createdAt;

  Workout({
    required this.id,
    required this.userId,
    this.weeklyPlanId,
    required this.scheduledDate,
    required this.workoutType,
    this.status = 'planned',
    required this.estimatedDurationMin,
    this.actualDurationMin,
    this.completedAt,
    this.userNotes,
    this.recommendationType,
    this.recommendationReason,
    required this.createdAt,
  });

  factory Workout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Workout(
      id: doc.id,
      userId: data['userId'] ?? '',
      weeklyPlanId: data['weeklyPlanId'],
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      workoutType: data['workoutType'] ?? '',
      status: data['status'] ?? 'planned',
      estimatedDurationMin: data['estimatedDurationMin'] ?? 0,
      actualDurationMin: data['actualDurationMin'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      userNotes: data['userNotes'],
      recommendationType: data['recommendationType'],
      recommendationReason: data['recommendationReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'weeklyPlanId': weeklyPlanId,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'workoutType': workoutType,
      'status': status,
      'estimatedDurationMin': estimatedDurationMin,
      'actualDurationMin': actualDurationMin,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'userNotes': userNotes,
      'recommendationType': recommendationType,
      'recommendationReason': recommendationReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isPlanned => status == 'planned';
  bool get isSkipped => status == 'skipped';
  bool get isStrength => workoutType.startsWith('strength');
  bool get isRun => workoutType.startsWith('run');
}
