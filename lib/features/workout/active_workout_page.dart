import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/services/workout_service.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final String workoutId;

  const ActiveWorkoutPage({super.key, required this.workoutId});

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  final WorkoutService _workoutService = WorkoutService();
  Workout? _workout;
  List<WorkoutExercise> _exercises = [];
  int _currentExerciseIndex = 0;
  DateTime? _startTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    final workout = await _workoutService.workoutStream(widget.workoutId).first;
    final exercises = await _workoutService.getWorkoutExercises(widget.workoutId);

    if (mounted) {
      setState(() {
        _workout = workout;
        _exercises = exercises;
        _startTime = DateTime.now();
        _isLoading = false;
      });
    }
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  Future<void> _completeWorkout() async {
    final duration = DateTime.now().difference(_startTime!).inMinutes;

    await _workoutService.completeWorkout(
      widget.workoutId,
      actualDurationMin: duration,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Workout completed! Duration: $duration min')),
      );
      context.go('/');
    }
  }

  Future<void> _skipWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Workout'),
        content: const Text('Are you sure you want to skip this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _workoutService.skipWorkout(widget.workoutId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout skipped')),
        );
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Workout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Workout')),
        body: const Center(child: Text('Workout not found')),
      );
    }

    final currentExercise = _exercises.isNotEmpty && _currentExerciseIndex < _exercises.length
        ? _exercises[_currentExerciseIndex]
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_formatWorkoutType(_workout!.workoutType)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _showExitConfirmation,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: currentExercise != null
                  ? _buildExerciseContent(currentExercise)
                  : _buildNoExercisesContent(),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: _exercises.isEmpty ? 0 : (_currentExerciseIndex + 1) / _exercises.length,
    );
  }

  Widget _buildExerciseContent(WorkoutExercise exercise) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Exercise ${_currentExerciseIndex + 1} of ${_exercises.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            exercise.exerciseId,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildSetRow('Sets', '${exercise.sets}'),
                  const Divider(),
                  _buildSetRow('Reps', '${exercise.repsPerSet}'),
                  if (exercise.weightKg != null) ...[
                    const Divider(),
                    _buildSetRow('Weight', '${exercise.weightKg} kg'),
                  ],
                  const Divider(),
                  _buildSetRow('Rest', '${exercise.restSeconds} sec'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildControls() {
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
                    onPressed: _currentExerciseIndex > 0 ? _previousExercise : null,
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _currentExerciseIndex < _exercises.length - 1
                        ? _nextExercise
                        : _completeWorkout,
                    child: Text(_currentExerciseIndex < _exercises.length - 1
                        ? 'Next'
                        : 'Complete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _skipWorkout,
              child: const Text('Skip Workout'),
            ),
          ],
        ),
      ),
    );
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
      context.go('/workout/${widget.workoutId}');
    }
  }

  String _formatWorkoutType(String type) {
    return type.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' - ');
  }
}
