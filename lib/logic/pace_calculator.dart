/// Running pace calculation utilities.
class PaceCalculator {
  /// Calculate pace in seconds per km from total time and distance.
  static int calculatePace(int timeSeconds, double distanceKm) {
    if (distanceKm <= 0) return 0;
    return (timeSeconds / distanceKm).round();
  }

  /// Format pace as "M:SS" string.
  static String formatPace(int paceSecKm) {
    final minutes = paceSecKm ~/ 60;
    final seconds = paceSecKm % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format duration as "Xh Ym" or "Ym".
  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Calculate training pace zones from a goal 10K time.
  /// Returns a map of zone name -> pace in sec/km.
  static Map<String, int> calculateTrainingPaces(int goal10kTimeSec) {
    final goalPace = calculatePace(goal10kTimeSec, 10.0);
    return {
      'easy': goalPace + 75, // goal pace + 60-90 sec/km
      'long': goalPace + 60, // goal pace + 45-75 sec/km
      'tempo': goalPace + 20, // goal pace + 15-30 sec/km
      'interval': (goalPace - 15).clamp(120, 600), // goal pace - 10-20 sec/km
    };
  }

  /// Estimate 10K time improvement based on weeks of training remaining.
  /// Assumes ~2 sec/km improvement per 4-week mesocycle.
  static int estimate10kTime(int currentPaceSecKm, int weeksRemaining) {
    final mesocyclesRemaining = weeksRemaining ~/ 4;
    final improvementPerMesocycle = 2; // sec/km
    final projectedPace = (currentPaceSecKm -
            mesocyclesRemaining * improvementPerMesocycle)
        .clamp(180, currentPaceSecKm);
    return projectedPace * 10; // pace * distance = time
  }
}
