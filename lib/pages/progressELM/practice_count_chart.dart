import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/practice_api.dart';

/// Vertical bar chart showing how many times each vowel was practised.
/// Includes a long/short filter pill.
class PracticeCountChart extends StatelessWidget {
  final List<VowelStats> stats;
  final String type; // 'short' | 'long'
  final bool isEnglish;
  final ValueChanged<String> onTypeChanged;

  const PracticeCountChart({
    super.key,
    required this.stats,
    required this.type,
    required this.isEnglish,
    required this.onTypeChanged,
  });

  String t(String en, String th) => isEnglish ? en : th;

  @override
  Widget build(BuildContext context) {
    return ProgressCard(
      child: stats.isEmpty ? _empty() : _chart(),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(t('No data yet', 'ยังไม่มีข้อมูล'),
              style: const TextStyle(color: Colors.grey)),
        ),
      );

  // ── Bar chart ───────────────────────────────────────────────────────────────

  Widget _chart() {
    final maxY = stats
        .map((v) => v.practiceCount)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('Practice Count', 'จำนวนครั้งที่ฝึก'),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            FilterPill(
              value: type,
              isEnglish: isEnglish,
              onChanged: onTypeChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bars
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY + 2,
              barGroups: stats.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.practiceCount.toDouble(),
                      color: const Color(0xFF1A7A50),
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),

                // Count labels above each bar
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= stats.length) return const SizedBox();
                      final c = stats[i].practiceCount;
                      if (c == 0) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('$c',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54)),
                      );
                    },
                  ),
                ),

                // Vowel symbol labels below each bar
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= stats.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(stats[i].symbol,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barTouchData: BarTouchData(enabled: false),
            ),
          ),
        ),
      ],
    );
  }
}
