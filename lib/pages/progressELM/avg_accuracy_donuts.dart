import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';

/// Two circular donut gauges — long vowel accuracy vs short vowel accuracy.
class AvgAccuracyDonuts extends StatelessWidget {
  final double longAvg;  // 0.0–1.0
  final double shortAvg; // 0.0–1.0
  final bool isEnglish;

  const AvgAccuracyDonuts({
    super.key,
    required this.longAvg,
    required this.shortAvg,
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
            t('Average Accuracy', 'ความถูกต้องเฉลี่ย'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _donut(
                accuracy: longAvg,
                label: t('Long vowels', 'สระเสียงยาว'),
              ),
              _donut(
                accuracy: shortAvg,
                label: t('Short vowels', 'สระเสียงสั้น'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Single donut gauge ──────────────────────────────────────────────────────

  Widget _donut({
    required double accuracy,
    required String label,
  }) {
    final clamped = accuracy.clamp(0.0, 1.0); // จำกัดค่าให้อยู่ระหว่าง 0.0 ถึง 1.0
    final pct = (accuracy * 100).round();
    final color = accuracyColor(accuracy);

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: clamped * 100,
                      color: color,
                      radius: 24,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: (1 - clamped) * 100,
                      color: const Color(0xFFE8E8E8),
                      radius: 24,
                      showTitle: false,
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 0,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
