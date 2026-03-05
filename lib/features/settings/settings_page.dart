import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/auth_service.dart';

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
          const Divider(),
          _buildSectionHeader(context, 'Integrations'),
          ListTile(
            leading: const Icon(Icons.watch),
            title: const Text('Garmin'),
            subtitle: const Text('Not connected'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showGarminDialog(context);
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/login');
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

  void _showGarminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.watch),
            SizedBox(width: 8),
            Text('Garmin Connection'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect your Garmin device to sync workouts automatically.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Automatic workout sync'),
            Text('• Heart rate data'),
            Text('• GPS tracking'),
            Text('• Sleep data'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Garmin integration coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.link),
            label: const Text('Connect'),
          ),
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
