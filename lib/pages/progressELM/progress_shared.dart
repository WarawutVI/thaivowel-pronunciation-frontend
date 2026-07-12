import 'package:flutter/material.dart';

// ── Card wrapper used by every progress section ───────────────────────────────
class ProgressCard extends StatelessWidget {
  final Widget child;
  const ProgressCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}

// ── Long / short (/ all) vowel dropdown pill ─────────────────────────────────
class FilterPill extends StatelessWidget {
  final String value; // 'short' | 'long' | 'all' (if includeAll)
  final bool isEnglish;
  final bool includeAll;
  final ValueChanged<String> onChanged;

  const FilterPill({
    super.key,
    required this.value,
    required this.isEnglish,
    required this.onChanged,
    this.includeAll = false,
  });

  String _labelFor(String v) => switch (v) {
        'short' => isEnglish ? 'Short vowels' : 'สระเสียงสั้น',
        'long' => isEnglish ? 'Long vowels' : 'สระเสียงยาว',
        _ => isEnglish ? 'All vowels' : 'สระทั้งหมด',
      };

  PopupMenuItem<String> _item(String v) => PopupMenuItem(
        value: v,
        child: Row(
          children: [
            Icon(
              value == v ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: const Color(0xFF1A7A50),
            ),
            const SizedBox(width: 8),
            Text(
              _labelFor(v),
              style: TextStyle(
                fontSize: 13,
                fontWeight: value == v ? FontWeight.w600 : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(value);

    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      offset: const Offset(0, 36),
      itemBuilder: (_) => [
        if (includeAll) _item('all'),
        _item('short'),
        _item('long'),
      ],
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
              label,
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
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Returns EN or TH string based on language flag.
String pt(bool isEnglish, String en, String th) => isEnglish ? en : th;

/// Maps a 0–1 confidence value to a 4-level assessment color.
Color accuracyColor(double v) {
  final pct = (v * 100).round();
  if (pct >= 81) return const Color(0xFF1A7A50); // Excellent
  if (pct >= 51) return const Color(0xFF2A9B6A); // Good
  if (pct >= 30) return const Color(0xFFFF8C42); // Needs Improvement
  return const Color(0xFFE05C6A);                // Incorrect
}

/// Returns a 4-level assessment label based on confidence (0–1).
String assessmentLabel(double confidence, bool isEnglish) {
  final pct = (confidence * 100).round();
  if (pct >= 81) return isEnglish ? 'Excellent'         : 'ยอดเยี่ยม';
  if (pct >= 51) return isEnglish ? 'Good'              : 'ดี';
  if (pct >= 30) return isEnglish ? 'Needs Improvement' : 'ต้องพัฒนา';
  return             isEnglish ? 'Incorrect'         : 'ไม่ถูกต้อง';
}
