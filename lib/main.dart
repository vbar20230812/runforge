import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'data/services/exercise_service.dart';
import 'data/services/exercise_image_service.dart';
import 'router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  // Auto-login with credentials from .env
  if (FirebaseAuth.instance.currentUser == null) {
    final email = dotenv.env['FIREBASE_EMAIL'];
    final password = dotenv.env['FIREBASE_PASSWORD'];
    if (email != null && password != null) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    // Ensure user profile document exists
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Runner',
        'createdAt': FieldValue.serverTimestamp(),
        'goal10kTimeSec': 3600,
        'strengthFrequency': 3,
        'runFrequency': 2,
        'availableEquipment': ['dumbbell'],
        'preferredRunDays': ['tuesday', 'thursday'],
      });
    }

    // Seed exercises (idempotent — uses set, so existing docs get updated)
    try {
      await ExerciseService().seedExercises();
    } catch (e) {
      debugPrint('Exercise seed error: $e');
    }

    // Backfill exercise images in background (non-blocking)
    _backfillExerciseImages();
  }

  runApp(const ProviderScope(child: RunForgeApp()));
}

/// Fetch images from wger.de for exercises that don't have one yet.
/// Runs in the background — does not block app startup.
Future<void> _backfillExerciseImages() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('exercises').get();
    final imageService = ExerciseImageService();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['imageSource'] != null && (data['imageSource'] as String).isNotEmpty) {
        continue; // Already has an image
      }

      final name = data['name'] as String? ?? '';
      if (name.isEmpty) continue;

      final info = await imageService.getExerciseInfo(name);
      if (info.imageUrl != null) {
        await doc.reference.update({
          'imageSource': info.imageUrl,
          if (info.shortDescription != null)
            'shortDescription': info.shortDescription,
        });
        debugPrint('Updated image for: $name');
      }

      // Small delay to avoid hitting API rate limits
      await Future.delayed(const Duration(milliseconds: 200));
    }
    debugPrint('Exercise image backfill complete');
  } catch (e) {
    debugPrint('Image backfill error: $e');
  }
}

class RunForgeApp extends StatelessWidget {
  const RunForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RunForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
