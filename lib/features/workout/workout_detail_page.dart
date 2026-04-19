import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/models/exercise.dart';
import '../../shared/providers/workout_provider.dart';
import '../../shared/providers/exercise_provider.dart';

class WorkoutDetailPage extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailPage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));
    final exercisesAsync = ref.watch(workoutExercisesProvider(workoutId));

    return workoutAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (workout) {
        if (workout == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout')),
            body: const Center(child: Text('Workout not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_formatWorkoutType(workout.workoutType)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.push('/workout/$workoutId/edit');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, workout),
                const SizedBox(height: 24),
                exercisesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading exercises: $e')),
                  data: (exercises) {
                    final catalogAsync = ref.watch(exerciseCatalogProvider);
                    return catalogAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildExerciseList(context, exercises, {}, workout),
                      data: (catalog) {
                        final exerciseMap = <String, Exercise>{};
                        for (final ex in catalog) {
                          exerciseMap[ex.id] = ex;
                        }
                        return _buildExerciseList(context, exercises, exerciseMap, workout);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: workout.isPlanned
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/workout/$workoutId/active');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Workout'),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Workout workout) {
    final statusLabel = _statusLabel(workout.status);
    final statusColor = _statusColor(workout.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    workout.isStrength
                        ? Icons.fitness_center
                        : Icons.directions_run,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatWorkoutType(workout.workoutType),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: statusColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '~${workout.estimatedDurationMin} min',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(context, _formatDate(workout.scheduledDate), 'Date'),
                _buildInfoItem(context, '${workout.estimatedDurationMin}', 'Minutes'),
                _buildInfoItem(
                    context,
                    workout.actualDurationMin != null
                        ? '${workout.actualDurationMin}'
                        : '--',
                    'Actual'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    List<WorkoutExercise> exercises,
    Map<String, Exercise> exerciseMap,
    Workout workout,
  ) {
    if (exercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No exercises configured',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    // Group by superset pairs
    final groups = <List<WorkoutExercise>>[];
    final paired = <String>{};

    for (final ex in exercises) {
      if (ex.supersetPairId != null && !paired.contains(ex.supersetPairId)) {
        final partner = exercises.where(
          (e) => e.supersetPairId == ex.supersetPairId && e.id != ex.id,
        );
        if (partner.isNotEmpty) {
          paired.add(ex.supersetPairId!);
          final pair = [ex, partner.first]..sort((a, b) => a.order.compareTo(b.order));
          groups.add(pair);
          continue;
        }
      }
      if (ex.supersetPairId == null || !paired.contains(ex.supersetPairId)) {
        groups.add([ex]);
      }
    }

    // Calculate bone density score
    int boneDensityScore = 0;
    for (final ex in exercises) {
      final exercise = exerciseMap[ex.exerciseId];
      if (exercise != null) {
        boneDensityScore += exercise.boneDensityScore;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${exercises.length} exercises, ${exercises.fold<int>(0, (sum, e) => sum + e.sets)} total sets',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        ...groups.map((group) {
          final isSuperset = group.length > 1;
          return Column(
            children: [
              if (isSuperset)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, size: 16,
                          color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 4),
                      Text('SUPERSET',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              )),
                    ],
                  ),
                ),
              ...group.map((exercise) {
                final exMeta = exerciseMap[exercise.exerciseId];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSuperset
                          ? Theme.of(context).colorScheme.tertiaryContainer
                          : null,
                      child: Text('${exercise.order}'),
                    ),
                    title: Text(exMeta?.name ?? exercise.exerciseId),
                    subtitle: Text(
                      '${exercise.sets} sets x ${exercise.repsPerSet} reps'
                      '${exercise.weightKg != null ? ' @ ${exercise.weightKg}kg' : ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/exercise/${exercise.exerciseId}');
                    },
                  ),
                );
              }),
              if (isSuperset) const SizedBox(height: 8),
            ],
          );
        }),
        if (boneDensityScore > 0) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.health_and_safety,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Bone Density Score'),
              subtitle: Text(
                'This workout contributes a total bone density score of $boneDensityScore.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Text(
                '$boneDensityScore',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ),
        ],
        if (workout.userNotes != null && workout.userNotes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(workout.userNotes!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatWorkoutType(String type) {
    return type.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' - ');
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'planned':
        return 'Planned';
      case 'completed':
        return 'Completed';
      case 'skipped':
        return 'Skipped';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'planned':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
