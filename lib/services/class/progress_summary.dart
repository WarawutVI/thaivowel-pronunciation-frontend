class ProgressSummary {
  final double overallAccuracy;
  final int totalSessions;
  final double bestAccuracy;
  final double longAvgAccuracy;
  final double shortAvgAccuracy;

  const ProgressSummary({
    required this.overallAccuracy,
    required this.totalSessions,
    required this.bestAccuracy,
    required this.longAvgAccuracy,
    required this.shortAvgAccuracy,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> j) => ProgressSummary(
        overallAccuracy: (j['overall_accuracy'] ?? 0.0).toDouble(),
        totalSessions: (j['total_sessions'] ?? 0) as int,
        bestAccuracy: (j['best_accuracy'] ?? 0.0).toDouble(),
        longAvgAccuracy: (j['long_avg_accuracy'] ?? 0.0).toDouble(),
        shortAvgAccuracy: (j['short_avg_accuracy'] ?? 0.0).toDouble(),
      );
}
