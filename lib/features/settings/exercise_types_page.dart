import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/providers/exercise_provider.dart';
import '../../shared/widgets/loading_spinner.dart';
import '../../shared/widgets/error_message.dart';
import '../../data/models/exercise.dart';
import '../../data/services/exercise_image_service.dart';

class ExerciseTypesPage extends ConsumerWidget {
  const ExerciseTypesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
      ),
      body: exercisesAsync.when(
        loading: () => const LoadingSpinner(message: 'Loading exercises...'),
        error: (error, _) => ErrorMessage(
          message: 'Failed to load exercises: $error',
          onRetry: () => ref.invalidate(exerciseCatalogProvider),
        ),
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: Theme.of(context).disabledColor),
                    const SizedBox(height: 16),
                    Text('No exercises found', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Exercises will appear here once seeded.',
                      style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          // Group by primary muscle group
          final grouped = <String, List<Exercise>>{};
          for (final exercise in exercises) {
            final muscle = exercise.primaryMuscles.isNotEmpty
                ? exercise.primaryMuscles.first
                : 'other';
            grouped.putIfAbsent(muscle, () => []).add(exercise);
          }
          final sortedGroups = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedGroups.length,
            itemBuilder: (context, index) {
              final group = sortedGroups[index];
              final groupExercises = grouped[group]!;
              final groupIcon = _muscleIcon(group);
              final groupColor = _muscleColor(group);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: groupColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(groupIcon, color: groupColor, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatMuscleGroup(group),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${groupExercises.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                      ],
                    ),
                  ),
                  ...groupExercises.map((exercise) => _ExerciseCard(exercise: exercise)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _muscleIcon(String muscle) {
    switch (muscle) {
      case 'chest': return Icons.fitness_center;
      case 'back': return Icons.backpack;
      case 'shoulders': return Icons.accessibility_new;
      case 'biceps': return Icons.fitness_center;
      case 'triceps': return Icons.fitness_center;
      case 'core': return Icons.self_improvement;
      case 'quadriceps': return Icons.directions_walk;
      case 'hamstrings': return Icons.directions_run;
      case 'glutes': return Icons.accessibility;
      case 'calves': return Icons.directions_walk;
      default: return Icons.sports_gymnastics;
    }
  }

  Color _muscleColor(String muscle) {
    switch (muscle) {
      case 'chest': return Colors.red;
      case 'back': return Colors.blue;
      case 'shoulders': return Colors.teal;
      case 'biceps': return Colors.orange;
      case 'triceps': return Colors.deepOrange;
      case 'core': return Colors.purple;
      case 'quadriceps': return Colors.indigo;
      case 'hamstrings': return Colors.brown;
      case 'glutes': return Colors.pink;
      case 'calves': return Colors.cyan;
      default: return Colors.grey;
    }
  }

  String _formatMuscleGroup(String group) {
    return group.split(',').map((s) => s.trim().split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')).join(', ');
  }
}

class _ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  final _imageService = ExerciseImageService();
  String? _imageUrl;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final url = await _imageService.searchImageByName(widget.exercise.name);
    if (mounted) {
      setState(() {
        _imageUrl = url;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: _loaded
                ? (_imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.fitness_center, size: 20),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.fitness_center, size: 20),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.fitness_center, size: 20),
                      ))
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
          ),
        ),
        title: Text(ex.name),
        subtitle: Text(
          '${ex.primaryMuscles.map((m) => m[0].toUpperCase() + m.substring(1)).join(', ')} | ${_formatLabel(ex.equipment)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ex.movementType == 'compound')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Compound', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.blue)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Isolation', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/exercise/${ex.id}'),
      ),
    );
  }

  String _formatLabel(String value) =>
      value.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
}
