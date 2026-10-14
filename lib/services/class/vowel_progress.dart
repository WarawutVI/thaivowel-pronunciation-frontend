class VowelProgress {
  final int vowelId;
  final String symbol;
  final String vowelType;
  final int completed;
  final int attempted; // lessons tried at least once, passed or not
  final int total;

  const VowelProgress({
    required this.vowelId,
    required this.symbol,
    required this.vowelType,
    required this.completed,
    this.attempted = 0,
    required this.total,
  });

  factory VowelProgress.fromJson(Map<String, dynamic> j) => VowelProgress(
        vowelId: j['vowel_id'] as int,
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        completed: (j['completed'] ?? 0) as int,
        attempted: (j['attempted'] ?? 0) as int,
        total: (j['total'] ?? 6) as int,
      );
}
