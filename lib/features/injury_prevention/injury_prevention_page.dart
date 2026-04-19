import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/injury_provider.dart';
import '../../shared/widgets/loading_spinner.dart';
import '../../shared/widgets/error_message.dart';
import '../../data/models/injury_risk_assessment.dart';

class InjuryPreventionPage extends ConsumerWidget {
  const InjuryPreventionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentAsync = ref.watch(injuryRiskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Injury Prevention'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('InjuryPrevention: invalidating injuryRiskProvider');
              ref.invalidate(injuryRiskProvider);
            },
            tooltip: 'Recalculate',
          ),
        ],
      ),
      body: assessmentAsync.when(
        loading: () => const LoadingSpinner(message: 'Calculating injury risk...'),
        error: (error, _) => ErrorMessage(
          message: 'Failed to calculate risk: $error',
          onRetry: () => ref.invalidate(injuryRiskProvider),
        ),
        data: (assessment) {
          if (assessment == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 64, color: Theme.of(context).disabledColor),
                    const SizedBox(height: 16),
                    Text(
                      'Not enough data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete a few workouts so we can assess your injury risk.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return _AssessmentContent(assessment: assessment);
        },
      ),
    );
  }
}

class _AssessmentContent extends StatelessWidget {
  final InjuryRiskAssessment assessment;

  const _AssessmentContent({required this.assessment});

  Color _riskColor(int score) {
    if (score < 40) return Colors.green;
    if (score <= 70) return Colors.orange;
    return Colors.red;
  }

  String _riskLevelText(String level) {
    switch (level) {
      case 'low':
        return 'Low Risk';
      case 'moderate':
        return 'Moderate Risk';
      case 'high':
        return 'High Risk';
      default:
        return level;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'low':
        return Icons.info_outline;
      case 'medium':
        return Icons.warning_amber;
      case 'high':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(assessment.riskScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Overall risk score
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Overall Risk Score',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${assessment.riskScore}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _riskLevelText(assessment.riskLevel),
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Risk breakdown bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Breakdown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (assessment.loadSpikeScore != null)
                    _ScoreBar(label: 'Load Spike', score: assessment.loadSpikeScore!),
                  if (assessment.muscleImbalanceScore != null)
                    _ScoreBar(label: 'Muscle Imbalance', score: assessment.muscleImbalanceScore!),
                  if (assessment.recoveryScore != null)
                    _ScoreBar(label: 'Recovery', score: assessment.recoveryScore!),
                  if (assessment.sleepScore != null)
                    _ScoreBar(label: 'Sleep', score: assessment.sleepScore!),
                  if (assessment.restingHrScore != null)
                    _ScoreBar(label: 'Resting HR', score: assessment.restingHrScore!),
                  if (assessment.restDayScore != null)
                    _ScoreBar(label: 'Rest Days', score: assessment.restDayScore!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Risk factors
          if (assessment.riskFactors.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Risk Factors',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            ...assessment.riskFactors.map((factor) => Card(
                  child: ListTile(
                    leading: Icon(
                      _severityIcon(factor.severity),
                      color: _severityColor(factor.severity),
                    ),
                    title: Text(factor.factor),
                    subtitle: Text(factor.message),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Recommendations
          if (assessment.recommendations.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: assessment.recommendations.map((rec) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, size: 20, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreBar({required this.label, required this.score});

  Color _barColor(int score) {
    if (score < 40) return Colors.green;
    if (score <= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(_barColor(score)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text('$score', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
