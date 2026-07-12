import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:intl/intl.dart';

/// A single practice-session row, shared by HistoryBox and AllHistoryPage.
class SessionRow extends StatelessWidget {
  final SessionRecord session;
  final bool isEnglish;

  const SessionRow({
    super.key,
    required this.session,
    required this.isEnglish,
  });

  String t(String en, String th) => isEnglish ? en : th;

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final time = DateFormat('HH:mm').format(dt);

    if (day == today) return '${t('Today', 'วันนี้')} · $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return '${t('Yesterday', 'เมื่อวาน')} · $time';
    }
    return '${DateFormat('MMM d').format(dt)} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final s = session;
    final color = accuracyColor(s.confidence);
    final pct = (s.confidence * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Vowel symbol chip
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                s.lessonName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Lesson name + timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessmentLabel(s.confidence, isEnglish),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _timeLabel(s.practicedAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Accuracy pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$pct%',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}
