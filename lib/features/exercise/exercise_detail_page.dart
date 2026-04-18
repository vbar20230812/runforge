import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/exercise.dart';
import '../../data/services/exercise_service.dart';
import '../../data/services/exercise_image_service.dart';

class ExerciseDetailPage extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailPage({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final ExerciseImageService _imageService = ExerciseImageService();
  Exercise? _exercise;
  String? _imageUrl;
  String? _shortDescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    try {
      final exercise = await _exerciseService.getExercise(widget.exerciseId);
      String? imageUrl = exercise?.imageSource;
      String? shortDescription = exercise?.shortDescription;

      // If no stored imageSource or description, try fetching from free API
      if (exercise != null && (imageUrl == null || shortDescription == null)) {
        final info = await _imageService.getExerciseInfo(exercise.name);
        imageUrl ??= info.imageUrl;
        shortDescription ??= info.shortDescription;
      }

      if (mounted) {
        setState(() {
          _exercise = exercise;
          _imageUrl = imageUrl;
          _shortDescription = shortDescription;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercise')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercise')),
        body: const Center(child: Text('Exercise not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise!.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_shortDescription != null) ...[
              const SizedBox(height: 16),
              _buildShortDescription(),
            ],
            const SizedBox(height: 24),
            _buildMuscleInfo(),
            const SizedBox(height: 24),
            _buildEquipmentInfo(),
            const SizedBox(height: 24),
            if (_exercise!.instructions != null) _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildPlaceholderIcon(),
                        errorWidget: (_, __, ___) => _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _exercise!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildDifficultyIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      Icons.fitness_center,
      size: 40,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildDifficultyIndicator() {
    return Row(
      children: [
        Text(
          'Difficulty: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ...List.generate(5, (index) {
          return Icon(
            index < _exercise!.difficulty ? Icons.star : Icons.star_border,
            size: 16,
            color: Colors.amber,
          );
        }),
      ],
    );
  }

  Widget _buildShortDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _shortDescription!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _buildMuscleInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Muscles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_exercise!.primaryMuscles.isNotEmpty) ...[
              Text(
                'Primary',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exercise!.primaryMuscles.map((muscle) {
                  return Chip(
                    label: Text(_formatMuscleName(muscle)),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (_exercise!.secondaryMuscles.isNotEmpty) ...[
              Text(
                'Secondary',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exercise!.secondaryMuscles.map((muscle) {
                  return Chip(
                    label: Text(_formatMuscleName(muscle)),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equipment & Movement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('Equipment'),
              subtitle: Text(_formatEquipment(_exercise!.equipment)),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.move_down),
              title: const Text('Movement Type'),
              subtitle: Text(_exercise!.movementType),
              contentPadding: EdgeInsets.zero,
            ),
            if (_exercise!.isUnilateral)
              const ListTile(
                leading: Icon(Icons.swap_horiz),
                title: Text('Unilateral'),
                subtitle: Text('Works one side at a time'),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              _exercise!.instructions!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMuscleName(String muscle) {
    return muscle.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatEquipment(String equipment) {
    if (equipment.isEmpty) return 'Bodyweight';
    return equipment.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
