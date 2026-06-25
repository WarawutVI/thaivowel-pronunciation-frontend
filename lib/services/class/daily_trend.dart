class DailyTrend {
  final DateTime date;
  final double avgAccuracy;

  const DailyTrend({required this.date, required this.avgAccuracy});

  factory DailyTrend.fromJson(Map<String, dynamic> j) => DailyTrend(
        date: DateTime.parse(j['date'] as String),
        avgAccuracy: (j['avg_accuracy'] ?? 0.0).toDouble(),
      );
}
