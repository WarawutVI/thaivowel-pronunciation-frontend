import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:intl/intl.dart';

/// Accuracy trend line chart — three periods:
///   • 1W : avg accuracy per day  for the last 7 days
///   • 1M : avg accuracy per week for the last 30 days
///   • 1Y : avg accuracy per month for the last 12 months
///
/// X-axis always shows "d MMM" dates (~5 labels, evenly spaced).
/// Y-axis is always 0–100 %.
/// Period selector sits below the chart as circle buttons.
class TrendCard extends StatefulWidget {
  final String firebaseUid;
  final bool isEnglish;

  const TrendCard({
    super.key,
    required this.firebaseUid,
    required this.isEnglish,
  });

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  // ── State ─────────────────────────────────────────────────────────────────────

  List<DailyTrend> _trendData = [];
  bool _loading = false;

  String _vowelType = 'short';  // 'short' | 'long'
  String _period    = 'week';   // 'week'  | 'month' | 'year'

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String t(String en, String th) => widget.isEnglish ? en : th;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadTrend();
  }

  // ── Data ──────────────────────────────────────────────────────────────────────

  Future<void> _loadTrend() async {
    setState(() => _loading = true);
    try {
      final data = await PracticeApi.fetchTrend(
        widget.firebaseUid,
        _vowelType,
        period: _period,
      );
      setState(() {
        _trendData = data;
        _loading   = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Chart data helpers ────────────────────────────────────────────────────────

  List<FlSpot> get _spots => _trendData
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), e.value.avgAccuracy * 100))
      .toList();

  (double, double) get _xRange {
    final last = _trendData.isEmpty ? 1.0 : (_trendData.length - 1).toDouble();
    return (0, last);
  }

  /// Show ~5 labels evenly spaced across the data.
  double get _labelInterval {
    final n = _trendData.length;
    if (n <= 7) return 1;
    return (n / 5).ceilToDouble();
  }

  /// All periods: "d MMM" format (e.g. "15 Jul", "04 Sep").
  String _xLabel(int i) {
    if (i < 0 || i >= _trendData.length) return '';
    return DateFormat('d MMM').format(_trendData[i].date);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildChartArea(),
          const SizedBox(height: 12),
          _buildPeriodButtons(),
          _buildSummaryRow(),
        ],
      ),
    );
  }

  // ── Header: title + vowel type pill ──────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t('Accuracy Trend', 'แนวโน้มความแม่นยำ'),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        FilterPill(
          value: _vowelType,
          isEnglish: widget.isEnglish,
          onChanged: (v) {
            setState(() => _vowelType = v);
            _loadTrend();
          },
        ),
      ],
    );
  }

  // ── Chart area: spinner | empty | line chart ──────────────────────────────────

  Widget _buildChartArea() {
    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF1A7A50)),
          ),
        ),
      );
    }

    final spots = _spots;

    if (spots.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(t('No data yet', 'ยังไม่มีข้อมูล'),
              style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    final (minX, maxX) = _xRange;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,    // Y-axis always 0–100 %
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF1A7A50),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),  // no dots — clean line
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A7A50).withValues(alpha: 0.3),
                    const Color(0xFF1A7A50).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 20,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: _labelInterval,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _xLabel(v.round()),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
        ),
      ),
    );
  }

  // ── Period buttons below chart: 1W | 1M | 1Y ─────────────────────────────────

  Widget _buildPeriodButtons() {
    final options = [
      ('week',  '1W'),
      ('month', '1M'),
      ('year',  '1Y'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((opt) {
        final active = opt.$1 == _period;
        return GestureDetector(
          onTap: () {
            if (!active) {
              setState(() => _period = opt.$1);
              _loadTrend();
            }
          },
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF1A7A50)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Summary row: avg % and trend arrow ───────────────────────────────────────

  Widget _buildSummaryRow() {
    if (_trendData.length < 2) return const SizedBox();

    final values = _trendData.map((e) => e.avgAccuracy * 100).toList();
    final avg    = values.reduce((a, b) => a + b) / values.length;
    final delta  = values.last - values.first;
    final isUp   = delta >= 0;
    final color  = isUp ? const Color(0xFF1A7A50) : const Color(0xFFFF8C42);
    final label  = switch (_period) {
      'week'  => t('this week',  'สัปดาห์นี้'),
      'month' => t('this month', 'เดือนนี้'  ),
      _       => t('this year',  'ปีนี้'     ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            t('Avg ${avg.toStringAsFixed(0)}%',
               'เฉลี่ย ${avg.toStringAsFixed(0)}%'),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Row(
            children: [
              Icon(isUp ? Icons.trending_up : Icons.trending_down,
                  size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '${isUp ? '+' : ''}${delta.toStringAsFixed(0)}%'
                ' ${t('over', 'ใน')} $label',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
