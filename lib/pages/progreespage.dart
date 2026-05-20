import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/word_grid_page.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class Progreespage extends StatefulWidget {
  const Progreespage({super.key});

  @override
  State<Progreespage> createState() => _ProgreespageState();
}

class _ProgreespageState extends State<Progreespage> {
  bool isEnglish = true;
  bool loading = true;
  String? error;

  ProgressSummary? _summary;
  UserStreak? _streak;
  List<VowelStats> _shortStats = [];
  List<VowelStats> _longStats = [];
  List<SessionRecord> _recentSessions = [];
  List<DailyTrend> _shortTrend = [];
  List<DailyTrend> _longTrend = [];

  String _barType = 'short';
  String _trendType = 'short';

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        PracticeApi.fetchSummary(_uid),
        PracticeApi.fetchStreak(_uid),
        PracticeApi.fetchVowelStats(_uid, 'short'),
        PracticeApi.fetchVowelStats(_uid, 'long'),
        PracticeApi.fetchRecentSessions(_uid),
        PracticeApi.fetchTrend(_uid, 'short'),
        PracticeApi.fetchTrend(_uid, 'long'),
      ]);
      setState(() {
        _summary = results[0] as ProgressSummary;
        _streak = results[1] as UserStreak;
        _shortStats = results[2] as List<VowelStats>;
        _longStats = results[3] as List<VowelStats>;
        _recentSessions = results[4] as List<SessionRecord>;
        _shortTrend = results[5] as List<DailyTrend>;
        _longTrend = results[6] as List<DailyTrend>;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  List<VowelStats> get _barStats =>
      _barType == 'short' ? _shortStats : _longStats;

  List<DailyTrend> get _trendData =>
      _trendType == 'short' ? _shortTrend : _longTrend;

  List<VowelStats> get _weakVowels {
    final all = [..._shortStats, ..._longStats]
        .where((v) => v.practiceCount > 0)
        .toList()
      ..sort((a, b) => a.avgAccuracy.compareTo(b.avgAccuracy));
    return all.take(3).toList();
  }

  Color _accuracyColor(double v) {
    if (v >= 0.70) return const Color(0xFF1A7A50);
    if (v >= 0.50) return const Color(0xFFFF8C42);
    return const Color(0xFFE05C6A);
  }

  String _sessionLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(dt.year, dt.month, dt.day);
    final time = DateFormat('HH:mm').format(dt);
    if (sessionDay == today) return '${t('Today', 'วันนี้')} · $time';
    if (sessionDay == today.subtract(const Duration(days: 1))) {
      return '${t('Yesterday', 'เมื่อวาน')} · $time';
    }
    return '${DateFormat('MMM d').format(dt)} · $time';
  }

  Widget _buildCard(Widget child) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _buildDropdown(String value, ValueChanged<String> onChanged) =>
      GestureDetector(
        onTap: () => onChanged(value == 'short' ? 'long' : 'short'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5EE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1A7A50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value == 'short'
                    ? t('short vowels', 'สระสั้น')
                    : t('long vowels', 'สระยาว'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1A7A50),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: Color(0xFF1A7A50)),
            ],
          ),
        ),
      );

  Widget _buildSummaryCard() {
    final s = _summary!;
    final accuracy = (s.overallAccuracy * 100).round();
    final best = (s.bestAccuracy * 100).round();
    final streak = _streak?.currentStreak ?? 0;

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
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 130,
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
                  _buildStat(t('SESSIONS', 'ครั้ง'), '${s.totalSessions}'),
                  const SizedBox(width: 24),
                  _buildStat(t('BEST', 'ดีที่สุด'), '$best%'),
                  const SizedBox(width: 24),
                  _buildStat(t('STREAK', 'วันต่อเนื่อง'), '$streak 🔥'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildPracticeCount() {
    final stats = _barStats;
    if (stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(t('No data yet', 'ยังไม่มีข้อมูล'),
              style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    final maxY = stats
        .map((v) => v.practiceCount)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('Practice Count', 'จำนวนครั้งที่ฝึก'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            _buildDropdown(_barType, (v) => setState(() => _barType = v)),
          ],
        ),
        const SizedBox(height: 16),
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

  Widget _buildDonut(double accuracy, String label, Color color) {
    final clamped = accuracy.clamp(0.0, 1.0);
    final pct = (accuracy * 100).round();
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
                  color: color,
                ),
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

  Widget _buildAvgAccuracy() {
    final s = _summary!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('Average Accuracy', 'ความแม่นยำเฉลี่ย'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDonut(
              s.longAvgAccuracy,
              t('Long vowels', 'สระเสียงยาว'),
              const Color(0xFF1A7A50),
            ),
            _buildDonut(
              s.shortAvgAccuracy,
              t('Short vowels', 'สระเสียงสั้น'),
              const Color(0xFFFF8C42),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrend() {
    final trend = _trendData;
    // x-axis: 0=Sun, 1=Mon, …, 6=Sat (DateTime.weekday % 7 gives this mapping)
    const dayAbbrEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const dayAbbrTh = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

    // Map each entry to its day-of-week x position so the full Sun–Sat axis
    // always renders correctly regardless of which days have data.
    final spots = trend
        .map((e) => FlSpot(
              (e.date.weekday % 7).toDouble(), // 0=Sun … 6=Sat
              e.avgAccuracy * 100,
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('Accuracy Trend', 'แนวโน้มความแม่นยำ'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            _buildDropdown(
                _trendType, (v) => setState(() => _trendType = v)),
          ],
        ),
        const SizedBox(height: 16),
        if (spots.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(t('No data yet', 'ยังไม่มีข้อมูล'),
                  style: const TextStyle(color: Colors.grey)),
            ),
          )
        else
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: spots.length > 2,
                    color: const Color(0xFF1A7A50),
                    barWidth: 2.5,
                    dotData: FlDotData(show: spots.length <= 4),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1A7A50).withValues(alpha: 0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i < 0 || i > 6) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isEnglish ? dayAbbrEn[i] : dayAbbrTh[i],
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('Recent Sessions', 'เซสชันล่าสุด'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 12),
        if (_recentSessions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(t('No sessions yet', 'ยังไม่มีเซสชัน'),
                  style: const TextStyle(color: Colors.grey)),
            ),
          )
        else
          ..._recentSessions.map(_buildSessionRow),
      ],
    );
  }

  Widget _buildSessionRow(SessionRecord s) {
    final color = _accuracyColor(s.confidence);
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLong
                      ? t('Long vowel', 'สระเสียงยาว')
                      : t('Short vowel', 'สระเสียงสั้น'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                Text(_sessionLabel(s.practicedAt),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$pct%',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeakVowels() {
    final weak = _weakVowels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('Vowels to work on', 'สระที่ต้องฝึกเพิ่ม'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 4),
        Text(
          t('how the app records your practice',
              'วิธีที่แอปบันทึกการฝึกของคุณ'),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (weak.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  t('Practice more to see suggestions!',
                      'ฝึกเพิ่มเพื่อดูคำแนะนำ!'),
                  style: const TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...weak.map((v) {
            final pct = (v.avgAccuracy * 100).round();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(v.symbol,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('Average $pct%', 'เฉลี่ย $pct%'),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                        Text(
                            t('${v.practiceCount} attempts',
                                '${v.practiceCount} ครั้ง'),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(t('Try again', 'ลองอีกครั้ง'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(t('Your Progress', 'ความก้าวหน้า'),
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => setState(() => isEnglish = !isEnglish),
            icon: const Icon(Icons.language, color: Colors.black54),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF1A7A50)))
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 40),
                      const SizedBox(height: 12),
                      Text(
                          t('Failed to load data',
                              'โหลดข้อมูลไม่สำเร็จ'),
                          style:
                              const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A7A50),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(t('Retry', 'ลองอีกครั้ง')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF1A7A50),
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildCard(_buildPracticeCount()),
                        const SizedBox(height: 16),
                        _buildCard(_buildAvgAccuracy()),
                        const SizedBox(height: 16),
                        _buildCard(_buildTrend()),
                        const SizedBox(height: 16),
                        _buildCard(_buildRecentSessions()),
                        const SizedBox(height: 16),
                        _buildCard(_buildWeakVowels()),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }
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
      final y = size.height - barH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, barH),
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
