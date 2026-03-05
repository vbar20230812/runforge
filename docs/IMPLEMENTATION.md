# RunForge Implementation Guide v3.0

## Architecture: Flutter + Firebase (Serverless)

**Target Users:** ≤10 | **Monthly Cost:** $0 | **No Backend Required**

---

## Quick Start

### Prerequisites

- Flutter SDK 3.x installed
- Firebase account (free tier)
- FlutterFire CLI

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login
```

---

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Create a project" → Name: `runforge-dev`
3. Disable Google Analytics (optional)
4. Enable services:
   - **Authentication**: Email/Password + Google
   - **Firestore**: Create database (test mode)
   - **Storage**: Enable (test mode)

---

## Step 2: Create Flutter Project

```powershell
cd C:\Users\victo\Projects\RunForge

# Create Flutter web app
flutter create . --platforms=web

# Add dependencies
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutter pub add go_router flutter_riverpod uuid intl
flutter pub add fl_chart table_calendar
flutter pub add google_sign_in

# Configure Firebase
flutterfire configure
```

---

## Step 3: Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── date_helpers.dart
│
├── data/
│   ├── models/
│   │   ├── user_profile.dart
│   │   ├── workout.dart
│   │   ├── exercise.dart
│   │   └── training_goal.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── user_service.dart
│   │   ├── workout_service.dart
│   │   └── exercise_service.dart
│   │
│   └── repositories/
│       └── user_repository.dart
│
├── logic/
│   ├── workout_generator.dart
│   └── injury_risk_calculator.dart
│
├── features/
│   ├── auth/
│   │   └── auth_page.dart
│   ├── dashboard/
│   │   └── dashboard_page.dart
│   ├── calendar/
│   │   └── calendar_page.dart
│   ├── workout/
│   │   └── workout_detail_page.dart
│   ├── progress/
│   │   └── progress_page.dart
│   └── settings/
│       └── settings_page.dart
│
├── shared/
│   └── widgets/
│       └── loading_spinner.dart
│
└── router/
    └── app_router.dart
```

---

## Step 4: Initialize Firebase

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: RunForgeApp()));
}

class RunForgeApp extends StatelessWidget {
  const RunForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RunForge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
```

---

## Step 5: Auth Service

```dart
// lib/data/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

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
      'garminConnected': false,
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
}
```

---

## Step 6: Router Setup

```dart
// lib/router/app_router.dart
import 'package:go_router/go_router.dart';
import '../features/auth/auth_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/calendar/calendar_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarPage(),
    ),
  ],
);
```

---

## Step 7: Firestore Security Rules

```javascript
// Deploy in Firebase Console > Firestore > Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /exercises/{exerciseId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    match /workouts/{workoutId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    match /training_goals/{goalId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    match /progress_snapshots/{snapshotId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Step 8: Run & Deploy

```powershell
# Run locally
flutter run -d chrome

# Build for production
flutter build web

# Deploy to Firebase Hosting
firebase init hosting
firebase deploy --only hosting
```

---

## Seed Exercise Data

Run this once to populate the exercises collection in Firestore:

```dart
// lib/data/seeds/seed_exercises.dart
Future<void> seedExercises() async {
  final firestore = FirebaseFirestore.instance;
  final exercises = [
    {
      'id': 'squat_barbell',
      'name': 'Barbell Squat',
      'primaryMuscles': ['quadriceps', 'glutes'],
      'secondaryMuscles': ['hamstrings', 'core'],
      'equipment': 'barbell',
      'movementType': 'compound',
      'difficulty': 3,
      'boneDensityScore': 85,
    },
    {
      'id': 'deadlift_barbell',
      'name': 'Barbell Deadlift',
      'primaryMuscles': ['hamstrings', 'glutes', 'back'],
      'secondaryMuscles': ['core', 'forearms'],
      'equipment': 'barbell',
      'movementType': 'compound',
      'difficulty': 4,
      'boneDensityScore': 90,
    },
    {
      'id': 'lunge_dumbbell',
      'name': 'Dumbbell Lunges',
      'primaryMuscles': ['quadriceps', 'glutes'],
      'secondaryMuscles': ['hamstrings', 'calves'],
      'equipment': 'dumbbell',
      'movementType': 'compound',
      'difficulty': 2,
      'isUnilateral': true,
      'boneDensityScore': 70,
    },
    // Add more exercises...
  ];

  for (final exercise in exercises) {
    await firestore.collection('exercises').doc(exercise['id']).set(exercise);
  }
}
```

---

## Cost Summary

| Service | Free Tier | Your Usage | Cost |
|---------|-----------|------------|------|
| Firestore | 1GB, 50K reads/day | <100MB, <5K reads/day | **$0** |
| Auth | 10K users | <10 users | **$0** |
| Hosting | 10GB/month | <1GB/month | **$0** |
| Storage | 5GB | <100MB | **$0** |
| **TOTAL** | | | **$0/month** |

---

## Key Files Checklist

### Phase 1A (Auth + Setup)
- [ ] `lib/main.dart`
- [ ] `lib/firebase_options.dart`
- [ ] `lib/router/app_router.dart`
- [ ] `lib/data/services/auth_service.dart`
- [ ] `lib/features/auth/auth_page.dart`
- [ ] `lib/features/dashboard/dashboard_page.dart`

### Phase 1B (Workouts)
- [ ] `lib/data/models/exercise.dart`
- [ ] `lib/data/models/workout.dart`
- [ ] `lib/data/services/workout_service.dart`
- [ ] `lib/logic/workout_generator.dart`
- [ ] `lib/features/calendar/calendar_page.dart`
- [ ] Seed exercises to Firestore

---

*Last updated: March 3, 2026*
