import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:intl/intl.dart';

/// A single practice-session row, shared by HistoryBox and AllHistoryPage.
/// Single-vowel sessions render as a plain row; pair sessions collapse to
/// a single row that expands (tap to toggle) to show each vowel's score.
class SessionRow extends StatefulWidget {
  final SessionRecord session;
  final bool isEnglish;

  const SessionRow({
    super.key,
    required this.session,
    required this.isEnglish,
  });

  @override
  State<SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<SessionRow> {
  bool _expanded = false;

  String t(String en, String th) => widget.isEnglish ? en : th;

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
    final s = widget.session;
    return s.isPair ? _buildPairRow(s) : _buildSingleRow(s);
  }

  Widget _buildSingleRow(SessionRecord s) {
    final confidence = s.confidence ?? 0;
    final color = accuracyColor(confidence);
    final pct = (confidence * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                s.lessonName ?? s.symbol ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessmentLabel(confidence, widget.isEnglish),
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
                  fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairRow(SessionRecord s) {
    final avgConfidence = s.displayConfidence;
    final color = accuracyColor(avgConfidence);
    final pct = (avgConfidence * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(Icons.compare_arrows, color: color, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.shortSymbol} → ${s.longSymbol}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        Text(
                          _timeLabel(s.practicedAt),
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                      child: _segmentPill(s.shortSymbol ?? '',
                          s.confidenceShort ?? 0, widget.isEnglish)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _segmentPill(s.longSymbol ?? '',
                          s.confidenceLong ?? 0, widget.isEnglish)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _segmentPill(String symbol, double confidence, bool isEnglish) {
    final color = accuracyColor(confidence);
    final pct = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(symbol,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              Text('$pct%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            assessmentLabel(confidence, isEnglish),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
