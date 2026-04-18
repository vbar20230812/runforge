import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_exercise.dart';
import '../../data/services/exercise_image_service.dart' show ExerciseImageService, ExerciseInfoResult;
import '../../data/services/exercise_service.dart';
import '../../data/services/workout_service.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final String workoutId;

  const ActiveWorkoutPage({super.key, required this.workoutId});

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  final WorkoutService _workoutService = WorkoutService();
  final ExerciseService _exerciseService = ExerciseService();
  final ExerciseImageService _imageService = ExerciseImageService();
  Workout? _workout;
  List<WorkoutExercise> _exercises = [];
  final Map<String, String?> _exerciseImages = {};
  final Map<String, String> _exerciseNames = {};
  final Map<String, String?> _exerciseDescriptions = {};
  int _currentExerciseIndex = 0;
  DateTime? _startTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    try {
    final workout = await _workoutService.workoutStream(widget.workoutId).first;
    final exercises = await _workoutService.getWorkoutExercises(widget.workoutId);

    // Fetch images and names for all exercises
    final imageFutures = <String, Future<ExerciseInfoResult?>>{};
    for (final ex in exercises) {
      final exercise = await _exerciseService.getExercise(ex.exerciseId);
      if (exercise != null) {
        _exerciseNames[ex.exerciseId] = exercise.name;
        if (exercise.imageSource != null) {
          _exerciseImages[ex.exerciseId] = exercise.imageSource;
        }
        if (exercise.shortDescription != null) {
          _exerciseDescriptions[ex.exerciseId] = exercise.shortDescription;
        }
        if (exercise.imageSource == null) {
          imageFutures[ex.exerciseId] = _imageService.getExerciseInfo(exercise.name);
        }
      }
    }

    // Resolve any API lookups
    final results = await Future.wait(imageFutures.entries.map((e) async {
      final info = await e.value;
      return MapEntry(e.key, info);
    }));

    if (mounted) {
      setState(() {
        _workout = workout;
        _exercises = exercises;
        for (final entry in results) {
          _exerciseImages[entry.key] = entry.value?.imageUrl;
          if (entry.value?.shortDescription != null) {
            _exerciseDescriptions[entry.key] = entry.value!.shortDescription!;
          }
        }
        _startTime = DateTime.now();
        _isLoading = false;
      });
    }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: _exerciseImages[exercise.exerciseId] != null
                  ? CachedNetworkImage(
                      imageUrl: _exerciseImages[exercise.exerciseId]!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildPlaceholderIcon(48),
                      errorWidget: (_, __, ___) => _buildPlaceholderIcon(48),
                    )
                  : _buildPlaceholderIcon(48),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _exerciseNames[exercise.exerciseId] ?? exercise.exerciseId,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (_exerciseDescriptions[exercise.exerciseId] != null) ...[
            const SizedBox(height: 8),
            Text(
              _exerciseDescriptions[exercise.exerciseId]!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

  Widget _buildPlaceholderIcon(double size) {
    return Icon(
      Icons.fitness_center,
      size: size,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
