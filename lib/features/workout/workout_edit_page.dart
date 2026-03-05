import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/workout.dart';
import '../../data/services/workout_service.dart';

class WorkoutEditPage extends StatefulWidget {
  final String workoutId;

  const WorkoutEditPage({super.key, required this.workoutId});

  @override
  State<WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends State<WorkoutEditPage> {
  final WorkoutService _workoutService = WorkoutService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  TimeOfDay? _selectedTime;
  bool _isLoading = true;
  Workout? _workout;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadWorkout();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkout() async {
    final workout = await _workoutService.workoutStream(widget.workoutId).first;
    if (mounted && workout != null) {
      setState(() {
        _workout = workout;
        _notesController.text = workout.userNotes ?? '';
        _selectedTime = TimeOfDay.fromDateTime(workout.scheduledDate);
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final newDate = DateTime(
      _workout!.scheduledDate.year,
      _workout!.scheduledDate.month,
      _workout!.scheduledDate.day,
      _selectedTime?.hour ?? 0,
      _selectedTime?.minute ?? 0,
    );

    await _workoutService.updateWorkout(widget.workoutId, {
      'scheduledDate': newDate,
      'userNotes': _notesController.text.isEmpty ? null : _notesController.text,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout updated')),
      );
      context.pop();
    }
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _workoutService.skipWorkout(widget.workoutId, reason: 'Deleted');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Workout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Workout')),
        body: const Center(child: Text('Workout not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            onPressed: _deleteWorkout,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(_formatWorkoutType(_workout!.workoutType)),
                      subtitle: Text('${_workout!.estimatedDurationMin} min'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(_selectedTime?.format(context) ?? 'Not set'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectTime,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Add notes about this workout...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWorkoutType(String type) {
    return type.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' - ');
  }
}
