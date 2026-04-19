import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../shared/providers/workout_provider.dart';
import '../../data/models/workout.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.utc(_focusedDay.year, _focusedDay.month - 1, 1);
    final end = DateTime.utc(_focusedDay.year, _focusedDay.month + 2, 0);
    final workoutsAsync = ref.watch(workoutListProvider(DateRange(start: start, end: end)));

    return Scaffold(
      appBar: AppBar(title: const Text('Training Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() { _selectedDay = selected; _focusedDay = focused; });
            },
            availableCalendarFormats: const { CalendarFormat.month: 'Month' },
            eventLoader: (day) {
              final date = DateTime.utc(day.year, day.month, day.day);
              return workoutsAsync.whenOrNull(
                data: (workouts) => workouts.where((w) {
                  final d = w.scheduledDate;
                  return d.year == date.year && d.month == date.month && d.day == date.day;
                }).toList(),
              ) ?? [];
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
                    children: (events as List<Workout>).take(3).map((w) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: w.isCompleted ? Colors.green : w.isRun ? Colors.blue : Theme.of(context).colorScheme.primary,
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
                ? _buildDayWorkouts(workoutsAsync)
                : const Center(child: Text('Select a day to view workouts')),
          ),
        ],
      ),
    );
  }

  Widget _buildDayWorkouts(AsyncValue<List<Workout>> workoutsAsync) {
    return workoutsAsync.when(
      data: (allWorkouts) {
        final dayWorkouts = allWorkouts.where((w) {
          final d = w.scheduledDate;
          return d.year == _selectedDay!.year && d.month == _selectedDay!.month && d.day == _selectedDay!.day;
        }).toList();

        if (dayWorkouts.isEmpty) {
          return const Center(child: Text('No workouts for this day'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dayWorkouts.length,
          itemBuilder: (context, index) {
            final w = dayWorkouts[index];
            final color = w.isCompleted ? Colors.green : w.isSkipped ? Colors.grey : Theme.of(context).colorScheme.primary;
            return Card(
              child: ListTile(
                leading: Icon(w.isStrength ? Icons.fitness_center : Icons.directions_run, color: color),
                title: Text(w.workoutType.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ')),
                subtitle: Text('${w.status[0].toUpperCase()}${w.status.substring(1)} - ${w.estimatedDurationMin} min'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/workout/${w.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
