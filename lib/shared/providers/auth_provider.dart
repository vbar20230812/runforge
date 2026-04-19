import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
});
