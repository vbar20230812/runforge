import 'package:flutter/material.dart';
import '../../data/models/exercise.dart';

class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final String? setsReps;
  final VoidCallback? onTap;

  const ExerciseTile({super.key, required this.exercise, this.setsReps, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          exercise.movementType == 'compound' ? Icons.fitness_center : Icons.accessibility_new,
          size: 20,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(
        setsReps ?? exercise.primaryMuscles.map((m) => m[0].toUpperCase() + m.substring(1)).join(', '),
      ),
      trailing: exercise.difficulty >= 4 ? const Icon(Icons.signal_cellular_alt, size: 16) : null,
      onTap: onTap,
    );
  }
}
