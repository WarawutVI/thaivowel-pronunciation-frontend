import 'package:flutter/material.dart';
import 'package:frontend/pages/all_history_page.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/pages/progressELM/session_row.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

/// Scrollable list of the most recent practice sessions.
class HistoryBox extends StatelessWidget {
  final List<SessionRecord> sessions;
  final bool isEnglish;

  const HistoryBox({
    super.key,
    required this.sessions,
    required this.isEnglish,
  });

  String t(String en, String th) => isEnglish ? en : th;

  static const int _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final recent = sessions.take(_maxVisible).toList();

    return ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('History', 'ประวัติ'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(t('No sessions yet', 'ยังไม่มีเซสชัน'),
                    style: const TextStyle(color: Colors.grey)),
              ),
            )
          else ...[
            ...recent.map((s) => SessionRow(session: s, isEnglish: isEnglish)),
            if (sessions.length > _maxVisible)
              Center(
                child: GestureDetector(
                  onTap: () => Get.to(() => const AllHistoryPage()),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      t('Show more', 'ดูเพิ่มเติม'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A7A50),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
