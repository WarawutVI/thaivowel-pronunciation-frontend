import 'package:flutter/material.dart';
import 'package:frontend/pages/lessonsELM/vowel_card.dart';
import 'package:frontend/services/class/vowel_detail.dart';

// ── Section (Long / Short) with 3×3 grid ─────────────────────────────────────

class VowelSection extends StatelessWidget {
  final String title;
  final List<VowelDetail> vowels;
  final bool isEnglish;

  const VowelSection({
    super.key,
    required this.title,
    required this.vowels,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              isEnglish ? '${vowels.length} sounds' : '${vowels.length} เสียง',
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: vowels.length,
          itemBuilder: (_, i) =>
              VowelCard(vowel: vowels[i], isEnglish: isEnglish),
        ),
      ],
    );
  }
}
