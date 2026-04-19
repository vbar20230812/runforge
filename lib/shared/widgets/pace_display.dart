import 'package:flutter/material.dart';

class PaceDisplay extends StatelessWidget {
  final int paceSecKm;
  final String? zone;

  const PaceDisplay({super.key, required this.paceSecKm, this.zone});

  @override
  Widget build(BuildContext context) {
    final minutes = paceSecKm ~/ 60;
    final seconds = paceSecKm % 60;
    final paceText = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(paceText, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: _zoneColor(context),
        )),
        if (zone != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _zoneColor(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(zone!.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _zoneColor(context),
            )),
          ),
        ],
      ],
    );
  }

  Color _zoneColor(BuildContext context) {
    switch (zone) {
      case 'easy': return Colors.green;
      case 'long': return Colors.blue;
      case 'tempo': return Colors.orange;
      case 'interval': return Colors.red;
      default: return Theme.of(context).colorScheme.primary;
    }
  }
}
