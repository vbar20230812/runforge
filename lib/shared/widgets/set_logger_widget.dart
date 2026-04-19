import 'package:flutter/material.dart';

class SetLoggerWidget extends StatelessWidget {
  final int setNumber;
  final int plannedReps;
  final double? plannedWeight;
  final int? actualReps;
  final double? actualWeight;
  final bool completed;
  final ValueChanged<int>? onRepsChanged;
  final ValueChanged<double?>? onWeightChanged;
  final VoidCallback? onCompleted;

  const SetLoggerWidget({
    super.key,
    required this.setNumber,
    required this.plannedReps,
    this.plannedWeight,
    this.actualReps,
    this.actualWeight,
    this.completed = false,
    this.onRepsChanged,
    this.onWeightChanged,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: completed ? Colors.green.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text('S$setNumber', style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: Text('$plannedReps reps${plannedWeight != null ? ' @ ${plannedWeight}kg' : ''}',
                style: Theme.of(context).textTheme.bodyMedium),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration.collapsed(hintText: 'Reps'),
                controller: TextEditingController(text: actualReps?.toString()),
                onChanged: (v) => onRepsChanged?.call(int.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration.collapsed(hintText: 'Kg'),
                controller: TextEditingController(text: actualWeight?.toString()),
                onChanged: (v) => onWeightChanged?.call(double.tryParse(v)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(completed ? Icons.check_circle : Icons.circle_outlined,
                color: completed ? Colors.green : null),
              onPressed: onCompleted,
              iconSize: 24,
            ),
          ],
        ),
      ),
    );
  }
}
