import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Profile'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            subtitle: const Text('Name, age, weight, height'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Training Preferences'),
            subtitle: const Text('Frequency, equipment, schedule'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/preferences');
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Training'),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Exercise Types'),
            subtitle: const Text('Manage exercise categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/exercises');
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Goals'),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Training Goal'),
            subtitle: const Text('10K under 60 minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/goals');
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'RunForge v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
