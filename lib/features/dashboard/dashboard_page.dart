import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/workout_provider.dart';
import '../../data/models/workout.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final userId = ref.watch(userIdProvider);
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weekWorkouts = userId != null
        ? ref.watch(workoutListProvider(DateRange(start: weekStart, end: weekEnd)))
        : null;

    final todayWorkouts = weekWorkouts?.whenOrNull(
      data: (workouts) => workouts.where((w) {
        final d = w.scheduledDate;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('RunForge'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          if (userId != null) ref.invalidate(workoutListProvider(DateRange(start: weekStart, end: weekEnd)));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome${userProfile.whenOrNull(data: (p) => p?.name != null ? ', ${p!.name}!' : '!') ?? '!'}',
                      style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Goal: 10K under ${_formatTime(userProfile.whenOrNull(data: (p) => p?.goal10kTimeSec ?? 3600) ?? 3600)}',
                      style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today section
            Text('Today', style: Theme.of(context).textTheme.titleLarge),
            Text(DateFormat('EEEE, MMMM d').format(today),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),

            if (todayWorkouts != null && todayWorkouts.isNotEmpty)
              ...todayWorkouts.map((w) => _WorkoutListTile(workout: w))
            else
              const Card(child: ListTile(
                leading: Icon(Icons.self_improvement),
                title: Text('Rest day'),
                subtitle: Text('No workouts scheduled for today'),
              )),

            const SizedBox(height: 24),

            // Weekly overview
            Text('This Week', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.directions_run, label: 'Runs', value: _countRuns(weekWorkouts), color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.fitness_center, label: 'Strength', value: _countStrength(weekWorkouts), color: Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.check_circle, label: 'Done', value: _completionRate(weekWorkouts), color: Colors.green)),
              ],
            ),
            const SizedBox(height: 24),

            // Upcoming
            Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            weekWorkouts?.when(
              data: (workouts) {
                final upcoming = workouts.where((w) => w.status == 'planned' && w.scheduledDate.isAfter(today)).take(5).toList();
                if (upcoming.isEmpty) return const Text('No upcoming workouts');
                return Column(children: upcoming.map((w) => _WorkoutListTile(workout: w)).toList());
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Could not load workouts'),
            ) ?? const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    return '$m min';
  }

  String _countRuns(AsyncValue? workouts) {
    if (workouts == null) return '0';
    return workouts.whenOrNull(data: (list) {
      final w = list as List<Workout>;
      final completed = w.where((w) => w.isRun && w.isCompleted).length;
      final total = w.where((w) => w.isRun).length;
      return '$completed/$total';
    }) ?? '0/0';
  }

  String _countStrength(AsyncValue? workouts) {
    if (workouts == null) return '0';
    return workouts.whenOrNull(data: (list) {
      final w = list as List<Workout>;
      final completed = w.where((w) => w.isStrength && w.isCompleted).length;
      final total = w.where((w) => w.isStrength).length;
      return '$completed/$total';
    }) ?? '0/0';
  }

  String _completionRate(AsyncValue? workouts) {
    if (workouts == null) return '0%';
    return workouts.whenOrNull(data: (list) {
      final w = list as List<Workout>;
      if (w.isEmpty) return '0%';
      final pct = (w.where((w) => w.isCompleted).length / w.length * 100).round();
      return '$pct%';
    }) ?? '0%';
  }
}

class _WorkoutListTile extends StatelessWidget {
  final Workout workout;
  const _WorkoutListTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final color = workout.isCompleted ? Colors.green : workout.isSkipped ? Colors.grey : Theme.of(context).colorScheme.primary;
    return Card(
      child: ListTile(
        leading: Icon(workout.isStrength ? Icons.fitness_center : Icons.directions_run, color: color),
        title: Text(_formatType(workout.workoutType)),
        subtitle: Text('${workout.estimatedDurationMin} min'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/workout/${workout.id}'),
      ),
    );
  }

  String _formatType(String type) {
    return type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
