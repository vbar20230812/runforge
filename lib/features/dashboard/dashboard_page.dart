import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/workout_provider.dart';
import '../../shared/providers/exercise_provider.dart';
import '../../shared/providers/plan_provider.dart';
import '../../data/models/workout.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/workout_service.dart';
import '../../data/services/plan_service.dart';
import '../../data/services/baseline_service.dart';
import '../../logic/workout_generator.dart';
import '../../logic/plan_generator.dart';
import '../../core/utils/date_helpers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final userId = ref.watch(userIdProvider);
    final today = DateTime.now();
    final weekStart = _dateOnly(today.subtract(Duration(days: today.weekday - 1)));
    final weekEnd = _dateOnly(weekStart.add(const Duration(days: 7))).subtract(const Duration(milliseconds: 1));

    final weekWorkouts = userId != null
        ? ref.watch(workoutListProvider(DateRange(start: weekStart, end: weekEnd)))
        : null;

    final hasWorkouts = weekWorkouts?.whenOrNull(
          data: (workouts) => workouts.isNotEmpty,
        ) ?? false;

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
          if (userId != null) {
            ref.invalidate(workoutListProvider(DateRange(start: weekStart, end: weekEnd)));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome card
            _buildWelcomeCard(userProfile),
            const SizedBox(height: 24),

            // Generate plan button (shown when no workouts exist)
            if (!hasWorkouts && !_isGenerating)
              _buildGeneratePlanButton(userProfile, userId),

            if (_isGenerating)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Generating your training plan...'),
                    ],
                  ),
                ),
              ),

            // Today section
            Text('Today', style: Theme.of(context).textTheme.titleLarge),
            Text('${DateHelpers.formatDay(today)}, ${DateHelpers.formatDate(today)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            _buildTodayWorkouts(weekWorkouts, today),
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
                final upcoming = workouts
                    .where((w) => w.status == 'planned' && w.scheduledDate.isAfter(today))
                    .take(5)
                    .toList();
                if (upcoming.isEmpty) return const Text('No upcoming workouts');
                return Column(children: upcoming.map((w) => _WorkoutListTile(workout: w)).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load workouts: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ) ?? const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(AsyncValue<UserProfile?> userProfile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome${userProfile.whenOrNull(data: (p) => p?.name != null ? ', ${p!.name}!' : '!') ?? '!'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Goal: 10K under ${_formatTime(userProfile.whenOrNull(data: (p) => p?.goal10kTimeSec ?? 3600) ?? 3600)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratePlanButton(AsyncValue<UserProfile?> userProfile, String? userId) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
            const SizedBox(height: 12),
            Text('No training plan yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            )),
            const SizedBox(height: 4),
            Text('Generate a personalized weekly plan based on your goals and preferences.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              )),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: userId != null ? () => _generatePlan(userProfile, userId) : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Generate This Week\'s Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePlan(AsyncValue<UserProfile?> userProfile, String userId) async {
    setState(() => _isGenerating = true);

    try {
      final profile = userProfile.whenOrNull(data: (p) => p);
      if (profile == null) {
        _showError('User profile not found');
        return;
      }

      // Fetch exercises from Firestore
      final exercises = await ref.read(exerciseCatalogProvider.future);
      if (exercises.isEmpty) {
        _showError('No exercises found. Try restarting the app.');
        return;
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekNumber = DateHelpers.weekNumber(now);

      final generator = PlanGenerator(
        workoutGenerator: WorkoutGenerator(
          exerciseCatalog: exercises,
          user: profile,
        ),
        workoutService: WorkoutService(),
        planService: PlanService(),
        baselineService: BaselineService(),
        user: profile,
      );

      await generator.generateWeek(
        weekNumber: weekNumber,
        year: now.year,
        weekStart: weekStart,
      );

      // Refresh providers to show new data
      ref.invalidate(workoutListProvider(DateRange(
        start: weekStart,
        end: weekStart.add(const Duration(days: 6)),
      )));
      ref.invalidate(currentWeekPlanProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Training plan generated!')),
        );
      }
    } catch (e) {
      _showError('Failed to generate plan: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTodayWorkouts(AsyncValue<List<Workout>>? weekWorkouts, DateTime today) {
    final todayWorkouts = weekWorkouts?.whenOrNull(
      data: (workouts) => workouts.where((w) {
        final d = w.scheduledDate;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList(),
    );

    if (todayWorkouts != null && todayWorkouts.isNotEmpty) {
      return Column(children: todayWorkouts.map((w) => _WorkoutListTile(workout: w)).toList());
    }
    return const Card(
      child: ListTile(
        leading: Icon(Icons.self_improvement),
        title: Text('Rest day'),
        subtitle: Text('No workouts scheduled for today'),
      ),
    );
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _formatTime(int seconds) => '${seconds ~/ 60} min';

  String _countRuns(AsyncValue? w) => w?.whenOrNull(data: (list) {
    final workouts = list as List<Workout>;
    return '${workouts.where((w) => w.isRun && w.isCompleted).length}/${workouts.where((w) => w.isRun).length}';
  }) ?? '0/0';

  String _countStrength(AsyncValue? w) => w?.whenOrNull(data: (list) {
    final workouts = list as List<Workout>;
    return '${workouts.where((w) => w.isStrength && w.isCompleted).length}/${workouts.where((w) => w.isStrength).length}';
  }) ?? '0/0';

  String _completionRate(AsyncValue? w) => w?.whenOrNull(data: (list) {
    final workouts = list as List<Workout>;
    if (workouts.isEmpty) return '0%';
    return '${(workouts.where((w) => w.isCompleted).length / workouts.length * 100).round()}%';
  }) ?? '0%';
}

class _WorkoutListTile extends StatelessWidget {
  final Workout workout;
  const _WorkoutListTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final color = workout.isCompleted
        ? Colors.green
        : workout.isSkipped
            ? Colors.grey
            : Theme.of(context).colorScheme.primary;
    return Card(
      child: ListTile(
        leading: Icon(
          workout.isStrength ? Icons.fitness_center : Icons.directions_run,
          color: color,
        ),
        title: Text(_formatType(workout.workoutType)),
        subtitle: Text('${workout.estimatedDurationMin} min'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/workout/${workout.id}'),
      ),
    );
  }

  String _formatType(String type) =>
      type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
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
