import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/loading_spinner.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
      ),
      body: profileAsync.when(
        loading: () => const LoadingSpinner(message: 'Loading goal...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load profile: $error'),
              ],
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off, size: 64, color: Theme.of(context).disabledColor),
                    const SizedBox(height: 16),
                    Text(
                      'No profile found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final goalMinutes = (profile.goal10kTimeSec / 60).round();
          final currentMinutes = profile.current10kTimeSec != null
              ? (profile.current10kTimeSec! / 60).round()
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Current Goal',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '10K under $goalMinutes minutes',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (currentMinutes != null) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current: ~$currentMinutes min',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Target: $goalMinutes min',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: currentMinutes <= goalMinutes
                                  ? 1.0
                                  : (goalMinutes / currentMinutes).clamp(0.0, 1.0),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      debugPrint('GoalsPage: navigating to /settings/goals');
                      context.push('/settings/goals');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Goal'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Training Plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          label: 'Strength sessions/week',
                          value: '${profile.strengthFrequency}',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Run sessions/week',
                          value: '${profile.runFrequency}',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Equipment',
                          value: profile.availableEquipment.isEmpty
                              ? 'None selected'
                              : profile.availableEquipment.join(', '),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Run days',
                          value: profile.preferredRunDays.isEmpty
                              ? 'None selected'
                              : profile.preferredRunDays.join(', '),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
