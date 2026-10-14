import 'package:flutter/material.dart';

// ── "New here?" banner ────────────────────────────────────────────────────────

class NewHereBanner extends StatelessWidget {
  final bool isEnglish;
  const NewHereBanner({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: Color(0xFF1A7A50),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish
                      ? 'Basic vowel pronunciation'
                      : 'การพื้นฐานออกเสียงสระ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                    children: isEnglish
                        ? const [
                            TextSpan(text: 'Vowel sounds are produced by the '),
                            TextSpan(
                              text: '"part of the tongue"',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: '"tongue height"',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text:
                                  ' used, which vary to create diverse and distinct vowel sounds.',
                            ),
                          ]
                        : const [
                            TextSpan(text: 'การออกเสียงสระเกิดจากการกำหนด '),
                            TextSpan(
                              text: '"ส่วนของลิ้น"',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(text: 'เเละ '),
                            TextSpan(
                              text: '"ระดับของลิ้น"',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text:
                                  'ที่เเตกต่างกันทำให้เกิดเสียงสระที่หลากหลายเเละชัดเจน',
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
