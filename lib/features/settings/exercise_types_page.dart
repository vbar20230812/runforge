import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../shared/providers/exercise_provider.dart';
import '../../shared/widgets/loading_spinner.dart';
import '../../shared/widgets/error_message.dart';
import '../../data/models/exercise.dart';

class ExerciseTypesPage extends ConsumerWidget {
  const ExerciseTypesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Types'),
      ),
      body: exercisesAsync.when(
        loading: () => const LoadingSpinner(message: 'Loading exercises...'),
        error: (error, _) => ErrorMessage(
          message: 'Failed to load exercises: $error',
          onRetry: () => ref.invalidate(exerciseCatalogProvider),
        ),
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: Theme.of(context).disabledColor),
                    const SizedBox(height: 16),
                    Text(
                      'No exercises found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exercises will appear here once seeded.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by primary muscle group
          final grouped = <String, List<Exercise>>{};
          for (final exercise in exercises) {
            final muscle = exercise.primaryMuscles.isNotEmpty
                ? exercise.primaryMuscles.first
                : 'other';
            grouped.putIfAbsent(muscle, () => []).add(exercise);
          }

          // Sort groups alphabetically
          final sortedGroups = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedGroups.length,
            itemBuilder: (context, index) {
              final group = sortedGroups[index];
              final groupExercises = grouped[group]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                    child: Text(
                      _formatMuscleGroup(group),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...groupExercises.map((exercise) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text(exercise.name),
                          subtitle: Text(
                            '${_formatMuscleGroup(exercise.primaryMuscles.join(', '))} | ${_formatLabel(exercise.equipment)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            debugPrint('ExerciseTypesPage: navigating to /exercise/${exercise.id}');
                            context.push('/exercise/${exercise.id}');
                          },
                        ),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatMuscleGroup(String group) {
    return group
        .split(',')
        .map((s) => s.trim().split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '))
        .join(', ');
  }

  String _formatLabel(String value) {
    return value.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}
