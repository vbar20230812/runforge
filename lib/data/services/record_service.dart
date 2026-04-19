import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/personal_record.dart';

class RecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrUpdateRecord(PersonalRecord record) async {
    // Check if a record already exists for this user+exercise+type
    try {
      final existing = await _firestore
          .collection('personal_records')
          .where('userId', isEqualTo: record.userId)
          .where('exerciseId', isEqualTo: record.exerciseId)
          .where('recordType', isEqualTo: record.recordType)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('personal_records').add(record.toFirestore());
      } else {
        final prevValue = existing.docs.first.data()['value'] as double?;
        await _firestore.collection('personal_records').doc(existing.docs.first.id).update({
          'value': record.value,
          'achievedAt': FieldValue.serverTimestamp(),
          'previousValue': prevValue,
        });
      }
    } catch (e) {
      debugPrint('createOrUpdateRecord error: $e');
    }
  }

  Future<List<PersonalRecord>> getRecordsForExercise(String userId, String exerciseId) async {
    try {
      final snapshot = await _firestore
          .collection('personal_records')
          .where('userId', isEqualTo: userId)
          .where('exerciseId', isEqualTo: exerciseId)
          .get();
      return snapshot.docs.map((doc) => PersonalRecord.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('getRecordsForExercise error: $e');
      return [];
    }
  }

  Stream<List<PersonalRecord>> allRecordsStream(String userId) {
    return _firestore
        .collection('personal_records')
        .where('userId', isEqualTo: userId)
        .orderBy('achievedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PersonalRecord.fromFirestore(doc)).toList())
        .handleError((_) => <PersonalRecord>[]);
  }
}
