import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exercise.dart';
import '../../data/services/exercise_image_service.dart';
import '../../shared/providers/exercise_provider.dart';

class ExerciseDetailPage extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailPage({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);

    return catalogAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Exercise')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Exercise')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (exercises) {
        final exercise = exercises.where((e) => e.id == exerciseId).firstOrNull;

        if (exercise == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Exercise')),
            body: const Center(child: Text('Exercise not found')),
          );
        }

        return _ExerciseDetailContent(exercise: exercise);
      },
    );
  }
}

class _ExerciseDetailContent extends ConsumerStatefulWidget {
  final Exercise exercise;

  const _ExerciseDetailContent({required this.exercise});

  @override
  ConsumerState<_ExerciseDetailContent> createState() =>
      _ExerciseDetailContentState();
}

class _ExerciseDetailContentState
    extends ConsumerState<_ExerciseDetailContent> {
  String? _imageUrl;
  String? _shortDescription;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    // Use stored image source if available
    if (widget.exercise.imageSource != null) {
      if (mounted) {
        setState(() {
          _imageUrl = widget.exercise.imageSource;
          _shortDescription = widget.exercise.shortDescription;
          _isLoadingImage = false;
        });
      }
      return;
    }

    // Otherwise fetch from the API
    try {
      final imageService = ExerciseImageService();
      final info = await imageService.getExerciseInfo(widget.exercise.name);
      if (mounted) {
        setState(() {
          _imageUrl = info.imageUrl;
          _shortDescription = info.shortDescription ?? widget.exercise.shortDescription;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading exercise image: $e');
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, exercise),
            if (_shortDescription != null) ...[
              const SizedBox(height: 16),
              _buildShortDescription(context),
            ],
            const SizedBox(height: 24),
            _buildMuscleInfo(context, exercise),
            const SizedBox(height: 24),
            _buildEquipmentInfo(context, exercise),
            const SizedBox(height: 24),
            if (exercise.instructions != null &&
                exercise.instructions!.isNotEmpty)
              _buildInstructions(context, exercise),
            if (exercise.boneDensityScore > 0) ...[
              const SizedBox(height: 24),
              _buildBoneDensityScore(context, exercise),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Exercise exercise) {
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
                child: _isLoadingImage
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _placeholderIcon(context),
                            errorWidget: (_, __, ___) =>
                                _placeholderIcon(context),
                          )
                        : _placeholderIcon(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildDifficultyIndicator(context, exercise.difficulty),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    return Icon(
      Icons.fitness_center,
      size: 40,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildDifficultyIndicator(BuildContext context, int difficulty) {
    return Row(
      children: [
        Text(
          'Difficulty: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ...List.generate(5, (index) {
          return Icon(
            index < difficulty ? Icons.star : Icons.star_border,
            size: 16,
            color: Colors.amber,
          );
        }),
      ],
    );
  }

  Widget _buildShortDescription(BuildContext context) {
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

  Widget _buildMuscleInfo(BuildContext context, Exercise exercise) {
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
            if (exercise.primaryMuscles.isNotEmpty) ...[
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
                children: exercise.primaryMuscles.map((muscle) {
                  return Chip(
                    label: Text(_formatName(muscle)),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (exercise.secondaryMuscles.isNotEmpty) ...[
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
                children: exercise.secondaryMuscles.map((muscle) {
                  return Chip(
                    label: Text(_formatName(muscle)),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentInfo(BuildContext context, Exercise exercise) {
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
              subtitle: Text(_formatName(exercise.equipment)),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.move_down),
              title: const Text('Movement Type'),
              subtitle: Text(_formatName(exercise.movementType)),
              contentPadding: EdgeInsets.zero,
            ),
            if (exercise.isUnilateral)
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

  Widget _buildInstructions(BuildContext context, Exercise exercise) {
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
              exercise.instructions!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoneDensityScore(BuildContext context, Exercise exercise) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.health_and_safety,
            color: Theme.of(context).colorScheme.primary),
        title: const Text('Bone Density Score'),
        subtitle: Text(
          'This exercise has a bone density contribution of ${exercise.boneDensityScore}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${exercise.boneDensityScore}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
    );
  }

  String _formatName(String text) {
    if (text.isEmpty) return 'Bodyweight';
    return text.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
