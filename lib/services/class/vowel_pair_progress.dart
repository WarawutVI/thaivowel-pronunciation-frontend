class VowelPairProgress {
  final int shortVowelId;
  final String shortSymbol;
  final int longVowelId;
  final String longSymbol;
  // Passed attempts per direction: short → long, and long → short.
  final int completedShortFirst;
  final int completedLongFirst;
  // All attempts per direction, passed or not.
  final int attemptedShortFirst;
  final int attemptedLongFirst;

  const VowelPairProgress({
    required this.shortVowelId,
    required this.shortSymbol,
    required this.longVowelId,
    required this.longSymbol,
    required this.completedShortFirst,
    required this.completedLongFirst,
    this.attemptedShortFirst = 0,
    this.attemptedLongFirst = 0,
  });

  int completed({required bool longFirst}) =>
      longFirst ? completedLongFirst : completedShortFirst;

  int attempted({required bool longFirst}) =>
      longFirst ? attemptedLongFirst : attemptedShortFirst;

  factory VowelPairProgress.fromJson(Map<String, dynamic> j) =>
      VowelPairProgress(
        shortVowelId: j['short_vowel_id'] as int,
        shortSymbol: j['short_symbol'] as String,
        longVowelId: j['long_vowel_id'] as int,
        longSymbol: j['long_symbol'] as String,
        completedShortFirst: j['completed_short_first'] as int? ?? 0,
        completedLongFirst: j['completed_long_first'] as int? ?? 0,
        attemptedShortFirst: j['attempted_short_first'] as int? ?? 0,
        attemptedLongFirst: j['attempted_long_first'] as int? ?? 0,
      );
}
