import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/services/workout_service.dart';
import '../../data/models/workout.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final WorkoutService _workoutService = WorkoutService();
  Map<DateTime, List<Workout>> _workoutEvents = {};
  List<Workout> _selectedDayWorkouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  void _loadWorkouts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final start = DateTime.utc(_focusedDay.year, _focusedDay.month - 1, 1);
    final end = DateTime.utc(_focusedDay.year, _focusedDay.month + 2, 0);

    _workoutService.getWorkoutsByDateRange(userId, start, end).listen((workouts) {
      final Map<DateTime, List<Workout>> events = {};
      for (final workout in workouts) {
        final date = DateTime.utc(
          workout.scheduledDate.year,
          workout.scheduledDate.month,
          workout.scheduledDate.day,
        );
        events.putIfAbsent(date, () => []).add(workout);
      }
      setState(() {
        _workoutEvents = events;
        _updateSelectedDayWorkouts();
      });
    });
  }

  void _updateSelectedDayWorkouts() {
    if (_selectedDay == null) {
      _selectedDayWorkouts = [];
      return;
    }
    final date = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    _selectedDayWorkouts = _workoutEvents[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _updateSelectedDayWorkouts();
              });
            },
            eventLoader: (day) {
              final date = DateTime.utc(day.year, day.month, day.day);
              return _workoutEvents[date] ?? [];
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: (events as List<Workout>).take(3).map((workout) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getWorkoutColor(workout),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _selectedDay != null
                ? _buildSelectedDayContent()
                : const Center(
                    child: Text('Select a day to view workouts'),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'Progress'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 2:
              context.go('/progress');
              break;
          }
        },
      ),
    );
  }

  Color _getWorkoutColor(Workout workout) {
    switch (workout.status) {
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getWorkoutIcon(Workout workout) {
    if (workout.isStrength) return Icons.fitness_center;
    if (workout.isRun) return Icons.directions_run;
    return Icons.sports_gymnastics;
  }

  Widget _buildSelectedDayContent() {
    if (_selectedDayWorkouts.isEmpty) {
      return const Center(
        child: Text('No workouts scheduled for this day'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedDayWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _selectedDayWorkouts[index];
        return Card(
          child: ListTile(
            leading: Icon(
              _getWorkoutIcon(workout),
              color: _getWorkoutColor(workout),
            ),
            title: Text(_formatWorkoutType(workout.workoutType)),
            subtitle: Text(
              '${workout.status.capitalize()} • ${workout.estimatedDurationMin} min',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/workout/${workout.id}'),
          ),
        );
      },
    );
  }

  String _formatWorkoutType(String type) {
    return type.split('-').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' - ');
  }
}

extension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
