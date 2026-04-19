import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutExercise {
  final String id;
  final String exerciseId;
  final int order;
  final String? supersetPairId;
  final int sets;
  final int repsPerSet;
  final double? weightKg;
  final int? actualSets;
  final List<int>? actualReps;
  final List<double>? actualWeight;
  final int restSeconds;
  final List<String> primaryMusclesTargeted;
  final int estimatedLoadScore;
  final String exerciseType; // 'strength' or 'cardio_burst'
  final int? durationSeconds; // for cardio bursts

  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.order,
    this.supersetPairId,
    required this.sets,
    required this.repsPerSet,
    this.weightKg,
    this.actualSets,
    this.actualReps,
    this.actualWeight,
    required this.restSeconds,
    required this.primaryMusclesTargeted,
    required this.estimatedLoadScore,
    this.exerciseType = 'strength',
    this.durationSeconds,
  });

  factory WorkoutExercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutExercise(
      id: doc.id,
      exerciseId: data['exerciseId'] ?? '',
      order: data['order'] ?? 0,
      supersetPairId: data['supersetPairId'],
      sets: data['sets'] ?? 3,
      repsPerSet: data['repsPerSet'] ?? 10,
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      actualSets: data['actualSets'],
      actualReps: data['actualReps'] != null
          ? List<int>.from(data['actualReps'])
          : null,
      actualWeight: data['actualWeight'] != null
          ? (data['actualWeight'] as List).map((e) => (e as num).toDouble()).toList()
          : null,
      restSeconds: data['restSeconds'] ?? 60,
      primaryMusclesTargeted: List<String>.from(data['primaryMusclesTargeted'] ?? []),
      estimatedLoadScore: data['estimatedLoadScore'] ?? 0,
      exerciseType: data['exerciseType'] ?? 'strength',
      durationSeconds: data['durationSeconds'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'exerciseId': exerciseId,
      'order': order,
      'supersetPairId': supersetPairId,
      'sets': sets,
      'repsPerSet': repsPerSet,
      'weightKg': weightKg,
      'actualSets': actualSets,
      'actualReps': actualReps,
      'actualWeight': actualWeight,
      'restSeconds': restSeconds,
      'primaryMusclesTargeted': primaryMusclesTargeted,
      'estimatedLoadScore': estimatedLoadScore,
      'exerciseType': exerciseType,
      'durationSeconds': durationSeconds,
    };
  }
}
