import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/active_workout_provider.dart';
import '../../shared/providers/workout_provider.dart';

class WorkoutCompletePage extends ConsumerWidget {
  final String workoutId;

  const WorkoutCompletePage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));
    final activeState = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Complete'),
        automaticallyImplyLeading: false,
      ),
      body: workoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (workout) {
          if (workout == null) {
            return const Center(child: Text('Workout not found'));
          }

          // Compute summary data
          final durationMin = workout.actualDurationMin ?? 0;
          final exercisesCompleted = activeState?.setLogs.entries
                  .where((e) => e.value.any((log) => log.completed))
                  .length ??
              0;
          final totalExercises = activeState?.setLogs.length ?? 0;

          // Compute total volume
          double totalVolume = 0;
          if (activeState != null) {
            for (final entry in activeState.setLogs.entries) {
              for (final log in entry.value) {
                if (log.completed) {
                  totalVolume += log.reps * (log.weight ?? 0);
                }
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Celebration icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Great Job!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),

                // Duration card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          context,
                          '$durationMin',
                          'Minutes',
                          Icons.timer,
                        ),
                        _buildStat(
                          context,
                          '$exercisesCompleted/$totalExercises',
                          'Exercises',
                          Icons.fitness_center,
                        ),
                        _buildStat(
                          context,
                          totalVolume >= 1000
                              ? '${(totalVolume / 1000).toStringAsFixed(1)}k'
                              : totalVolume.toStringAsFixed(0),
                          'Volume (kg)',
                          Icons.bar_chart,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Workout type
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(_formatWorkoutType(workout.workoutType)),
                    subtitle: Text('Scheduled: ${_formatDate(workout.scheduledDate)}'),
                  ),
                ),
                const SizedBox(height: 16),

                // Personal records (placeholder -- actual PR detection
                // would require comparing against previous records)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Personal Records',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'PRs will be shown here when detected during your workout.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes input
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workout Notes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'How did the workout feel?',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) {
                            // Notes are handled by the active workout provider
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Done button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(activeWorkoutProvider.notifier).cancelWorkout();
                      context.go('/');
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
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

  String _formatWorkoutType(String type) {
    return type.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' - ');
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
