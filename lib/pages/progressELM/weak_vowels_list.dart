import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/word_grid_page.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

/// Top-3 lowest-accuracy vowels with a "Try again" button each.
class WeakVowelsList extends StatelessWidget {
  final List<VowelStats> weakVowels;
  final bool isEnglish;

  const WeakVowelsList({
    super.key,
    required this.weakVowels,
    required this.isEnglish,
  });

  String t(String en, String th) => isEnglish ? en : th;

  @override
  Widget build(BuildContext context) {
    return ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Vowels to work on', 'สระที่ต้องฝึกเพิ่ม'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            t('how the app records your practice',
                'วิธีที่แอปบันทึกการฝึกของคุณ'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (weakVowels.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  t('Practice more to see suggestions!',
                      'ฝึกเพิ่มเพื่อดูคำแนะนำ!'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...weakVowels.map(_buildRow),
        ],
      ),
    );
  }

  // ── Single weak-vowel row ───────────────────────────────────────────────────

  Widget _buildRow(VowelStats v) {
    final pct = (v.avgAccuracy * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Vowel symbol
          Text(
            v.symbol,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(width: 12),

          // Average + attempt count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Average $pct%', 'เฉลี่ย $pct%'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                Text(
                  t('${v.practiceCount} attempts',
                      '${v.practiceCount} ครั้ง'),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Try again → navigate to WordGridPage
          ElevatedButton(
            onPressed: () => Get.to(() => WordGridPage(
                  vowelId: v.vowelId,
                  vowelSymbol: v.symbol,
                  vowelType: v.vowelType,
                  isEnglish: isEnglish,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C42),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              t('Try again', 'ลองอีกครั้ง'),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
