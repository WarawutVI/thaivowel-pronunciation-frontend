class SessionRecord {
  final String symbol;
  final String vowelType;
  final String lessonName;
  final double confidence;
  final DateTime practicedAt;

  const SessionRecord({
    required this.symbol,
    required this.vowelType,
    required this.lessonName,
    required this.confidence,
    required this.practicedAt,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        symbol: j['symbol'] as String,
        vowelType: j['vowel_type'] as String,
        lessonName: j['lesson_name'] as String,
        confidence: (j['confidence'] ?? 0.0).toDouble(),
        practicedAt: DateTime.parse(j['practiced_at'] as String).toLocal(),
      );
}
