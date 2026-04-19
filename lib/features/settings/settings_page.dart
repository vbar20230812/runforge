import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../shared/providers/user_provider.dart';
import '../../core/constants/app_constants.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    final userName = profileAsync.when(
      loading: () => null,
      error: (_, __) => null,
      data: (profile) => profile?.name,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    userName != null && userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName ?? 'Loading...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Manage your profile and preferences',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Profile section
          _sectionHeader(context, 'Profile'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            subtitle: const Text('Name, age, weight, height'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              debugPrint('SettingsPage: navigating to /settings/profile');
              context.push('/settings/profile');
            },
          ),

          // Preferences section
          _sectionHeader(context, 'Preferences'),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Training Preferences'),
            subtitle: const Text('Frequency, equipment, run days'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              debugPrint('SettingsPage: navigating to /settings/preferences');
              context.push('/settings/preferences');
            },
          ),

          // Training section
          _sectionHeader(context, 'Training'),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Training Goal'),
            subtitle: const Text('Set your 10K target time'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              debugPrint('SettingsPage: navigating to /settings/goals');
              context.push('/settings/goals');
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Exercise Types'),
            subtitle: const Text('Browse exercises by muscle group'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              debugPrint('SettingsPage: navigating to /settings/exercises');
              context.push('/settings/exercises');
            },
          ),

          const Divider(),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
