import 'package:flutter/material.dart';

// ── "Tongue height" section ─────────────────────────────────────────────────

class TongueHeightSection extends StatefulWidget {
  final bool isEnglish;
  const TongueHeightSection({super.key, required this.isEnglish});

  @override
  State<TongueHeightSection> createState() => _TongueHeightSectionState();
}

class _TongueHeightSectionState extends State<TongueHeightSection> {
  static const _levels = [
    (image: 1, en: 'High', th: 'สูง'),
    (image: 2, en: 'Middle', th: 'กึ่งกลาง'),
    (image: 3, en: 'Low', th: 'ต่ำ'),
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.isEnglish
        ? (String en, String th) => en
        : (String en, String th) => th;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Tongue Height', 'ระดับของลิ้น'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/lessons/slide/${_levels[_selected].image}.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < _levels.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selected == i
                          ? const Color(0xFF1A7A50)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selected == i
                            ? const Color(0xFF1A7A50)
                            : Colors.black12,
                      ),
                    ),
                    child: Text(
                      t(_levels[i].en, _levels[i].th),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selected == i ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
