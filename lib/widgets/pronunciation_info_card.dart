import 'package:flutter/material.dart';

/// White rounded card used in the "How to pronounce" grid — a small green
/// uppercase label above a bold value, laid out 2 per row by [PronunciationInfoGrid].
class PronunciationInfoCard extends StatelessWidget {
  final String label;
  final String value;

  const PronunciationInfoCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A7A50),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays out label/value pairs as a 2-column grid of [PronunciationInfoCard]s.
class PronunciationInfoGrid extends StatelessWidget {
  final List<MapEntry<String, String>> items;

  const PronunciationInfoGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final hasSecond = i + 1 < items.length;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PronunciationInfoCard(
              label: items[i].key,
              value: items[i].value,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: hasSecond
                ? PronunciationInfoCard(
                    label: items[i + 1].key,
                    value: items[i + 1].value,
                  )
                : const SizedBox(),
          ),
        ],
      ));
    }
    return Column(children: rows);
  }
}
