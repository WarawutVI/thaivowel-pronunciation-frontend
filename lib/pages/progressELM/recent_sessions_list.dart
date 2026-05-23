import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:intl/intl.dart';

/// Scrollable list of the most recent practice sessions.
class RecentSessionsList extends StatelessWidget {
  final List<SessionRecord> sessions;
  final bool isEnglish;

  const RecentSessionsList({
    super.key,
    required this.sessions,
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
            t('Recent Sessions', 'เซสชันล่าสุด'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(t('No sessions yet', 'ยังไม่มีเซสชัน'),
                    style: const TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...sessions.map(_buildRow),
        ],
      ),
    );
  }

  // ── Single session row ──────────────────────────────────────────────────────

  Widget _buildRow(SessionRecord s) {
    final color = accuracyColor(s.confidence);
    final pct = (s.confidence * 100).round();
    final isLong = s.vowelType == 'long';

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
              color: isLong
                  ? const Color(0xFFE8F5EE)
                  : const Color(0xFFFFEEE8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                s.symbol,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLong
                      ? const Color(0xFF1A7A50)
                      : const Color(0xFFFF8C42),
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
                  s.lessonName,
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

  // ── Relative timestamp label ────────────────────────────────────────────────

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
}
