# RunForge — Running Personal Trainer
## Design & Architecture Document v3.1

**Version:** 3.1
**Date:** April 18, 2026
**Status:** Phase 1A Complete | Phase 1B–7 Not Started
**Implementation Coverage:** ~15% of documented features exist in code
**Target Users:** Single user (personal use, auto-login)

---

## What's Changed in v3.1

| Change | Previous | Now |
|--------|----------|-----|
| **Frontend** | React + Vite | Flutter Web |
| **Database** | PostgreSQL (Supabase) | Firestore (Firebase) |
| **Backend** | Node.js + Express | **None** (Serverless) |
| **Auth** | Supabase Auth | Firebase Auth (auto-login, single user) |
| **Hosting** | Vercel + Render | Firebase Hosting |
| **Cost** | $0-53/mo | **$0/mo** (single user) |
| **Garmin** | Planned (Phase 4) | **Removed from scope** |
| **Multi-user** | ≤10 users | **Single user only** |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER WEB APP                               │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │    Pages     │  │  Widgets     │  │  Services/Providers  │   │
│  │  (Features)  │  │  (UI)        │  │  (Business Logic)    │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
│         └─────────────────┼──────────────────────┘               │
│                           │                                      │
│                           ▼                                      │
│              ┌─────────────────────────┐                         │
│              │   Firebase SDK          │                         │
│              │  (Auth + Firestore)     │                         │
│              └────────────┬────────────┘                         │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            ▼
            ┌───────────────────────────────────┐
            │           FIREBASE                │
            │  ┌─────────┐  ┌────────────────┐  │
            │  │  Auth   │  │   Firestore    │  │
            │  │ (Email) │  │  (NoSQL DB)    │  │
            │  └─────────┘  └────────────────┘  │
            │  ┌─────────┐  ┌────────────────┐  │
            │  │ Storage │  │    Hosting     │  │
            │  │ (Images)│  │   (Web Deploy) │  │
            │  └─────────┘  └────────────────┘  │
            └───────────────────────────────────┘

**No backend server** - All logic runs client-side in Flutter
**Single user** - Auto-login on app start, no signup flow needed
**All data operations** via Firebase SDK directly from app
```

---

## Current Implementation Status (as of April 18, 2026)

### What Actually Exists

| Component | Status | Notes |
|-----------|--------|-------|
| Flutter project + Firebase init | Done | Web-only |
| Auth (Email/Password) | Done | Auto-login with hardcoded creds (see Security section) |
| UserProfile model | Done | Basic fields implemented |
| Exercise model | Done | Only 10 exercises seeded (doc specifies 37+) |
| Workout + WorkoutExercise models | Done | Basic fields implemented |
| ExerciseService | Done | Queries work, images via wger.de API |
| WorkoutService | Done | CRUD + date-range queries (requires composite index) |
| AuthService | Done | signUp, signIn, signOut, getUserProfile |
| Calendar page | Partial | Month view only, basic workout markers |
| Dashboard page | Skeleton | Static placeholder cards |
| Settings pages | Partial | Profile edit, training prefs, goal settings |

### Critical Known Issues

1. **SECURITY: Firestore rules are wide open** — deployed rules are `allow read, write: if true` (see Section 8)
2. **SECURITY: Hardcoded credentials** in `main.dart` — email/password in source code
3. **Riverpod imported but unused** — all state is local `setState`, no providers exist
4. **No workout generator** — exercises are hardcoded static lists, not algorithmically generated

### What Does NOT Exist Yet

All of the following are documented below but **not implemented**:
- Training goals model and management
- Workout generator algorithm (superset pairing, periodization, bone density scoring)
- Weekly plan generator
- Injury risk calculator (ACWR, muscle imbalance detection)
- Progress snapshots and progress charts
- Personal records tracking
- Garmin integration (removed from scope)
- Recommendation engine
- Muscle impact visualization
- Workout player (superset tracking, rest timer)
- `lib/logic/` directory (entire business logic layer)
- `lib/data/repositories/` directory
- `lib/shared/` directory

> **Note:** The legacy `docs/RunForge-Design-Document.md` (v1.0, React/PostgreSQL architecture) is superseded by this document. It should be archived or deleted to avoid confusion.

---

## 1. Product Vision

RunForge is a web-based personal training application purpose-built for runners targeting a 10K PR. It combines superset strength workouts with structured running plans, visualized on a training calendar.

### 1.1 Target User Profile

- Intermediate runners (able to complete 10K, aiming to improve time)
- Age range: 30–55, health-conscious
- Wants efficient gym sessions (20–35 min) using supersets
- Runs 2–3 times per week, strength trains 3–5 times per week

### 1.2 Core Goals

| # | Goal | Metric |
|---|------|--------|
| G1 | Goal-oriented training | All workouts drive toward user's specific goal |
| G2 | Improve 10K time | Pace progression tracked from logged run data |
| G3 | Prevent injury | Balanced muscle loading + injury risk monitoring |
| G4 | Maximize gym efficiency | Superset-based workouts under 35 min |
| G5 | Workout variety | No repeated workout in a 4-week cycle |
| G6 | ~~Seamless device sync~~ | ~~Removed from scope~~ |
| G7 | Increase bone density | Prioritize high-impact + heavy-load exercises |
| G8 | Track progress | Visual progress charts, PR tracking |

### 1.3 Default Goal

**Default goal: Maintain 10K under 1 hour (60 minutes)**

---

## 2. Technology Stack

### 2.1 Frontend (Flutter)

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Framework** | Flutter 3.x | Cross-platform UI framework |
| **Language** | Dart | Type-safe, compiled language |
| **State Management** | Riverpod or Provider | Reactive state management (**NOTE:** Riverpod is imported but unused — all pages use `setState` directly) |
| **Routing** | GoRouter | Declarative routing |
| **Charts** | fl_chart | Progress visualizations |
| **Calendar** | table_calendar | Training calendar |

### 2.2 Backend (Firebase - Serverless)

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Authentication** | Firebase Auth | Email/password, auto-login (single user) |
| **Database** | Cloud Firestore | NoSQL document database |
| **Storage** | Firebase Storage | Exercise images/animations |
| **Hosting** | Firebase Hosting | Web app deployment |

### 2.3 Why This Stack

| Factor | Decision Rationale |
|--------|-------------------|
| **Flutter vs React** | You already know Flutter (assetflow3); single codebase for web/mobile |
| **Firestore vs SQL** | Simpler for small user base; real-time sync built-in |
| **No Backend** | Single-user personal app; Firebase SDK handles everything directly |
| **Cost** | Entire stack is **free** for this user scale (**NOTE:** Real-time `snapshots()` listeners consume reads continuously; 37+ exercise images may exceed Storage free tier) |

---

## 3. Firestore Database Schema

### 3.1 Collection Structure

```
firestore/
├── users/                          # User profiles
│   └── {uid}/
│       └── (profile document)
│
├── training_goals/                 # User goals
│   └── {goalId}/
│       └── (goal document)
│
├── exercises/                      # Global exercise catalog
│   └── {exerciseId}/
│       └── (exercise document)
│
├── weekly_plans/                   # Weekly training plans
│   └── {planId}/
│       └── (plan document)
│
├── workouts/                       # Individual workouts
│   └── {workoutId}/
│       └── (workout document)
│       └── exercises/              # Subcollection
│           └── {exerciseLogId}/
│
├── progress_snapshots/             # Daily progress records
│   └── {snapshotId}/
│       └── (snapshot document)
│
├── injury_risk_assessments/        # Injury risk records
│   └── {assessmentId}/
│       └── (assessment document)
│
└── personal_records/               # User PRs
    └── {recordId}/
        └── (record document)
```

### 3.2 Document Models (Dart)

#### User Profile

```dart
// Collection: users/{uid}
class UserProfile {
  final String id;
  final String email;
  final String? name;
  final DateTime createdAt;

  // Physical Profile
  final int? age;
  final double? weightKg;
  final int? heightCm;
  final int? current10kTimeSec;
  final int goal10kTimeSec;

  // Training Preferences
  final int strengthFrequency;      // 3-5 sessions/week
  final int runFrequency;           // 2-3 sessions/week
  final List<String> availableEquipment;
  final List<String> preferredRunDays;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
    this.age,
    this.weightKg,
    this.heightCm,
    this.current10kTimeSec,
    this.goal10kTimeSec = 3600, // Default: 60 min
    this.strengthFrequency = 3,
    this.runFrequency = 2,
    this.availableEquipment = const ['dumbbells'],
    this.preferredRunDays = const ['tuesday', 'thursday'],
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      age: data['age'],
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      heightCm: data['heightCm'],
      current10kTimeSec: data['current10kTimeSec'],
      goal10kTimeSec: data['goal10kTimeSec'] ?? 3600,
      strengthFrequency: data['strengthFrequency'] ?? 3,
      runFrequency: data['runFrequency'] ?? 2,
      availableEquipment: List<String>.from(data['availableEquipment'] ?? []),
      preferredRunDays: List<String>.from(data['preferredRunDays'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'current10kTimeSec': current10kTimeSec,
      'goal10kTimeSec': goal10kTimeSec,
      'strengthFrequency': strengthFrequency,
      'runFrequency': runFrequency,
      'availableEquipment': availableEquipment,
      'preferredRunDays': preferredRunDays,
    };
  }
}
```

#### Training Goal

```dart
// Collection: training_goals/{goalId}
class TrainingGoal {
  final String id;
  final String userId;
  final String goalType;           // 'maintain', 'improve_time', 'race_prep'
  final String status;             // 'active', 'achieved', 'abandoned'

  final int? target10kTimeSec;
  final int? targetPaceSecKm;
  final DateTime? raceDate;

  final int? baseline10kTimeSec;
  final int? baselinePaceSecKm;
  final DateTime? targetDate;

  final DateTime createdAt;
  final DateTime? achievedAt;
  final DateTime? lastRecalculation;
  final bool isDefault;

  TrainingGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    this.status = 'active',
    this.target10kTimeSec,
    this.targetPaceSecKm,
    this.raceDate,
    this.baseline10kTimeSec,
    this.baselinePaceSecKm,
    this.targetDate,
    required this.createdAt,
    this.achievedAt,
    this.lastRecalculation,
    this.isDefault = false,
  });
}
```

#### Exercise

```dart
// Collection: exercises/{exerciseId}
class Exercise {
  final String id;                 // e.g., 'squat_barbell'
  final String name;               // 'Barbell Squat'
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;          // 'barbell', 'dumbbell', 'bodyweight', 'cable'
  final String movementType;       // 'compound', 'isolation'
  final int difficulty;            // 1-5
  final bool isUnilateral;
  final String? instructions;
  final int boneDensityScore;      // 0-100
  final String? imageSource;       // Firebase Storage path
  final bool hasAnimation;

  Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.movementType,
    required this.difficulty,
    this.isUnilateral = false,
    this.instructions,
    this.boneDensityScore = 50,
    this.imageSource,
    this.hasAnimation = false,
  });
}
```

#### Workout

```dart
// Collection: workouts/{workoutId}
class Workout {
  final String id;
  final String userId;
  final String? weeklyPlanId;
  final DateTime scheduledDate;
  final String workoutType;        // 'strength_upper', 'strength_lower', 'run_easy', etc.
  final String status;             // 'planned', 'in_progress', 'completed', 'skipped'

  final int estimatedDurationMin;
  final int? actualDurationMin;

  final DateTime? completedAt;
  final String? userNotes;

  final String? recommendationType;
  final String? recommendationReason;

  final DateTime createdAt;

  Workout({
    required this.id,
    required this.userId,
    this.weeklyPlanId,
    required this.scheduledDate,
    required this.workoutType,
    this.status = 'planned',
    required this.estimatedDurationMin,
    this.actualDurationMin,
    this.completedAt,
    this.userNotes,
    this.recommendationType,
    this.recommendationReason,
    required this.createdAt,
  });
}
```

#### Workout Exercise (Subcollection)

```dart
// Collection: workouts/{workoutId}/exercises/{exerciseLogId}
class WorkoutExercise {
  final String id;
  final String exerciseId;
  final int order;

  final String? supersetPairId;    // Groups exercises in same superset

  final int sets;
  final int repsPerSet;
  final double? weightKg;

  final int? actualSets;
  final List<int>? actualReps;
  final List<double>? actualWeight;

  final int restSeconds;

  final List<String> primaryMusclesTargeted;
  final int estimatedLoadScore;

  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.order,
    this.supersetPairId,
    required this.sets,
    required this.repsPerSet,
    this.weightKg,
    this.actualSets,
    this.actualReps,
    this.actualWeight,
    required this.restSeconds,
    required this.primaryMusclesTargeted,
    required this.estimatedLoadScore,
  });
}
```

#### Progress Snapshot

```dart
// Collection: progress_snapshots/{snapshotId}
class ProgressSnapshot {
  final String id;
  final String userId;
  final DateTime snapshotDate;

  // Running metrics
  final double? weeklyDistanceKm;
  final int? avgPaceSecKm;
  final int? avgHr;
  final int runSessionsWeek;

  // Strength metrics
  final int strengthSessionsWeek;
  final double? totalVolumeLoad;
  final double? boneDensityWeekly;

  // Health metrics
  final double? weightKg;
  final int? restingHr;
  final double? sleepHours;
  final int? dailySteps;

  // Calculated scores
  final int? recoveryScore;        // 0-100
  final int? injuryRiskScore;      // 0-100
  final int? progressScore;        // 0-100

  final DateTime createdAt;

  ProgressSnapshot({
    required this.id,
    required this.userId,
    required this.snapshotDate,
    this.weeklyDistanceKm,
    this.avgPaceSecKm,
    this.avgHr,
    this.runSessionsWeek = 0,
    this.strengthSessionsWeek = 0,
    this.totalVolumeLoad,
    this.boneDensityWeekly,
    this.weightKg,
    this.restingHr,
    this.sleepHours,
    this.dailySteps,
    this.recoveryScore,
    this.injuryRiskScore,
    this.progressScore,
    required this.createdAt,
  });
}
```

#### Injury Risk Assessment

```dart
// Collection: injury_risk_assessments/{assessmentId}
class InjuryRiskAssessment {
  final String id;
  final String userId;
  final DateTime assessmentDate;

  final int riskScore;             // 0-100
  final String riskLevel;          // 'low', 'moderate', 'high' (see _determineRiskLevel)

  final int? loadSpikeScore;
  final int? muscleImbalanceScore;
  final int? recoveryScore;
  final int? sleepScore;
  final int? restingHrScore;
  final int? restDayScore;

  final List<RiskFactor> riskFactors;
  final List<String> recommendations;

  final DateTime createdAt;

  InjuryRiskAssessment({
    required this.id,
    required this.userId,
    required this.assessmentDate,
    required this.riskScore,
    required this.riskLevel,
    this.loadSpikeScore,
    this.muscleImbalanceScore,
    this.recoveryScore,
    this.sleepScore,
    this.restingHrScore,
    this.restDayScore,
    this.riskFactors = const [],
    this.recommendations = const [],
    required this.createdAt,
  });
}

class RiskFactor {
  final String factor;
  final String severity;
  final dynamic value;
  final String message;

  RiskFactor({
    required this.factor,
    required this.severity,
    required this.value,
    required this.message,
  });
}
```

---

## 4. Flutter Project Structure

```
lib/
├── main.dart
├── firebase_options.dart           # Generated by FlutterFire CLI
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── equipment.dart
│   │   └── muscle_groups.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── colors.dart
│   │   └── text_styles.dart
│   │
│   └── utils/
│       ├── date_helpers.dart
│       ├── duration_formatters.dart
│       └── pace_calculator.dart
│
├── data/
│   ├── models/                     # Data classes
│   │   ├── user_profile.dart
│   │   ├── workout.dart
│   │   ├── workout_exercise.dart
│   │   ├── exercise.dart
│   │   ├── training_goal.dart
│   │   ├── progress_snapshot.dart
│   │   ├── injury_risk_assessment.dart
│   │   └── personal_record.dart
│   │
│   ├── services/                   # Firebase services
│   │   ├── auth_service.dart
│   │   ├── user_service.dart
│   │   ├── workout_service.dart
│   │   ├── exercise_service.dart
│   │   ├── plan_service.dart
│   │   └── progress_service.dart
│   │
│   └── repositories/               # Data abstraction layer
│       ├── user_repository.dart
│       ├── workout_repository.dart
│       └── exercise_repository.dart
│
├── logic/                          # Business logic
│   ├── workout_generator.dart      # Core workout generation algorithm
│   ├── injury_risk_calculator.dart
│   ├── recommendation_engine.dart
│   └── pace_calculator.dart
│
├── features/                       # Feature-based UI structure
│   │
│   ├── auth/
│   │   ├── auth_page.dart
│   │   ├── login_form.dart
│   │   └── register_form.dart
│   │
│   ├── dashboard/
│   │   ├── dashboard_page.dart
│   │   ├── today_summary_card.dart
│   │   ├── upcoming_workouts_list.dart
│   │   └── goal_progress_card.dart
│   │
│   ├── calendar/
│   │   ├── calendar_page.dart
│   │   ├── month_view.dart
│   │   ├── week_view.dart
│   │   └── workout_card.dart
│   │
│   ├── workout/
│   │   ├── workout_detail_page.dart
│   │   ├── workout_player_page.dart
│   │   ├── exercise_card.dart
│   │   ├── rest_timer_widget.dart
│   │   └── workout_complete_page.dart
│   │
│   ├── progress/
│   │   ├── progress_page.dart
│   │   ├── pace_trend_chart.dart
│   │   ├── volume_chart.dart
│   │   ├── muscle_balance_radar.dart
│   │   └── personal_records_list.dart
│   │
│   ├── injury_prevention/
│   │   ├── injury_prevention_page.dart
│   │   ├── risk_score_gauge.dart
│   │   ├── risk_factors_list.dart
│   │   └── muscle_recovery_grid.dart
│   │
│   ├── goals/
│   │   ├── goals_page.dart
│   │   ├── goal_selection_page.dart
│   │   └── goal_progress_page.dart
│   │
│   └── settings/
│       ├── settings_page.dart
│       ├── profile_form.dart
│       └── preferences_form.dart
│
├── shared/                         # Shared widgets
│   ├── widgets/
│   │   ├── loading_spinner.dart
│   │   ├── error_message.dart
│   │   ├── custom_button.dart
│   │   ├── date_picker.dart
│   │   └── duration_picker.dart
│   │
│   └── providers/
│       ├── auth_provider.dart
│       ├── user_provider.dart
│       └── workout_provider.dart
│
└── router/
    └── app_router.dart             # GoRouter configuration
```

---

## 5. Firebase Services

### 5.1 Auth Service (Single User - Auto Login)

> The app uses a single Firebase Auth account. No signup flow is needed — the user is auto-logged in on app start with stored credentials. The `signUp` method exists only for initial account creation.

```dart
// lib/data/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Auto-login with stored credentials on app start.
  /// Called from main.dart before runApp().
  Future<void> autoLogin({
    required String email,
    required String password,
  }) async {
    if (_auth.currentUser != null) return; // Already logged in
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// One-time account creation (run manually, not in app flow).
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
      'goal10kTimeSec': 3600, // Default: 60 min
      'strengthFrequency': 3,
      'runFrequency': 2,
      'availableEquipment': ['dumbbells'],
      'preferredRunDays': ['tuesday', 'thursday'],
    });

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

### 5.2 Workout Service

```dart
// lib/data/services/workout_service.dart
class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Workout>> getWorkoutsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _firestore
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Workout.fromFirestore(doc))
            .toList());
  }

  Future<String> createWorkout(Workout workout) async {
    final docRef = await _firestore.collection('workouts').add(workout.toFirestore());
    return docRef.id;
  }

  Future<void> updateWorkout(String workoutId, Map<String, dynamic> data) async {
    await _firestore.collection('workouts').doc(workoutId).update(data);
  }

  Future<void> completeWorkout(
    String workoutId, {
    required int actualDurationMin,
    String? userNotes,
  }) async {
    await updateWorkout(workoutId, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'actualDurationMin': actualDurationMin,
      if (userNotes != null) 'userNotes': userNotes,
    });
  }

  Future<List<WorkoutExercise>> getWorkoutExercises(String workoutId) async {
    final snapshot = await _firestore
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => WorkoutExercise.fromFirestore(doc))
        .toList();
  }
}
```

### 5.3 Exercise Service

```dart
// lib/data/services/exercise_service.dart
class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Exercise>> getAllExercises() async {
    final snapshot = await _firestore.collection('exercises').get();
    return snapshot.docs
        .map((doc) => Exercise.fromFirestore(doc))
        .toList();
  }

  Future<List<Exercise>> getExercisesByEquipment(List<String> equipment) async {
    final snapshot = await _firestore
        .collection('exercises')
        .where('equipment', whereIn: equipment)
        .get();

    return snapshot.docs
        .map((doc) => Exercise.fromFirestore(doc))
        .toList();
  }

  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) async {
    final snapshot = await _firestore
        .collection('exercises')
        .where('primaryMuscles', arrayContains: muscleGroup)
        .get();

    return snapshot.docs
        .map((doc) => Exercise.fromFirestore(doc))
        .toList();
  }
}
```

---

## 6. Workout Generation Algorithm

> **NOT IMPLEMENTED.** The `lib/logic/` directory does not exist. Workouts currently use hardcoded static exercise lists. The algorithm below is the **target design**.

### 6.1 Core Generator

```dart
// lib/logic/workout_generator.dart
class WorkoutGenerator {
  final List<Exercise> exerciseCatalog;
  final UserProfile user;
  final TrainingGoal goal;

  WorkoutGenerator({
    required this.exerciseCatalog,
    required this.user,
    required this.goal,
  });

  Workout generateStrengthWorkout({
    required String type,           // 'upper', 'lower', 'full'
    required DateTime scheduledDate,
    required int weekNumber,
  }) {
    // Get exercises filtered by user's equipment
    final availableExercises = exerciseCatalog
        .where((e) => user.availableEquipment.contains(e.equipment))
        .toList();

    // Select exercises based on workout type
    final selectedExercises = _selectExercisesForType(type, availableExercises);

    // Create supersets
    final supersets = _createSupersets(selectedExercises);

    // Build workout exercises list
    final workoutExercises = _buildWorkoutExercises(supersets);

    // Calculate estimated duration
    final duration = _estimateDuration(workoutExercises);

    return Workout(
      id: '', // Will be set by Firestore
      userId: user.id,
      scheduledDate: scheduledDate,
      workoutType: 'strength_$type',
      estimatedDurationMin: duration,
      createdAt: DateTime.now(),
    );
  }

  List<Exercise> _selectExercisesForType(String type, List<Exercise> available) {
    switch (type) {
      case 'upper':
        return available
            .where((e) => e.primaryMuscles.any((m) =>
                ['chest', 'back', 'shoulders', 'biceps', 'triceps'].contains(m)))
            .toList();
      case 'lower':
        return available
            .where((e) => e.primaryMuscles.any((m) =>
                ['quadriceps', 'hamstrings', 'glutes', 'calves'].contains(m)))
            .toList();
      case 'full':
        return available;
      default:
        return available;
    }
  }

  List<SupersetPair> _createSupersets(List<Exercise> exercises) {
    // Group exercises into antagonist pairs for supersets
    // e.g., chest/back, quads/hamstrings, biceps/triceps
    final pairs = <SupersetPair>[];

    // Implementation of superset pairing logic...
    // This ensures no repeated workout in 4-week cycle

    return pairs;
  }

  int _estimateDuration(List<WorkoutExercise> exercises) {
    // Sum of: (sets × (reps_time + rest_time)) for all exercises
    int totalSeconds = 0;
    for (final ex in exercises) {
      final setTime = ex.repsPerSet * 4; // ~4 sec per rep
      final restTime = ex.restSeconds;
      totalSeconds += ex.sets * (setTime + restTime);
    }
    return (totalSeconds / 60).round();
  }
}
```

### 6.2 Weekly Plan Generator

```dart
// lib/logic/plan_generator.dart
class WeeklyPlanGenerator {
  final WorkoutGenerator workoutGenerator;
  final UserProfile user;
  final TrainingGoal goal;

  WeeklyPlanGenerator({
    required this.workoutGenerator,
    required this.user,
    required this.goal,
  });

  Future<WeeklyPlan> generateWeek({
    required int weekNumber,
    required int year,
    required DateTime startDate,
  }) async {
    final workouts = <Workout>[];
    final planId = const Uuid().v4();

    // Determine phase based on goal and timeline
    final phase = _determinePhase(weekNumber);

    // Generate strength workouts
    for (var i = 0; i < user.strengthFrequency; i++) {
      final type = _getStrengthType(i, user.strengthFrequency);
      final date = _getNextStrengthDate(startDate, i);

      final workout = workoutGenerator.generateStrengthWorkout(
        type: type,
        scheduledDate: date,
        weekNumber: weekNumber,
      );

      workouts.add(workout);
    }

    // Generate running workouts
    for (var i = 0; i < user.runFrequency; i++) {
      final type = _getRunType(i, weekNumber, phase);
      final date = _getNextRunDate(startDate, i);

      final workout = _generateRunWorkout(
        type: type,
        scheduledDate: date,
        weekNumber: weekNumber,
      );

      workouts.add(workout);
    }

    // Save workouts to Firestore
    for (final workout in workouts) {
      await _workoutService.createWorkout(workout);
    }

    return WeeklyPlan(
      id: planId,
      userId: user.id,
      weekNumber: weekNumber,
      year: year,
      phase: phase,
      mesocycle: _calculateMesocycle(weekNumber),
      createdAt: DateTime.now(),
    );
  }

  String _determinePhase(int weekNumber) {
    // Periodization logic
    if (weekNumber <= 4) return 'base';
    if (weekNumber <= 8) return 'build';
    if (weekNumber <= 12) return 'peak';
    return 'recover';
  }
}
```

---

## 7. Injury Risk Calculation

> **NOT IMPLEMENTED.** No injury risk code exists. The calculator below is the **target design**.

```dart
// lib/logic/injury_risk_calculator.dart
class InjuryRiskCalculator {
  final List<Workout> recentWorkouts;
  final List<ProgressSnapshot> recentSnapshots;
  final Map<String, int> muscleRecoveryStatus;

  InjuryRiskCalculator({
    required this.recentWorkouts,
    required this.recentSnapshots,
    required this.muscleRecoveryStatus,
  });

  InjuryRiskAssessment calculate() {
    final factors = <RiskFactor>[];

    // 1. Training Load Spike (ACWR)
    final acwr = _calculateACWR();
    if (acwr > 1.5) {
      factors.add(RiskFactor(
        factor: 'training_load_spike',
        severity: 'high',
        value: acwr,
        message: 'Training load increased ${(acwr - 1) * 100}% from average',
      ));
    }

    // 2. Muscle Imbalance
    final imbalances = _detectMuscleImbalances();
    if (imbalances.isNotEmpty) {
      factors.add(RiskFactor(
        factor: 'muscle_imbalance',
        severity: imbalances.length > 2 ? 'high' : 'medium',
        value: imbalances,
        message: 'Imbalances: ${imbalances.keys.join(", ")}',
      ));
    }

    // 3. Recovery Score
    final recoveryScore = _calculateRecoveryScore();
    if (recoveryScore < 40) {
      factors.add(RiskFactor(
        factor: 'inadequate_recovery',
        severity: 'high',
        value: recoveryScore,
        message: 'Recovery score is critically low',
      ));
    }

    // 4. Rest Days
    final daysSinceRest = _daysSinceLastRestDay();
    if (daysSinceRest > 10) {
      factors.add(RiskFactor(
        factor: 'no_rest_day',
        severity: 'high',
        value: daysSinceRest,
        message: 'No rest day in $daysSinceRest days',
      ));
    }

    // Calculate overall risk score
    final riskScore = _calculateOverallScore(factors);
    final riskLevel = _determineRiskLevel(riskScore);

    return InjuryRiskAssessment(
      id: '',
      userId: '',
      assessmentDate: DateTime.now(),
      riskScore: riskScore,
      riskLevel: riskLevel,
      riskFactors: factors,
      recommendations: _generateRecommendations(factors),
      createdAt: DateTime.now(),
    );
  }

  double _calculateACWR() {
    // Acute:Chronic Workload Ratio
    // This week's load / 4-week average load
    // Implementation...
    return 1.0;
  }

  int _calculateOverallScore(List<RiskFactor> factors) {
    const weights = {
      'training_load_spike': 0.25,
      'muscle_imbalance': 0.20,
      'inadequate_recovery': 0.20,
      'poor_sleep': 0.15,
      'high_resting_hr': 0.10,
      'no_rest_day': 0.10,
    };

    double score = 0;
    for (final factor in factors) {
      final weight = weights[factor.factor] ?? 0.10;
      final severityScore = factor.severity == 'high' ? 100 :
                           factor.severity == 'medium' ? 60 : 30;
      score += weight * severityScore;
    }

    return (score.clamp(0, 100)).toInt();
  }

  String _determineRiskLevel(int score) {
    if (score > 70) return 'high';
    if (score > 40) return 'moderate';
    return 'low';
  }
}
```

---

## 8. Firestore Security Rules

> **Simple rules for a single-user personal app.** Only requirement: must be authenticated. No per-document ownership checks needed since there's only one user.

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Single-user app: any authenticated user can read/write everything
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

> **NOTE:** The previous per-collection rules with `request.auth.uid` ownership checks were over-engineered for a single-user app. If the app ever goes multi-user, revisit this.

---

## 8.5 Required Firestore Indexes

The following composite indexes are required for the queries in this design. Firestore does **not** create these automatically.

| Collection | Fields | Query Using It |
|------------|--------|----------------|
| `workouts` | `userId` (ASC), `scheduledDate` (ASC) | `getWorkoutsByDateRange()` |
| `training_goals` | `userId` (ASC), `status` (ASC) | Active goals query |
| `progress_snapshots` | `userId` (ASC), `snapshotDate` (DESC) | Recent snapshots query |

Create in Firebase Console → Firestore → Indexes, or Firestore will auto-prompt on first failed query.

---

## 9. Implementation Phases

| Phase | What to Build | Time | Priority | Status |
|-------|---------------|------|----------|--------|
| **1A** | Flutter project, Firebase setup, auth | Week 1 | HIGH | DONE |
| **1B** | Exercise catalog, workout generator | Week 2 | HIGH | NOT STARTED |
| **1C** | Calendar view, workout display | Week 3 | HIGH | PARTIAL (month view only) |
| **2** | Running workouts, muscle visualization | Weeks 4-5 | HIGH | NOT STARTED |
| **3** | Workout player, tracking | Weeks 5-6 | MEDIUM | NOT STARTED |
| **4** | ~~Garmin integration~~ | ~~Weeks 7-8~~ | ~~MEDIUM~~ | REMOVED FROM SCOPE |
| **5** | Progress tracking, charts | Weeks 9-10 | MEDIUM | NOT STARTED |
| **6** | Injury prevention system | Weeks 11-12 | LOW | NOT STARTED |
| **7** | Smart recommendations | Weeks 13-14 | LOW | NOT STARTED |

---

## 10. Cost Estimate

### Single User (Personal App)

| Service | Usage | Free Tier | Monthly Cost |
|---------|-------|-----------|--------------|
| **Firestore** | <500MB, <50K reads/day | ✅ Free | $0 |
| **Firebase Auth** | 1 user | ✅ Free | $0 |
| **Firebase Hosting** | <10GB bandwidth | ✅ Free | $0 |
| **Firebase Storage** | <5GB | ✅ Free | $0 |
| **TOTAL** | | | **$0/month** |

> **Watch out:** Real-time `snapshots()` listeners consume reads continuously. Monitor usage in Firebase Console if queries feel slow.
> **NOTE:** `firebase_storage` is listed in `pubspec.yaml` but never imported or used anywhere in the codebase. Remove if not needed, or use it for exercise images.

---

## 11. Deployment

### Initial Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure

# Run locally
flutter run -d chrome

# Build for web
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Firebase Console Setup

1. Create Firebase project at https://console.firebase.google.com
2. Enable Authentication (Email/Password only)
3. Create Firestore database (start in test mode)
4. Enable Storage
5. Register web app and copy config
6. Deploy security rules from Section 8

---

## 12. Key Files to Create First

### Phase 1A Checklist:
- [x] `lib/main.dart` - App entry point
- [x] `lib/firebase_options.dart` - Firebase config
- [x] `lib/data/services/auth_service.dart`
- [ ] `lib/data/services/user_service.dart`
- [x] `lib/data/models/user_profile.dart`
- [x] `lib/features/auth/auth_page.dart`
- [x] `lib/features/dashboard/dashboard_page.dart`
- [x] `lib/router/app_router.dart`

### Phase 1B Checklist:
- [x] `lib/data/models/exercise.dart`
- [x] `lib/data/models/workout.dart`
- [x] `lib/data/services/exercise_service.dart`
- [x] `lib/data/services/workout_service.dart`
- [ ] `lib/logic/workout_generator.dart`
- [x] `lib/features/calendar/calendar_page.dart` (month view only)
- [x] Seed exercises to Firestore (10 of 37+ done)

---

*Last updated: April 18, 2026*
*Architecture: Flutter + Firebase (Serverless, single user)*
*Target: Personal use, $0/month*
*Note: `docs/RunForge-Design-Document.md` (v1.0) is superseded — should be archived*
