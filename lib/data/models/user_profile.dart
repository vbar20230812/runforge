import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int strengthFrequency;
  final int runFrequency;
  final List<String> availableEquipment;
  final List<String> preferredRunDays;

  // Garmin Integration
  final bool garminConnected;
  final String? garminUserId;
  final DateTime? garminLastSync;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
    this.age,
    this.weightKg,
    this.heightCm,
    this.current10kTimeSec,
    this.goal10kTimeSec = 3600,
    this.strengthFrequency = 3,
    this.runFrequency = 2,
    this.availableEquipment = const ['dumbbells'],
    this.preferredRunDays = const ['tuesday', 'thursday'],
    this.garminConnected = false,
    this.garminUserId,
    this.garminLastSync,
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
      garminConnected: data['garminConnected'] ?? false,
      garminUserId: data['garminUserId'],
      garminLastSync: data['garminLastSync'] != null
          ? (data['garminLastSync'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
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
      'garminConnected': garminConnected,
      'garminUserId': garminUserId,
      'garminLastSync': garminLastSync != null
          ? Timestamp.fromDate(garminLastSync!)
          : null,
    };
  }

  UserProfile copyWith({
    String? name,
    int? age,
    double? weightKg,
    int? heightCm,
    int? current10kTimeSec,
    int? goal10kTimeSec,
    int? strengthFrequency,
    int? runFrequency,
    List<String>? availableEquipment,
    List<String>? preferredRunDays,
  }) {
    return UserProfile(
      id: id,
      email: email,
      createdAt: createdAt,
      name: name ?? this.name,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      current10kTimeSec: current10kTimeSec ?? this.current10kTimeSec,
      goal10kTimeSec: goal10kTimeSec ?? this.goal10kTimeSec,
      strengthFrequency: strengthFrequency ?? this.strengthFrequency,
      runFrequency: runFrequency ?? this.runFrequency,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      preferredRunDays: preferredRunDays ?? this.preferredRunDays,
      garminConnected: garminConnected,
      garminUserId: garminUserId,
      garminLastSync: garminLastSync,
    );
  }
}
