import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/progress_provider.dart';
import '../../shared/widgets/loading_spinner.dart';
import '../../shared/widgets/error_message.dart';
import '../../data/models/progress_snapshot.dart';
import '../../data/models/personal_record.dart';
import 'volume_chart.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Strength'),
              Tab(text: 'Records'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _StrengthTab(),
            _RecordsTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(progressSnapshotsProvider);

    return snapshotsAsync.when(
      loading: () => const LoadingSpinner(message: 'Loading progress...'),
      error: (error, _) => ErrorMessage(
        message: 'Failed to load progress: $error',
        onRetry: () => ref.invalidate(progressSnapshotsProvider),
      ),
      data: (snapshots) {
        if (snapshots.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'No progress data yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete workouts to start tracking your progress.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Compute weekly summary from latest snapshot
        final latest = snapshots.first;
        final weekWorkouts = latest.runSessionsWeek + latest.strengthSessionsWeek;
        final totalVolume = latest.totalVolumeLoad ?? 0;
        final adherence = latest.progressScore ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.fitness_center,
                      iconColor: Colors.blue,
                      value: '$weekWorkouts',
                      label: 'Workouts',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.monitor_weight,
                      iconColor: Colors.orange,
                      value: totalVolume > 0 ? totalVolume.toStringAsFixed(0) : '--',
                      label: 'Volume (kg)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      value: '$adherence',
                      label: 'Adherence %',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.directions_run,
                      iconColor: Colors.purple,
                      value: (latest.weeklyDistanceKm ?? 0).toStringAsFixed(1),
                      label: 'Distance (km)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recent Snapshots',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...snapshots.take(5).map((s) => _SnapshotTile(snapshot: s)),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  final ProgressSnapshot snapshot;

  const _SnapshotTile({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final date = snapshot.snapshotDate;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.trending_up, color: Colors.blue),
        title: Text('Snapshot - $dateStr'),
        subtitle: Text(
          'Runs: ${snapshot.runSessionsWeek} | Strength: ${snapshot.strengthSessionsWeek}'
          '${snapshot.totalVolumeLoad != null ? ' | Vol: ${snapshot.totalVolumeLoad!.toStringAsFixed(0)}kg' : ''}',
        ),
      ),
    );
  }
}

class _StrengthTab extends StatelessWidget {
  const _StrengthTab();

  @override
  Widget build(BuildContext context) {
    return const VolumeChart();
  }
}

class _RecordsTab extends ConsumerWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(personalRecordsProvider);

    return recordsAsync.when(
      loading: () => const LoadingSpinner(message: 'Loading records...'),
      error: (error, _) => ErrorMessage(
        message: 'Failed to load records: $error',
        onRetry: () => ref.invalidate(personalRecordsProvider),
      ),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'No personal records yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep training to set your first record!',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _RecordCard(record: record);
          },
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  final PersonalRecord record;

  const _RecordCard({required this.record});

  IconData _typeIcon(String type) {
    switch (type) {
      case 'max_weight':
        return Icons.fitness_center;
      case 'max_reps':
        return Icons.repeat;
      case 'max_volume':
        return Icons.bar_chart;
      case 'fastest_pace':
        return Icons.speed;
      case 'longest_distance':
        return Icons.straighten;
      default:
        return Icons.emoji_events;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'max_weight':
        return 'Max Weight';
      case 'max_reps':
        return 'Max Reps';
      case 'max_volume':
        return 'Max Volume';
      case 'fastest_pace':
        return 'Fastest Pace';
      case 'longest_distance':
        return 'Longest Distance';
      default:
        return 'Personal Record';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${record.achievedAt.day}/${record.achievedAt.month}/${record.achievedAt.year}';
    final improvement = record.previousValue != null
        ? record.value - record.previousValue!
        : null;

    return Card(
      child: ListTile(
        leading: Icon(
          _typeIcon(record.recordType),
          color: Colors.amber,
          size: 32,
        ),
        title: Text(record.exerciseName),
        subtitle: Text(
          '${_typeLabel(record.recordType)}: ${record.value.toStringAsFixed(1)} ${record.unit}'
          '${improvement != null && improvement > 0 ? '\n+$improvement ${record.unit} improvement' : ''}'
          '\n$dateStr',
        ),
        isThreeLine: improvement != null && improvement > 0,
      ),
    );
  }
}
