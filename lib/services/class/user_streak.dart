class UserStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastPracticeDate;

  const UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastPracticeDate,
  });

  factory UserStreak.fromJson(Map<String, dynamic> j) => UserStreak(
        currentStreak: (j['current_streak'] ?? 0) as int,
        longestStreak: (j['longest_streak'] ?? 0) as int,
        lastPracticeDate: j['last_practice_date'] as String?,
      );
}
