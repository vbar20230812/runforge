# RunForge

A web-based personal training application for runners targeting 10K goals.

## Features

- **Goal-Driven Training** - All workouts generated toward a specific goal (default: 10K under 1 hour)
- **Smart Workout Recommendations** - AI-powered suggestions based on history and recovery
- **Injury Prevention** - Monitors training load, fatigue, and injury risk factors
- **Garmin Integration** - Sync with Forerunner devices
- **Dynamic Recalculation** - When goal changes, all future workouts are recalculated

## Documentation

- [Design Document](docs/DESIGN.md) - Full architecture and data models
- [Implementation Guide](docs/IMPLEMENTATION.md) - Setup and development guide

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Frontend** | Flutter Web |
| **Database** | Cloud Firestore |
| **Auth** | Firebase Authentication |
| **Storage** | Firebase Storage |
| **Hosting** | Firebase Hosting |
| **Backend** | **None** (Serverless) |

## Architecture

```
┌─────────────────────────────────────────┐
│           FLUTTER WEB APP               │
│  Pages │ Widgets │ Services │ Logic    │
└─────────────────┬───────────────────────┘
                  │ Firebase SDK
                  ▼
┌─────────────────────────────────────────┐
│              FIREBASE                   │
│  Auth │ Firestore │ Storage │ Hosting  │
└─────────────────────────────────────────┘
```

**No backend server** - All logic runs client-side via Firebase SDK.

## Cost

| Users | Monthly Cost |
|-------|-------------|
| ≤10 | **$0** |
| 10-100 | ~$5 |
| 100-1000 | ~$35 |

## Quick Start

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Clone and setup
git clone https://github.com/yourusername/runforge.git
cd runforge

# Get dependencies
flutter pub get

# Configure Firebase
flutterfire configure

# Run locally
flutter run -d chrome

# Deploy
flutter build web
firebase deploy --only hosting
```

## Status

Currently in design phase. Implementation starting soon.

---

*Architecture: Flutter + Firebase (Serverless)*
*Target: ≤10 users, $0/month*
