/// A row from GET /practice_sessions/recent — either a single-vowel
/// attempt ('single') or a vowel-pair attempt ('pair'). Only the fields
/// relevant to that [type] are populated; the others are null.
class SessionRecord {
  final String type; // 'single' | 'pair'
  final DateTime practicedAt;
  final bool isPassed;

  // 'single' fields
  final String? symbol;
  final String? vowelType;
  final String? lessonName;
  final double? confidence;
  final String? assessmentLevel;

  // 'pair' fields
  final String? shortSymbol;
  final String? longSymbol;
  final double? confidenceShort;
  final double? confidenceLong;
  final String? assessmentLevelShort;
  final String? assessmentLevelLong;

  const SessionRecord({
    required this.type,
    required this.practicedAt,
    required this.isPassed,
    this.symbol,
    this.vowelType,
    this.lessonName,
    this.confidence,
    this.assessmentLevel,
    this.shortSymbol,
    this.longSymbol,
    this.confidenceShort,
    this.confidenceLong,
    this.assessmentLevelShort,
    this.assessmentLevelLong,
  });

  bool get isPair => type == 'pair';

  /// Single symbol for single-vowel rows, "short→long" for pair rows.
  String get displaySymbol =>
      isPair ? '$shortSymbol→$longSymbol' : (symbol ?? '');

  /// Single confidence for single-vowel rows, average of both segments
  /// for pair rows (used for sorting/filtering, not shown as-is in the UI).
  double get displayConfidence => isPair
      ? (((confidenceShort ?? 0) + (confidenceLong ?? 0)) / 2)
      : (confidence ?? 0);

  factory SessionRecord.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String? ?? 'single';
    final practicedAt = DateTime.parse(j['practiced_at'] as String).toLocal();
    final isPassed = j['is_passed'] as bool? ?? false;

    if (type == 'pair') {
      final pair = j['pair'] as Map<String, dynamic>? ?? {};
      return SessionRecord(
        type: type,
        practicedAt: practicedAt,
        isPassed: isPassed,
        shortSymbol: pair['short_symbol'] as String?,
        longSymbol: pair['long_symbol'] as String?,
        confidenceShort: (pair['confidence_short'] as num?)?.toDouble(),
        confidenceLong: (pair['confidence_long'] as num?)?.toDouble(),
        assessmentLevelShort: pair['assessment_level_short'] as String?,
        assessmentLevelLong: pair['assessment_level_long'] as String?,
      );
    }

    return SessionRecord(
      type: type,
      practicedAt: practicedAt,
      isPassed: isPassed,
      symbol: j['symbol'] as String?,
      vowelType: j['vowel_type'] as String?,
      lessonName: j['lesson_name'] as String?,
      confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
      assessmentLevel: j['assessment_level'] as String?,
    );
  }
}
