import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkoutDetailPage extends StatelessWidget {
  final String workoutId;

  const WorkoutDetailPage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
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
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildExerciseList(context),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () {
            context.push('/workout/$workoutId/active');
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Workout'),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                    Icons.fitness_center,
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
                        'Strength - Upper Body',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Planned • ~30 min',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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
                _buildInfoItem(context, '6', 'Exercises'),
                _buildInfoItem(context, '18', 'Total Sets'),
                _buildInfoItem(context, '30', 'Minutes'),
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

  Widget _buildExerciseList(BuildContext context) {
    final exercises = [
      {'id': 'push_up', 'name': 'Push-Ups', 'sets': 3, 'reps': 12},
      {'id': 'row_dumbbell', 'name': 'Dumbbell Row', 'sets': 3, 'reps': 10},
      {'id': 'overhead_press_dumbbell', 'name': 'Overhead Press', 'sets': 3, 'reps': 10},
      {'id': 'tricep_dips', 'name': 'Tricep Dips', 'sets': 3, 'reps': 12},
      {'id': 'bicep_curls', 'name': 'Bicep Curls', 'sets': 3, 'reps': 12},
      {'id': 'plank', 'name': 'Plank', 'sets': 3, 'reps': 45},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(exercise['name'] as String),
              subtitle: Text('${exercise['sets']} sets × ${exercise['reps']} reps'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/exercise/${exercise['id']}');
              },
            ),
          );
        }),
      ],
    );
  }
}
