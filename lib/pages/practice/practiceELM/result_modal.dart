import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

void showResultModal(
  BuildContext context, {
  required bool isEnglish,
  required double confidence,
  required List<double> refSamples,
  required List<double> userSamples,
  required String suggestion,
  required double userF1,
  required double userF2,
  VowelFormant? ref,
}) {
  String t(String en, String th) => isEnglish ? en : th;
  final passed = confidence >= 0.51;
  final level = assessmentLabel(confidence, isEnglish);
  final assessImage = _assessImagePath(confidence);
  final assessCaption = _assessCaption(confidence, isEnglish);

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
                      color: accuracyColor(confidence),
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
                      color: accuracyColor(confidence),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Container(color: Colors.grey.shade200),
                        FractionallySizedBox(
                          widthFactor: confidence.clamp(0.0, 1.0),
                          child: Container(color: accuracyColor(confidence)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    t(
                      'accuracy ${(confidence * 100).toStringAsFixed(0)}%',
                      'ความถูกต้อง ${(confidence * 100).toStringAsFixed(0)}%',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (suggestion.isNotEmpty && !passed) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${t('suggestion', 'คำแนะนำ')} : ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A7A50),
                            ),
                          ),
                          TextSpan(
                            text: suggestion,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

class _FormantStat extends StatelessWidget {
  final String label;
  final double userValue;
  final String target;
  final bool isEnglish;

  const _FormantStat({
    required this.label,
    required this.userValue,
    required this.target,
    required this.isEnglish,
  });

  String t(String en, String th) => isEnglish ? en : th;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${t('You', 'คุณ')}: ${userValue.round()} Hz',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        Text(
          '${t('Target', 'เป้าหมาย')}: $target Hz',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
