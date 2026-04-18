import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingPreferencesPage extends StatefulWidget {
  const TrainingPreferencesPage({super.key});

  @override
  State<TrainingPreferencesPage> createState() => _TrainingPreferencesPageState();
}

class _TrainingPreferencesPageState extends State<TrainingPreferencesPage> {
  final _formKey = GlobalKey<FormState>();
  int _sessionsPerWeek = 3;
  String _preferredTime = 'morning';
  Set<String> _availableEquipment = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _equipmentOptions = [
    'bodyweight',
    'dumbbell',
    'barbell',
    'kettlebell',
    'resistance_band',
    'pull_up_bar',
    'bench',
    'cable_machine',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .get();

      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          _sessionsPerWeek = data['sessionsPerWeek'] ?? 3;
          _preferredTime = data['preferredTime'] ?? 'morning';
          _availableEquipment = Set<String>.from(data['availableEquipment'] ?? []);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .set({
      'sessionsPerWeek': _sessionsPerWeek,
      'preferredTime': _preferredTime,
      'availableEquipment': _availableEquipment.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences updated')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Preferences'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Training Frequency',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Text('Sessions per week: $_sessionsPerWeek'),
                          Slider(
                            value: _sessionsPerWeek.toDouble(),
                            min: 1,
                            max: 7,
                            divisions: 6,
                            label: _sessionsPerWeek.toString(),
                            onChanged: (value) {
                              setState(() {
                                _sessionsPerWeek = value.round();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferred Training Time',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'morning', label: Text('Morning')),
                              ButtonSegment(value: 'afternoon', label: Text('Afternoon')),
                              ButtonSegment(value: 'evening', label: Text('Evening')),
                            ],
                            selected: {_preferredTime},
                            onSelectionChanged: (Set<String> selection) {
                              setState(() {
                                _preferredTime = selection.first;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _equipmentOptions.map((equipment) {
                              final isSelected = _availableEquipment.contains(equipment);
                              return FilterChip(
                                label: Text(_formatEquipment(equipment)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _availableEquipment.add(equipment);
                                    } else {
                                      _availableEquipment.remove(equipment);
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
            ),
    );
  }

  String _formatEquipment(String equipment) {
    return equipment.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
