import 'package:flutter/material.dart';
import 'package:frontend/pages/lessonsELM/vowel_detail_page.dart';
import 'package:frontend/services/class/vowel_detail.dart';
import 'package:get/get.dart';

// ── Individual vowel card ─────────────────────────────────────────────────────

class VowelCard extends StatelessWidget {
  final VowelDetail vowel;
  final bool isEnglish;
  const VowelCard({super.key, required this.vowel, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => VowelDetailPage(vowel: vowel, isEnglish: isEnglish),
        transition: Transition.rightToLeft,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vowel.symbol,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vowel.unicodePhonetic ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A7A50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
