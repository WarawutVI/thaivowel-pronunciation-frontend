class PredictPairSegment {
  final int classId;
  final double confidence;
  final double userF1;
  final double userF2;

  const PredictPairSegment({
    required this.classId,
    required this.confidence,
    required this.userF1,
    required this.userF2,
  });

  bool get isPassed => (confidence * 100).round() >= 51;

  factory PredictPairSegment.fromJson(Map<String, dynamic> j) {
    final formants = j['user_formants'] as Map<String, dynamic>? ?? {};
    return PredictPairSegment(
      classId: (j['class_id'] as num? ?? 0).toInt(),
      confidence: (j['confidence'] as num? ?? 0.0).toDouble(),
      userF1: (formants['F1'] as num? ?? 0.0).toDouble(),
      userF2: (formants['F2'] as num? ?? 0.0).toDouble(),
    );
  }
}

class PredictPairResult {
  final PredictPairSegment segment1;
  final PredictPairSegment segment2;

  const PredictPairResult({required this.segment1, required this.segment2});

  factory PredictPairResult.fromJson(Map<String, dynamic> j) =>
      PredictPairResult(
        segment1: PredictPairSegment.fromJson(
            j['segment1'] as Map<String, dynamic>),
        segment2: PredictPairSegment.fromJson(
            j['segment2'] as Map<String, dynamic>),
      );
}
