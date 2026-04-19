import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/progress_snapshot.dart';
import '../../shared/providers/progress_provider.dart';

/// Phase-to-color mapping for the volume chart bars.
Color _phaseColor(String phase) {
  switch (phase) {
    case 'base':
      return Colors.blue;
    case 'build':
      return Colors.orange;
    case 'peak':
      return Colors.red;
    case 'recover':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

/// Derives a week number from [snapshotDate] relative to a reference point.
/// Falls back to index-based ordering when no absolute week count is available.
int _weekIndex(DateTime snapshotDate, DateTime referenceDate) {
  final diff = snapshotDate.difference(referenceDate).inDays;
  return (diff / 7).floor() + 1;
}

class VolumeChart extends ConsumerWidget {
  const VolumeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(progressSnapshotsProvider);

    return snapshotsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load volume data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (snapshots) {
        final volumeSnapshots = snapshots
            .where((s) => s.totalVolumeLoad != null && s.totalVolumeLoad! > 0)
            .toList();

        if (volumeSnapshots.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No volume data yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete workouts to see volume trends.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Sort chronologically (oldest first).
        volumeSnapshots.sort(
          (a, b) => a.snapshotDate.compareTo(b.snapshotDate),
        );

        // Reference date is the earliest snapshot for relative week numbering.
        final referenceDate = volumeSnapshots.first.snapshotDate;

        // Build bar data.
        final barGroups = <BarChartGroupData>[];
        double maxVolume = 0;

        for (var i = 0; i < volumeSnapshots.length; i++) {
          final snapshot = volumeSnapshots[i];
          final volume = snapshot.totalVolumeLoad!;
          if (volume > maxVolume) maxVolume = volume;

          final weekIdx = _weekIndex(snapshot.snapshotDate, referenceDate);
          final phase = AppConstants.getPhaseForWeek(weekIdx);
          final color = _phaseColor(phase);

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: volume,
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }

        // Compute Y-axis ceiling: round up to next nice interval.
        final yMax = maxVolume * 1.15;
        final yInterval = _niceInterval(yMax);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Volume Load',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Sets x Reps x Weight (kg)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              _PhaseLegend(),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (yMax / yInterval).ceilToDouble() * yInterval,
                    barGroups: barGroups,
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(''),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= volumeSnapshots.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'W${idx + 1}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Padding(
                          padding: EdgeInsets.only(right: 4),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final snapshot = volumeSnapshots[group.x];
                          final weekIdx = _weekIndex(
                            snapshot.snapshotDate,
                            referenceDate,
                          );
                          final phase =
                              AppConstants.getPhaseForWeek(weekIdx);
                          return BarTooltipItem(
                            '${rod.toY.toStringAsFixed(0)} kg\n'
                            '${phase[0].toUpperCase()}${phase.substring(1)} phase',
                            TextStyle(
                              color: Colors.white,
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _VolumeStats(snapshots: volumeSnapshots, referenceDate: referenceDate),
            ],
          ),
        );
      },
    );
  }

  /// Returns a "nice" interval for the Y-axis given the max value.
  double _niceInterval(double maxVal) {
    if (maxVal <= 0) return 100;
    final rough = maxVal / 5;
    final magnitude = rough == 0 ? 1 : rough ~/ 1;
    // Round up to nearest power-of-10 step.
    var step = 10;
    while (step < magnitude) {
      step *= 10;
    }
    // Prefer 2, 5, or 10 multiples.
    if (rough <= step * 0.3) return step * 0.2;
    if (rough <= step * 0.7) return step * 0.5;
    return step.toDouble();
  }
}

/// Small legend showing phase color meanings.
class _PhaseLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final phases = [
      ('Base', Colors.blue),
      ('Build', Colors.orange),
      ('Peak', Colors.red),
      ('Recover', Colors.green),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: phases.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: entry.$2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              entry.$1,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Summary stats below the chart: total volume, average, and best week.
class _VolumeStats extends StatelessWidget {
  final List<ProgressSnapshot> snapshots;
  final DateTime referenceDate;

  const _VolumeStats({
    required this.snapshots,
    required this.referenceDate,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    final volumes = snapshots.map((s) => s.totalVolumeLoad!).toList();
    final total = volumes.fold<double>(0, (sum, v) => sum + v);
    final avg = total / volumes.length;
    final best = volumes.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatPill(label: 'Total', value: '${total.toStringAsFixed(0)} kg'),
                _StatPill(label: 'Avg/Week', value: '${avg.toStringAsFixed(0)} kg'),
                _StatPill(label: 'Best Week', value: '${best.toStringAsFixed(0)} kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
