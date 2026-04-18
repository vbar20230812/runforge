import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalSettingsPage extends StatefulWidget {
  const GoalSettingsPage({super.key});

  @override
  State<GoalSettingsPage> createState() => _GoalSettingsPageState();
}

class _GoalSettingsPageState extends State<GoalSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalValueController = TextEditingController();
  String _goalType = '10k_time';
  String _goalTimeline = '3_months';
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, String> _goalTypeLabels = {
    '10k_time': '10K Run Time',
    '5k_time': '5K Run Time',
    'strength': 'Strength Goal',
    'weight': 'Weight Goal',
    'endurance': 'Endurance Goal',
  };

  final Map<String, String> _timelineLabels = {
    '1_month': '1 Month',
    '3_months': '3 Months',
    '6_months': '6 Months',
    '1_year': '1 Year',
  };

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  @override
  void dispose() {
    _goalValueController.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
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
          .doc('goal')
          .get();

      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          _goalType = data['goalType'] ?? '10k_time';
          _goalTimeline = data['timeline'] ?? '3_months';
          _goalValueController.text = data['goalValue']?.toString() ?? '';
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

  Future<void> _saveGoal() async {
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
        .doc('goal')
        .set({
      'goalType': _goalType,
      'goalValue': _goalValueController.text,
      'timeline': _goalTimeline,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal updated')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Goal'),
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
                            'What do you want to achieve?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          RadioGroup<String>(
                            groupValue: _goalType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _goalType = value;
                                });
                              }
                            },
                            child: Column(
                              children: _goalTypeLabels.entries.map((entry) {
                                return RadioListTile<String>(
                                  title: Text(entry.value),
                                  value: entry.key,
                                );
                              }).toList(),
                            ),
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
                            'Goal Target',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _goalValueController,
                            decoration: InputDecoration(
                              labelText: _getGoalValueLabel(),
                              hintText: _getGoalValueHint(),
                            ),
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your goal target';
                              }
                              return null;
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
                            'Timeline',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          RadioGroup<String>(
                            groupValue: _goalTimeline,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _goalTimeline = value;
                                });
                              }
                            },
                            child: Column(
                              children: _timelineLabels.entries.map((entry) {
                                return RadioListTile<String>(
                                  title: Text(entry.value),
                                  value: entry.key,
                                );
                              }).toList(),
                            ),
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
            ),
    );
  }

  String _getGoalValueLabel() {
    switch (_goalType) {
      case '10k_time':
      case '5k_time':
        return 'Target Time';
      case 'strength':
        return 'Target Weight/Reps';
      case 'weight':
        return 'Target Weight (kg)';
      case 'endurance':
        return 'Target Duration';
      default:
        return 'Goal Value';
    }
  }

  String _getGoalValueHint() {
    switch (_goalType) {
      case '10k_time':
        return 'e.g., 60 minutes';
      case '5k_time':
        return 'e.g., 25 minutes';
      case 'strength':
        return 'e.g., Bench press 80kg';
      case 'weight':
        return 'e.g., 75';
      case 'endurance':
        return 'e.g., Run 30 minutes non-stop';
      default:
        return 'Enter your goal';
    }
  }
}
