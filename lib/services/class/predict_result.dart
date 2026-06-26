class PredictResult {
  final double confidence;
  final bool isPassed;
  final String assessmentLevel;
  final double userF1;
  final double userF2;
  final List<double> refWave;
  final List<double> userWave;

  const PredictResult({
    required this.confidence,
    required this.isPassed,
    required this.assessmentLevel,
    required this.userF1,
    required this.userF2,
    required this.refWave,
    required this.userWave,
  });

  factory PredictResult.fromJson(Map<String, dynamic> j) {
    final conf = (j['confidence'] as num? ?? 0.0).toDouble();
    final pct = (conf * 100).round();
    final formants = j['user_formants'] as Map<String, dynamic>? ?? {};
    final level = pct >= 81 ? 'Excellent'
                : pct >= 51 ? 'Good'
                : pct >= 30 ? 'Needs Improvement'
                :             'Incorrect';
    return PredictResult(
      confidence: conf,
      isPassed: pct >= 51,
      assessmentLevel: level,
      userF1: (formants['F1'] as num? ?? 0.0).toDouble(),
      userF2: (formants['F2'] as num? ?? 0.0).toDouble(),
      refWave:  (j['ref_wave']  as List? ?? []).map((e) => (e as num).toDouble()).toList(),
      userWave: (j['user_wave'] as List? ?? []).map((e) => (e as num).toDouble()).toList(),
    );
  }
}
