import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyPlan {
  final String id;
  final String userId;
  final int weekNumber;
  final int year;
  final String phase; // 'base', 'build', 'peak', 'recover'
  final int mesocycle;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> workoutIds;
  final DateTime createdAt;

  WeeklyPlan({
    required this.id,
    required this.userId,
    required this.weekNumber,
    required this.year,
    required this.phase,
    required this.mesocycle,
    required this.startDate,
    required this.endDate,
    this.workoutIds = const [],
    required this.createdAt,
  });

  factory WeeklyPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklyPlan(
      id: doc.id,
      userId: data['userId'] ?? '',
      weekNumber: data['weekNumber'] ?? 0,
      year: data['year'] ?? 0,
      phase: data['phase'] ?? '',
      mesocycle: data['mesocycle'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      workoutIds: List<String>.from(data['workoutIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'weekNumber': weekNumber,
      'year': year,
      'phase': phase,
      'mesocycle': mesocycle,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'workoutIds': workoutIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  WeeklyPlan copyWith({
    int? weekNumber,
    int? year,
    String? phase,
    int? mesocycle,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? workoutIds,
  }) {
    return WeeklyPlan(
      id: id,
      userId: userId,
      createdAt: createdAt,
      weekNumber: weekNumber ?? this.weekNumber,
      year: year ?? this.year,
      phase: phase ?? this.phase,
      mesocycle: mesocycle ?? this.mesocycle,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      workoutIds: workoutIds ?? this.workoutIds,
    );
  }
}
