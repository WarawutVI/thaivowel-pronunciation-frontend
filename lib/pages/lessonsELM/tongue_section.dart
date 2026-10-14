import 'package:flutter/material.dart';

// ── "Parts of the tongue" section ───────────────────────────────────────────

class TongueSection extends StatelessWidget {
  final bool isEnglish;
  const TongueSection({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Parts of the Tongue' : 'ส่วนของลิ้น',
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
            'assets/lessons/1.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
