import 'package:flutter/material.dart';
import 'package:frontend/services/practice_api.dart';

/// Hero gradient banner — overall accuracy, sessions, best score, streak.
class SummaryCard extends StatelessWidget {
  final ProgressSummary summary;
  final int streak;
  final bool isEnglish;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.streak,
    required this.isEnglish,
  });

  String t(String en, String th) => isEnglish ? en : th;

  @override
  Widget build(BuildContext context) {
    final accuracy = (summary.overallAccuracy * 100).round();
    final best = (summary.bestAccuracy * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A7A50), Color(0xFF2A9B6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Decorative mini bars in background
          Positioned(
            right: 0, top: 0, bottom: 0, width: 130,
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(painter: _MiniBarsPainter()),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('OVERALL ACCURACY', 'ความแม่นยำโดยรวม'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$accuracy%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _stat(t('SESSIONS', 'ครั้ง'), '${summary.totalSessions}'),
                  const SizedBox(width: 24),
                  _stat(t('BEST', 'ดีที่สุด'), '$best%'),
                  const SizedBox(width: 24),
                  _stat(t('STREAK', 'วันต่อเนื่อง'), '$streak 🔥'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      );
}

class _MiniBarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const heights = [0.5, 0.8, 0.4, 0.95, 0.6, 0.75, 0.55, 0.85, 0.45];
    const barW = 10.0;
    const gap = 4.0;
    var x = 0.0;
    for (final h in heights) {
      final barH = size.height * h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barH, barW, barH),
          const Radius.circular(3),
        ),
        paint,
      );
      x += barW + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
