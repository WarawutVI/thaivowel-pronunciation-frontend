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
  final bothPassed = segment1.isPassed && segment2.isPassed;

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
                    bothPassed
                        ? '${t('Well Done!', 'เก่งมากเลย!')} 🎉'
                        : t('Keep Practicing', 'ฝึกต่ออีกนิดนะ'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: bothPassed
                          ? const Color(0xFF34C759)
                          : Colors.black87,
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
