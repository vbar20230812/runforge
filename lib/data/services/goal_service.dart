import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/training_goal.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createGoal(TrainingGoal goal) async {
    final docRef = await _firestore.collection('training_goals').add(goal.toFirestore());
    return docRef.id;
  }

  Future<TrainingGoal?> getActiveGoal(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('training_goals')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return TrainingGoal.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('getActiveGoal error: $e');
      return null;
    }
  }

  Stream<TrainingGoal?> activeGoalStream(String userId) {
    return _firestore
        .collection('training_goals')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return TrainingGoal.fromFirestore(snapshot.docs.first);
        })
        .handleError((_) => null);
  }

  Future<void> updateGoal(String goalId, Map<String, dynamic> data) async {
    await _firestore.collection('training_goals').doc(goalId).update(data);
  }
}
