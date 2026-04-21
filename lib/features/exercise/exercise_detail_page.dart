import 'dart:async';
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
  String? _imageUrlEnd;
  String? _shortDescription;
  bool _isLoadingImage = true;
  bool _showEndPosition = false;
  bool _isAnimating = true;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (widget.exercise.imageSource != null) {
      if (mounted) {
        setState(() {
          _imageUrl = widget.exercise.imageSource;
          _imageUrlEnd = widget.exercise.imageSourceEnd;
          _shortDescription = widget.exercise.shortDescription;
          _isLoadingImage = false;
        });
        _startAnimation();
      }
      return;
    }

    try {
      final imageService = ExerciseImageService();
      final info = await imageService.getExerciseInfo(widget.exercise.name);
      if (mounted) {
        setState(() {
          _imageUrl = info.imageUrl;
          _shortDescription = info.shortDescription ?? widget.exercise.shortDescription;
          _isLoadingImage = false;
        });
        _startAnimation();
      }
    } catch (e) {
      debugPrint('Error loading exercise image: $e');
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  void _startAnimation() {
    if (_imageUrlEnd == null) return;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (mounted && _isAnimating) {
        setState(() => _showEndPosition = !_showEndPosition);
      }
    });
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
            // Hero exercise image with animation
            _buildHeroImage(context, exercise),
            const SizedBox(height: 16),

            // Name + difficulty row
            _buildTitleRow(context, exercise),
            const SizedBox(height: 16),

            // Target muscles — right below the image
            _buildMuscleInfo(context, exercise),
            const SizedBox(height: 16),

            if (_shortDescription != null) ...[
              _buildShortDescription(context),
              const SizedBox(height: 16),
            ],
            _buildEquipmentInfo(context, exercise),
            if (exercise.instructions != null &&
                exercise.instructions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInstructions(context, exercise),
            ],
            if (exercise.boneDensityScore > 0) ...[
              const SizedBox(height: 16),
              _buildBoneDensityScore(context, exercise),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, Exercise exercise) {
    final currentUrl = _showEndPosition && _imageUrlEnd != null
        ? _imageUrlEnd!
        : _imageUrl;
    final hasEndFrame = _imageUrlEnd != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main image area
          Container(
            width: double.infinity,
            height: 220,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: _isLoadingImage
                ? const Center(child: CircularProgressIndicator())
                : currentUrl != null
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: CachedNetworkImage(
                          key: ValueKey(currentUrl),
                          imageUrl: currentUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => _placeholderImage(context),
                          errorWidget: (_, __, ___) => _placeholderImage(context),
                        ),
                      )
                    : _placeholderImage(context),
          ),

          // Controls: Start / End / Animate toggle
          if (hasEndFrame)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _positionButton('Start', !_showEndPosition && !_isAnimating, () {
                    setState(() {
                      _isAnimating = false;
                      _showEndPosition = false;
                    });
                  }),
                  const SizedBox(width: 8),
                  _positionButton('Animate', _isAnimating, () {
                    setState(() => _isAnimating = true);
                    _startAnimation();
                  }),
                  const SizedBox(width: 8),
                  _positionButton('End', _showEndPosition && !_isAnimating, () {
                    setState(() {
                      _isAnimating = false;
                      _showEndPosition = true;
                    });
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _positionButton(String label, bool isActive, VoidCallback onTap) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : null,
        foregroundColor: isActive
            ? Theme.of(context).colorScheme.onPrimary
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _placeholderImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Icon(
        Icons.fitness_center,
        size: 64,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, Exercise exercise) {
    return Row(
      children: [
        Expanded(
          child: Text(
            exercise.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        _buildDifficultyIndicator(context, exercise.difficulty),
      ],
    );
  }

  Widget _buildDifficultyIndicator(BuildContext context, int difficulty) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
