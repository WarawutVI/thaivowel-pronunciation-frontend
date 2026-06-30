class LessonProgress {
  final int lessonId;
  final int lessonOrder;
  final String lessonName;
  final bool? isCompleted;
  final double bestAccuracy;
  final int attempts;

  const LessonProgress({
    required this.lessonId,
    required this.lessonOrder,
    required this.lessonName,
    required this.isCompleted,
    required this.bestAccuracy,
    required this.attempts,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        lessonId: j['lesson_id'] as int,
        lessonOrder: j['lesson_order'] as int,
        lessonName: j['lesson_name'] as String,
        isCompleted: j['is_completed'] == null ? null : (j['is_completed'] as int) == 1,
        bestAccuracy: (j['best_accuracy'] ?? 0.0).toDouble(),
        attempts: (j['attempts'] ?? 0) as int,
      );
}
