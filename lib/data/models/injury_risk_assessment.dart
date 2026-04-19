import 'package:cloud_firestore/cloud_firestore.dart';

class RiskFactor {
  final String factor;
  final String severity; // 'low', 'medium', 'high'
  final dynamic value;
  final String message;

  RiskFactor({
    required this.factor,
    required this.severity,
    required this.value,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'factor': factor,
      'severity': severity,
      'value': value,
      'message': message,
    };
  }

  factory RiskFactor.fromMap(Map<String, dynamic> map) {
    return RiskFactor(
      factor: map['factor'] ?? '',
      severity: map['severity'] ?? '',
      value: map['value'],
      message: map['message'] ?? '',
    );
  }
}

class InjuryRiskAssessment {
  final String id;
  final String userId;
  final DateTime assessmentDate;
  final int riskScore; // 0-100
  final String riskLevel; // 'low', 'moderate', 'high'
  final int? loadSpikeScore;
  final int? muscleImbalanceScore;
  final int? recoveryScore;
  final int? sleepScore;
  final int? restingHrScore;
  final int? restDayScore;
  final List<RiskFactor> riskFactors;
  final List<String> recommendations;
  final DateTime createdAt;

  InjuryRiskAssessment({
    required this.id,
    required this.userId,
    required this.assessmentDate,
    required this.riskScore,
    required this.riskLevel,
    this.loadSpikeScore,
    this.muscleImbalanceScore,
    this.recoveryScore,
    this.sleepScore,
    this.restingHrScore,
    this.restDayScore,
    this.riskFactors = const [],
    this.recommendations = const [],
    required this.createdAt,
  });

  factory InjuryRiskAssessment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InjuryRiskAssessment(
      id: doc.id,
      userId: data['userId'] ?? '',
      assessmentDate: (data['assessmentDate'] as Timestamp).toDate(),
      riskScore: data['riskScore'] ?? 0,
      riskLevel: data['riskLevel'] ?? '',
      loadSpikeScore: data['loadSpikeScore'],
      muscleImbalanceScore: data['muscleImbalanceScore'],
      recoveryScore: data['recoveryScore'],
      sleepScore: data['sleepScore'],
      restingHrScore: data['restingHrScore'],
      restDayScore: data['restDayScore'],
      riskFactors: data['riskFactors'] != null
          ? (data['riskFactors'] as List)
              .map((e) => RiskFactor.fromMap(e as Map<String, dynamic>))
              .toList()
          : [],
      recommendations:
          List<String>.from(data['recommendations'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'assessmentDate': Timestamp.fromDate(assessmentDate),
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'loadSpikeScore': loadSpikeScore,
      'muscleImbalanceScore': muscleImbalanceScore,
      'recoveryScore': recoveryScore,
      'sleepScore': sleepScore,
      'restingHrScore': restingHrScore,
      'restDayScore': restDayScore,
      'riskFactors': riskFactors.map((e) => e.toMap()).toList(),
      'recommendations': recommendations,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
