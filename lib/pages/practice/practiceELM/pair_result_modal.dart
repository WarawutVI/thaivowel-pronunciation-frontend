import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/class/predict_pair_result.dart';
import 'package:get/get.dart';

void showPairResultModal(
  BuildContext context, {
  required bool isEnglish,
  required String shortSymbol,
  required String longSymbol,
  required PredictPairSegment segment1,
  required PredictPairSegment segment2,
}) {
  String t(String en, String th) => isEnglish ? en : th;
  final avgConfidence = (segment1.confidence + segment2.confidence) / 2;
  final passed = avgConfidence >= 0.51;
  final level = assessmentLabel(avgConfidence, isEnglish);
  final assessImage = _assessImagePath(avgConfidence);
  final assessCaption = _assessCaption(avgConfidence, isEnglish);

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    passed ? '$level 🎉' : level,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: accuracyColor(avgConfidence),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Image.asset(assessImage, height: 150),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    assessCaption,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: accuracyColor(avgConfidence),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    t(
                      'average accuracy ${(avgConfidence * 100).toStringAsFixed(0)}%',
                      'ความถูกต้องเฉลี่ย ${(avgConfidence * 100).toStringAsFixed(0)}%',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SegmentResultRow(
                  symbol: shortSymbol,
                  segment: segment1,
                  isEnglish: isEnglish,
                ),
                const SizedBox(height: 12),
                _SegmentResultRow(
                  symbol: longSymbol,
                  segment: segment2,
                  isEnglish: isEnglish,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1A7A50)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(t('Try Again', 'ลองอีกครั้ง'),
                            style: const TextStyle(color: Color(0xFF1A7A50))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A7A50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(t('Finish', 'เสร็จสิ้น'),
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.grey[200], shape: BoxShape.circle),
                child: Icon(Icons.close, color: Colors.grey[700], size: 24),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Maps a 0–1 confidence value to its assessment illustration, using the
/// same tier thresholds as [assessmentLabel]/[accuracyColor].
String _assessImagePath(double confidence) {
  final pct = (confidence * 100).round();
  if (pct >= 81) return 'assets/assess/Excellent.png';
  if (pct >= 51) return 'assets/assess/Good.png';
  if (pct >= 30) return 'assets/assess/Improvement.png';
  return 'assets/assess/Incorrect.png';
}

/// Maps a 0–1 confidence value to its assessment caption, using the same
/// tier thresholds as [assessmentLabel]/[accuracyColor]/[_assessImagePath].
String _assessCaption(double confidence, bool isEnglish) {
  final pct = (confidence * 100).round();
  if (pct >= 81) {
    return isEnglish ? 'Fantastic Pronunciation' : 'เก่งสุดๆไปเลย';
  }
  if (pct >= 51) {
    return isEnglish ? 'Well Done!' : 'เก่งมากเลย!';
  }
  if (pct >= 30) {
    return isEnglish ? "You're Almost There!" : 'พยายามอีกนิดนะ!';
  }
  return isEnglish ? 'Try Again!' : 'ลองใหม่อีกครั้งนะ!';
}

class _SegmentResultRow extends StatelessWidget {
  final String symbol;
  final PredictPairSegment segment;
  final bool isEnglish;

  const _SegmentResultRow({
    required this.symbol,
    required this.segment,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    final color = accuracyColor(segment.confidence);
    final pct = (segment.confidence * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            symbol,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessmentLabel(segment.confidence, isEnglish),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(color: Colors.grey.shade200),
                        FractionallySizedBox(
                          widthFactor: segment.confidence.clamp(0.0, 1.0),
                          child: Container(color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$pct%',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
