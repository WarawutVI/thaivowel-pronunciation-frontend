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
                      'similarity ${(confidence * 100).toStringAsFixed(0)}%',
                      'ความคล้ายคลึงกัน ${(confidence * 100).toStringAsFixed(0)}%',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (ref != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FormantStat(
                        label: 'F1',
                        userValue: userF1,
                        target: ref.hasRange
                            ? '${ref.f1Min!.round()}-${ref.f1Max!.round()}'
                            : '${ref.f1.round()}',
                        isEnglish: isEnglish,
                      ),
                      _FormantStat(
                        label: 'F2',
                        userValue: userF2,
                        target: ref.hasRange
                            ? '${ref.f2Min!.round()}-${ref.f2Max!.round()}'
                            : '${ref.f2.round()}',
                        isEnglish: isEnglish,
                      ),
                    ],
                  ),
                ],
                if (suggestion.isNotEmpty && !passed) ...[
                  const SizedBox(height: 14),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${t('suggestion', 'คำแนะนำ')} : ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
