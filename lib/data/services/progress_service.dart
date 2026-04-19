import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/progress_snapshot.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createSnapshot(ProgressSnapshot snapshot) async {
    final docRef = await _firestore.collection('progress_snapshots').add(snapshot.toFirestore());
    return docRef.id;
  }

  Future<List<ProgressSnapshot>> getSnapshotsByDateRange(
    String userId, DateTime start, DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('progress_snapshots')
          .where('userId', isEqualTo: userId)
          .where('snapshotDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('snapshotDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('snapshotDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => ProgressSnapshot.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('getSnapshotsByDateRange error: $e');
      return [];
    }
  }

  Future<ProgressSnapshot?> getLatestSnapshot(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('progress_snapshots')
          .where('userId', isEqualTo: userId)
          .orderBy('snapshotDate', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ProgressSnapshot.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('getLatestSnapshot error: $e');
      return null;
    }
  }

  Stream<List<ProgressSnapshot>> streamSnapshots(String userId, {int limit = 30}) {
    return _firestore
        .collection('progress_snapshots')
        .where('userId', isEqualTo: userId)
        .orderBy('snapshotDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ProgressSnapshot.fromFirestore(doc)).toList())
        .handleError((_) => <ProgressSnapshot>[]);
  }
}
