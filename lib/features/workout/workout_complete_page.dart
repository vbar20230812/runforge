import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/exercise_baseline.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/services/baseline_service.dart';
import '../../data/services/workout_service.dart';
import '../../shared/providers/active_workout_provider.dart';
import '../../shared/providers/workout_provider.dart';

class WorkoutCompletePage extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutCompletePage({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutCompletePage> createState() => _WorkoutCompletePageState();
}

class _WorkoutCompletePageState extends ConsumerState<WorkoutCompletePage> {
  List<ExerciseBaseline>? _baselines;
  List<WorkoutExercise>? _exercises;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final workoutService = WorkoutService();
      final baselineService = BaselineService();

      final exercises = await workoutService.getWorkoutExercises(widget.workoutId);
      final workoutAsync = ref.read(workoutByIdProvider(widget.workoutId));

      String? userId;
      workoutAsync.whenOrNull(data: (w) => userId = w?.userId);

      List<ExerciseBaseline> baselines = [];
      if (userId != null) {
        baselines = await baselineService.getAllBaselines(userId!);
      }

      if (mounted) {
        setState(() {
          _exercises = exercises.where((e) => e.exerciseType != 'cardio_burst').toList();
          _baselines = baselines;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(workoutByIdProvider(widget.workoutId));
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

          final durationMin = workout.actualDurationMin ?? 0;
          final exercisesCompleted = activeState?.setLogs.entries
                  .where((e) => e.value.any((log) => log.completed))
                  .length ??
              0;
          final totalExercises = activeState?.setLogs.length ?? 0;

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

                // Baseline comparison
                _buildBaselineComparison(context),

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

  Widget _buildBaselineComparison(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_exercises == null || _exercises!.isEmpty || _baselines == null) {
      return const SizedBox.shrink();
    }

    final baselineMap = <String, ExerciseBaseline>{};
    for (final b in _baselines!) {
      baselineMap[b.exerciseId] = b;
    }

    // Only show exercises that have actual data
    final exercisesWithActuals = _exercises!.where((e) =>
        e.actualReps != null && e.actualReps!.isNotEmpty).toList();

    if (exercisesWithActuals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Baseline',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Baselines will be established as you complete workouts.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Baseline Progress',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...exercisesWithActuals.map((ex) {
              final baseline = baselineMap[ex.exerciseId];
              final isBaselineSet = baseline != null &&
                  baseline.baselineWeightKg != null;
              final sessionWeight = ex.actualWeight != null &&
                      ex.actualWeight!.isNotEmpty
                  ? ex.actualWeight!.reduce((a, b) => a + b) /
                      ex.actualWeight!.length
                  : 0.0;
              final baselineWeight =
                  baseline?.baselineWeightKg ?? 0.0;
              final delta = isBaselineSet && baselineWeight > 0
                  ? ((sessionWeight - baselineWeight) / baselineWeight * 100)
                      .round()
                  : null;
              final improved = delta != null && delta > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ex.exerciseId.replaceAll('_', ' ').split(' ').map(
                            (w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isBaselineSet)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Baseline Set',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.blue)),
                      )
                    else ...[
                      Text(
                        '${baselineWeight.toStringAsFixed(1)}kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sessionWeight.toStringAsFixed(1)}kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (delta != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          improved ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: improved ? Colors.green : Colors.orange,
                        ),
                        Text(
                          '${improved ? '+' : ''}$delta%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: improved ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
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
}
