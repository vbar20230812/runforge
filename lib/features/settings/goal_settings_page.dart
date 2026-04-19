import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/loading_spinner.dart';
import '../../core/constants/app_constants.dart';

class GoalSettingsPage extends ConsumerStatefulWidget {
  const GoalSettingsPage({super.key});

  @override
  ConsumerState<GoalSettingsPage> createState() => _GoalSettingsPageState();
}

class _GoalSettingsPageState extends ConsumerState<GoalSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  String _goalType = '10k_time';
  bool _isSaving = false;
  bool _initialized = false;

  static const Map<String, String> _goalTypeLabels = {
    '10k_time': '10K Run Time',
    '5k_time': '5K Run Time',
  };

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _populateFromProfile() {
    final profileAsync = ref.read(userProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null && !_initialized) {
        _initialized = true;
        final goalMinutes = (profile.goal10kTimeSec / 60).round();
        _timeController.text = goalMinutes.toString();
      }
    });
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userId = ref.read(userIdProvider);
    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    final goalMinutes = int.tryParse(_timeController.text) ?? 60;
    final goalSeconds = goalMinutes * 60;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'goal10kTimeSec': goalSeconds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ref.invalidate(userProfileProvider);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('GoalSettingsPage: save failed: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    _populateFromProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Goal'),
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
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Goal type selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goal Type',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ..._goalTypeLabels.entries.map((entry) {
                          return RadioListTile<String>(
                            title: Text(entry.value),
                            value: entry.key,
                            groupValue: _goalType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _goalType = value;
                                });
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Target time
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Time',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _timeController,
                          decoration: InputDecoration(
                            labelText: _goalType == '10k_time'
                                ? '10K target time (minutes)'
                                : '5K target time (minutes)',
                            hintText: _goalType == '10k_time' ? 'e.g., 60' : 'e.g., 25',
                            prefixIcon: const Icon(Icons.timer),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a target time';
                            }
                            final time = int.tryParse(value);
                            if (time == null || time < 1) {
                              return 'Please enter a valid time in minutes';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Default: ${AppConstants.default10kGoalSeconds ~/ 60} minutes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveGoal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.flag),
                  label: const Text('Set Goal'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
