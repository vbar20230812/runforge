import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/loading_spinner.dart';
import '../../core/constants/app_constants.dart';

class TrainingPreferencesPage extends ConsumerStatefulWidget {
  const TrainingPreferencesPage({super.key});

  @override
  ConsumerState<TrainingPreferencesPage> createState() => _TrainingPreferencesPageState();
}

class _TrainingPreferencesPageState extends ConsumerState<TrainingPreferencesPage> {
  final _formKey = GlobalKey<FormState>();
  int _strengthFrequency = AppConstants.defaultStrengthFrequency;
  int _runFrequency = AppConstants.defaultRunFrequency;
  Set<String> _selectedEquipment = {};
  Set<String> _selectedRunDays = {};
  bool _isSaving = false;
  bool _initialized = false;

  static const List<String> _equipmentOptions = [
    'barbell', 'dumbbell', 'cable', 'bodyweight', 'kettlebell', 'machine',
  ];

  static const List<String> _runDayOptions = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  @override
  void dispose() {
    super.dispose();
  }

  void _populateFromProfile() {
    final profileAsync = ref.read(userProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null && !_initialized) {
        _initialized = true;
        setState(() {
          _strengthFrequency = profile.strengthFrequency;
          _runFrequency = profile.runFrequency;
          _selectedEquipment = Set<String>.from(profile.availableEquipment);
          _selectedRunDays = Set<String>.from(profile.preferredRunDays);
        });
      }
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    final userId = ref.read(userIdProvider);
    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'strengthFrequency': _strengthFrequency,
        'runFrequency': _runFrequency,
        'availableEquipment': _selectedEquipment.toList(),
        'preferredRunDays': _selectedRunDays.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ref.invalidate(userProfileProvider);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences updated')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('TrainingPreferencesPage: save failed: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  String _formatLabel(String value) {
    return value.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    _populateFromProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Preferences'),
      ),
      body: profileAsync.when(
        loading: () => const LoadingSpinner(message: 'Loading preferences...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load preferences: $error'),
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
                // Strength frequency
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Strength Frequency',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_strengthFrequency sessions per week',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Slider(
                          value: _strengthFrequency.toDouble(),
                          min: AppConstants.minStrengthFrequency.toDouble(),
                          max: AppConstants.maxStrengthFrequency.toDouble(),
                          divisions: AppConstants.maxStrengthFrequency - AppConstants.minStrengthFrequency,
                          label: _strengthFrequency.toString(),
                          onChanged: (value) {
                            setState(() {
                              _strengthFrequency = value.round();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Run frequency
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Run Frequency',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_runFrequency sessions per week',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Slider(
                          value: _runFrequency.toDouble(),
                          min: AppConstants.minRunFrequency.toDouble(),
                          max: AppConstants.maxRunFrequency.toDouble(),
                          divisions: AppConstants.maxRunFrequency - AppConstants.minRunFrequency,
                          label: _runFrequency.toString(),
                          onChanged: (value) {
                            setState(() {
                              _runFrequency = value.round();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Available equipment
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Equipment',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select all equipment you have access to',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _equipmentOptions.map((equipment) {
                            return FilterChip(
                              label: Text(_formatLabel(equipment)),
                              selected: _selectedEquipment.contains(equipment),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedEquipment.add(equipment);
                                  } else {
                                    _selectedEquipment.remove(equipment);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Preferred run days
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred Run Days',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select which days you prefer to run',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _runDayOptions.map((day) {
                            return FilterChip(
                              label: Text(_formatLabel(day)),
                              selected: _selectedRunDays.contains(day),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedRunDays.add(day);
                                  } else {
                                    _selectedRunDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _savePreferences,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Preferences'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
