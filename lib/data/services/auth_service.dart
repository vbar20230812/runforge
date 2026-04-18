import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'id': credential.user!.uid,
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'goal10kTimeSec': 3600,
      'strengthFrequency': 3,
      'runFrequency': 2,
      'availableEquipment': ['dumbbells'],
      'preferredRunDays': ['tuesday', 'thursday'],
    });

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserProfile?> getUserProfile() async {
    if (userId == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Stream<UserProfile?> userProfileStream() {
    if (userId == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null)
        .handleError((_) => null);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).update(data);
  }
}
