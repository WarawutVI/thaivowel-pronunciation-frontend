class VowelPairProgress {
  final int shortVowelId;
  final String shortSymbol;
  final int longVowelId;
  final String longSymbol;
  final int completed;

  const VowelPairProgress({
    required this.shortVowelId,
    required this.shortSymbol,
    required this.longVowelId,
    required this.longSymbol,
    required this.completed,
  });

  factory VowelPairProgress.fromJson(Map<String, dynamic> j) =>
      VowelPairProgress(
        shortVowelId: j['short_vowel_id'] as int,
        shortSymbol: j['short_symbol'] as String,
        longVowelId: j['long_vowel_id'] as int,
        longSymbol: j['long_symbol'] as String,
        completed: j['completed'] as int,
      );
}
