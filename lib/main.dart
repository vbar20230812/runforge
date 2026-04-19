import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'data/services/exercise_service.dart';
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

  // Seed exercises if collection is empty
  try {
    final exerciseSnapshot = await FirebaseFirestore.instance
        .collection('exercises')
        .limit(1)
        .get();
    if (exerciseSnapshot.docs.isEmpty) {
      await ExerciseService().seedExercises();
    }
  } catch (e) {
    debugPrint('Exercise seed error: $e');
  }

  runApp(const ProviderScope(child: RunForgeApp()));
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
