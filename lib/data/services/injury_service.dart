import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/injury_risk_assessment.dart';

class InjuryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> saveAssessment(InjuryRiskAssessment assessment) async {
    final docRef = await _firestore.collection('injury_risk_assessments').add(assessment.toFirestore());
    return docRef.id;
  }

  Future<InjuryRiskAssessment?> getLatestAssessment(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('injury_risk_assessments')
          .where('userId', isEqualTo: userId)
          .orderBy('assessmentDate', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return InjuryRiskAssessment.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('getLatestAssessment error: $e');
      return null;
    }
  }

  Future<List<InjuryRiskAssessment>> getAssessmentHistory(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('injury_risk_assessments')
          .where('userId', isEqualTo: userId)
          .orderBy('assessmentDate', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => InjuryRiskAssessment.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('getAssessmentHistory error: $e');
      return [];
    }
  }
}
