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

// ── Long / short vowel dropdown pill ─────────────────────────────────────────
class FilterPill extends StatelessWidget {
  final String value; // 'short' | 'long'
  final bool isEnglish;
  final ValueChanged<String> onChanged;

  const FilterPill({
    super.key,
    required this.value,
    required this.isEnglish,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = value == 'short'
        ? (isEnglish ? 'Short vowels' : 'สระเสียงสั้น')
        : (isEnglish ? 'Long vowels' : 'สระเสียงยาว');

    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      offset: const Offset(0, 36),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'short',
          child: Row(
            children: [
              Icon(
                value == 'short' ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: const Color(0xFF1A7A50),
              ),
              const SizedBox(width: 8),
              Text(
                isEnglish ? 'Short vowels' : 'สระเสียงสั้น',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: value == 'short' ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'long',
          child: Row(
            children: [
              Icon(
                value == 'long' ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: const Color(0xFF1A7A50),
              ),
              const SizedBox(width: 8),
              Text(
                isEnglish ? 'Long vowels' : 'สระเสียงยาว',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: value == 'long' ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
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

/// Maps a 0–1 accuracy value to a traffic-light color.
Color accuracyColor(double v) {
  if (v >= 0.70) return const Color(0xFF1A7A50);
  if (v >= 0.50) return const Color(0xFFFF8C42);
  return const Color(0xFFE05C6A);
}
