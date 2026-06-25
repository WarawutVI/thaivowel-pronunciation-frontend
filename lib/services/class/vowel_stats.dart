class VowelStats {
  final int vowelId;
  final String symbol;
  final String vowelType;
  final int practiceCount;
  final double avgAccuracy;

  const VowelStats({
    required this.vowelId,
    required this.symbol,
    required this.vowelType,
    required this.practiceCount,
    required this.avgAccuracy,
  });

  factory VowelStats.fromJson(Map<String, dynamic> j) => VowelStats(
        vowelId: j['vowel_id'] as int,
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        practiceCount: (j['practice_count'] ?? 0) as int,
        avgAccuracy: (j['avg_accuracy'] ?? 0.0).toDouble(),
      );
}
