import 'package:flutter/material.dart';
import '../../data/models/workout.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onTap;

  const WorkoutCard({super.key, required this.workout, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    final icon = _typeIcon;

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(_formatType(workout.workoutType)),
        subtitle: Text('${workout.estimatedDurationMin} min'),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    switch (workout.status) {
      case 'completed': return Colors.green;
      case 'skipped': return Colors.grey;
      case 'in_progress': return Colors.orange;
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  IconData get _typeIcon {
    if (workout.isStrength) return Icons.fitness_center;
    if (workout.isRun) return Icons.directions_run;
    return Icons.sports_gymnastics;
  }

  String _formatType(String type) {
    return type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
