import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String id;
  final String name;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;
  final String movementType;
  final int difficulty;
  final bool isUnilateral;
  final String? shortDescription;
  final String? instructions;
  final int boneDensityScore;
  final String? imageSource;
  final String? imageSourceEnd; // End position frame
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
    this.shortDescription,
    this.instructions,
    this.boneDensityScore = 50,
    this.imageSource,
    this.imageSourceEnd,
    this.hasAnimation = false,
  });

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      primaryMuscles: List<String>.from(data['primaryMuscles'] ?? []),
      secondaryMuscles: List<String>.from(data['secondaryMuscles'] ?? []),
      equipment: data['equipment'] ?? '',
      movementType: data['movementType'] ?? '',
      difficulty: data['difficulty'] ?? 1,
      isUnilateral: data['isUnilateral'] ?? false,
      instructions: data['instructions'],
      shortDescription: data['shortDescription'],
      boneDensityScore: data['boneDensityScore'] ?? 50,
      imageSource: data['imageSource'],
      imageSourceEnd: data['imageSourceEnd'],
      hasAnimation: data['hasAnimation'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'movementType': movementType,
      'difficulty': difficulty,
      'isUnilateral': isUnilateral,
      'instructions': instructions,
      'shortDescription': shortDescription,
      'boneDensityScore': boneDensityScore,
      'imageSource': imageSource,
      'imageSourceEnd': imageSourceEnd,
      'hasAnimation': hasAnimation,
    };
  }
}
