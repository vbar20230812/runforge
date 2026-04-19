import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/services/exercise_image_service.dart';
import '../../shared/providers/active_workout_provider.dart';
import '../../shared/providers/exercise_provider.dart';
import '../../shared/providers/workout_provider.dart';
import '../../shared/widgets/rest_timer_widget.dart';
import '../../shared/widgets/set_logger_widget.dart';

class ActiveWorkoutPage extends ConsumerStatefulWidget {
  final String workoutId;

  const ActiveWorkoutPage({super.key, required this.workoutId});

  @override
  ConsumerState<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends ConsumerState<ActiveWorkoutPage> {
  bool _isInitializing = true;
  String? _initError;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  DateTime? _startedAt;

  final Map<String, String?> _exerciseImages = {};
  final Map<String, String> _exerciseNames = {};

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeWorkout() async {
    try {
      final workoutService = ref.read(workoutServiceProvider);
      final exerciseService = ref.read(exerciseServiceProvider);
      final imageService = ExerciseImageService();

      // Fetch workout
      final workoutStream = workoutService.workoutStream(widget.workoutId);
      Workout? workout;
      await for (final w in workoutStream) {
        workout = w;
        break;
      }

      if (workout == null) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _initError = 'Workout not found';
          });
        }
        return;
      }

      // Fetch exercises
      final exercises = await workoutService.getWorkoutExercises(widget.workoutId);

      // Fetch exercise metadata (names + images)
      for (final ex in exercises) {
        final exercise = await exerciseService.getExercise(ex.exerciseId);
        if (exercise != null) {
          _exerciseNames[ex.exerciseId] = exercise.name;
          if (exercise.imageSource != null) {
            _exerciseImages[ex.exerciseId] = exercise.imageSource;
          } else {
            final info = await imageService.getExerciseInfo(exercise.name);
            if (info.imageUrl != null) {
              _exerciseImages[ex.exerciseId] = info.imageUrl;
            }
          }
        }
      }

      if (!mounted) return;

      // Start the active workout via provider
      ref.read(activeWorkoutProvider.notifier).startWorkout(workout, exercises);

      // Start elapsed timer
      _startedAt = DateTime.now();
      _elapsedSeconds = 0;
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsedSeconds = DateTime.now().difference(_startedAt!).inSeconds;
          });
        }
      });

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Error initializing workout: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = e.toString();
        });
      }
    }
  }

  void _completeSet(int exerciseOrder, int setIndex, WorkoutExercise exercise) {
    final state = ref.read(activeWorkoutProvider);
    if (state == null) return;

    final logs = state.setLogs[exerciseOrder];
    final currentReps = logs != null && setIndex < logs.length ? logs[setIndex].reps : exercise.repsPerSet;
    final currentWeight = logs != null && setIndex < logs.length ? logs[setIndex].weight : exercise.weightKg;

    ref.read(activeWorkoutProvider.notifier).completeSet(
          exerciseOrder,
          setIndex,
          reps: currentReps,
          weight: currentWeight,
        );
  }

  Future<void> _completeWorkout() async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final workoutId = await notifier.completeWorkout();
    _elapsedTimer?.cancel();

    if (workoutId != null && mounted) {
      context.go('/workout/$workoutId/complete');
    }
  }

  void _nextGroup() {
    ref.read(activeWorkoutProvider.notifier).nextGroup();
  }

  void _previousGroup() {
    ref.read(activeWorkoutProvider.notifier).previousGroup();
  }

  Future<void> _showExitConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workout'),
        content: const Text('Your progress will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(activeWorkoutProvider.notifier).cancelWorkout();
      _elapsedTimer?.cancel();
      context.go('/workout/${widget.workoutId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Workout...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Workout')),
        body: Center(child: Text(_initError!)),
      );
    }

    final activeState = ref.watch(activeWorkoutProvider);
    if (activeState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Workout')),
        body: const Center(child: Text('No active workout')),
      );
    }

    final currentGroup = activeState.currentGroup;
    final totalGroups = activeState.groups.length;
    final currentIdx = activeState.currentGroupIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_formatWorkoutType(activeState.workout.workoutType)),
          automaticallyImplyLeading: false,
          actions: [
            // Elapsed time display
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _formatElapsed(_elapsedSeconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _showExitConfirmation,
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(context, currentIdx, totalGroups),
            // Main content
            Expanded(
              child: currentGroup != null
                  ? (currentGroup.isSuperset
                      ? _buildSupersetContent(context, activeState, currentGroup)
                      : _buildSoloContent(context, activeState, currentGroup.exercises.first))
                  : _buildNoExercisesContent(),
            ),
            // Controls
            _buildControls(context, activeState),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, int currentIdx, int totalGroups) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: totalGroups == 0 ? 0 : (currentIdx + 1) / totalGroups,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Block ${currentIdx + 1} of $totalGroups',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                _formatElapsed(_elapsedSeconds),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Solo exercise ──

  Widget _buildSoloContent(
    BuildContext context,
    ActiveWorkoutState activeState,
    WorkoutExercise exercise,
  ) {
    final name = _exerciseNames[exercise.exerciseId] ?? exercise.exerciseId;
    final imageUrl = _exerciseImages[exercise.exerciseId];
    final logs = activeState.setLogs[exercise.order] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Exercise image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(50),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholderIcon(40),
                      errorWidget: (_, __, ___) => _placeholderIcon(40),
                    )
                  : _placeholderIcon(40),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${exercise.sets} sets x ${exercise.repsPerSet} reps'
            '${exercise.weightKg != null ? ' @ ${exercise.weightKg}kg' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Set logger
          ...List.generate(exercise.sets, (i) {
            final log = i < logs.length ? logs[i] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SetLoggerWidget(
                setNumber: i + 1,
                plannedReps: exercise.repsPerSet,
                plannedWeight: exercise.weightKg,
                actualReps: log?.reps,
                actualWeight: log?.weight,
                completed: log?.completed ?? false,
                onRepsChanged: (reps) {
                  // Update reps in the log without completing
                },
                onWeightChanged: (weight) {
                  // Update weight in the log without completing
                },
                onCompleted: () => _completeSet(exercise.order, i, exercise),
              ),
            );
          }),

          // Rest timer
          if (activeState.isTimerRunning && activeState.timerSeconds > 0) ...[
            const SizedBox(height: 16),
            RestTimerWidget(
              durationSeconds: activeState.timerSeconds,
              autoStart: false,
              onComplete: () {
                debugPrint('Rest complete');
              },
            ),
          ] else ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: Text('${exercise.restSeconds}s rest between sets'),
                subtitle: const Text('Timer starts after completing a set'),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Superset ──

  Widget _buildSupersetContent(
    BuildContext context,
    ActiveWorkoutState activeState,
    ExerciseGroup group,
  ) {
    final exercises = group.exercises;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Superset badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 18,
                    color: Theme.of(context).colorScheme.onTertiaryContainer),
                const SizedBox(width: 6),
                Text('SUPERSET',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Alternate: Set 1 of A, then Set 1 of B, etc.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // Each exercise in the superset
          ...exercises.asMap().entries.map((entry) {
            final idx = entry.key;
            final exercise = entry.value;
            final label = idx == 0 ? 'A' : 'B';
            final logs = activeState.setLogs[exercise.order] ?? [];

            return Column(
              children: [
                _buildSupersetExerciseCard(
                  context,
                  exercise,
                  label,
                  logs,
                  activeState,
                ),
                if (idx < exercises.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.swap_vert,
                        color: Theme.of(context).colorScheme.outline),
                  ),
              ],
            );
          }),

          // Rest timer for superset
          if (activeState.isTimerRunning && activeState.timerSeconds > 0) ...[
            const SizedBox(height: 16),
            RestTimerWidget(
              durationSeconds: activeState.timerSeconds,
              autoStart: false,
              onComplete: () {
                debugPrint('Superset rest complete');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupersetExerciseCard(
    BuildContext context,
    WorkoutExercise exercise,
    String label,
    List<SetLog> logs,
    ActiveWorkoutState activeState,
  ) {
    final name = _exerciseNames[exercise.exerciseId] ?? exercise.exerciseId;
    final imageUrl = _exerciseImages[exercise.exerciseId];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _placeholderIcon(22),
                            errorWidget: (_, __, ___) => _placeholderIcon(22),
                          )
                        : _placeholderIcon(22),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _compactStat('${exercise.sets}', 'sets'),
                _compactStat('${exercise.repsPerSet}', 'reps'),
                if (exercise.weightKg != null)
                  _compactStat('${exercise.weightKg}', 'kg'),
                _compactStat('${exercise.restSeconds}s', 'rest'),
              ],
            ),
            const SizedBox(height: 12),

            // Set loggers
            ...List.generate(exercise.sets, (i) {
              final log = i < logs.length ? logs[i] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SetLoggerWidget(
                  setNumber: i + 1,
                  plannedReps: exercise.repsPerSet,
                  plannedWeight: exercise.weightKg,
                  actualReps: log?.reps,
                  actualWeight: log?.weight,
                  completed: log?.completed ?? false,
                  onCompleted: () => _completeSet(exercise.order, i, exercise),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _compactStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }

  // ── No exercises ──

  Widget _buildNoExercisesContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48),
          const SizedBox(height: 16),
          const Text('No exercises configured'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _completeWorkout,
            icon: const Icon(Icons.check),
            label: const Text('Complete Workout'),
          ),
        ],
      ),
    );
  }

  // ── Bottom controls ──

  Widget _buildControls(BuildContext context, ActiveWorkoutState activeState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: activeState.currentGroupIndex > 0
                        ? _previousGroup
                        : null,
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: activeState.isLastGroup
                        ? _completeWorkout
                        : _nextGroup,
                    child: Text(activeState.isLastGroup ? 'Complete' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _placeholderIcon(double size) {
    return Icon(
      Icons.fitness_center,
      size: size,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatWorkoutType(String type) {
    return type.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' - ');
  }
}
