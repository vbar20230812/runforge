import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile.dart';
import 'auth_provider.dart';

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null)
      .handleError((_) => null);
});
