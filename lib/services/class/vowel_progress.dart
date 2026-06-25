class VowelProgress {
  final int vowelId;
  final String symbol;
  final String vowelType;
  final int completed;
  final int total;

  const VowelProgress({
    required this.vowelId,
    required this.symbol,
    required this.vowelType,
    required this.completed,
    required this.total,
  });

  factory VowelProgress.fromJson(Map<String, dynamic> j) => VowelProgress(
        vowelId: j['vowel_id'] as int,
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        completed: (j['completed'] ?? 0) as int,
        total: (j['total'] ?? 6) as int,
      );
}
