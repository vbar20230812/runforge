import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/weekly_plan.dart';

class PlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createWeeklyPlan(WeeklyPlan plan) async {
    final docRef = await _firestore.collection('weekly_plans').add(plan.toFirestore());
    return docRef.id;
  }

  Future<WeeklyPlan?> getWeeklyPlan(String userId, int weekNumber, int year) async {
    try {
      final snapshot = await _firestore
          .collection('weekly_plans')
          .where('userId', isEqualTo: userId)
          .where('weekNumber', isEqualTo: weekNumber)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return WeeklyPlan.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('getWeeklyPlan error: $e');
      return null;
    }
  }

  Stream<WeeklyPlan?> currentWeekPlanStream(String userId) {
    final now = DateTime.now();
    // ISO week number calculation
    final jan1 = DateTime(now.year, 1, 1);
    final days = now.difference(jan1).inDays;
    final weekNumber = ((days + jan1.weekday) / 7).ceil();

    return _firestore
        .collection('weekly_plans')
        .where('userId', isEqualTo: userId)
        .where('weekNumber', isEqualTo: weekNumber)
        .where('year', isEqualTo: now.year)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return WeeklyPlan.fromFirestore(snapshot.docs.first);
        })
        .handleError((_) => null);
  }

  Future<void> updateWeeklyPlan(String planId, Map<String, dynamic> data) async {
    await _firestore.collection('weekly_plans').doc(planId).update(data);
  }
}
