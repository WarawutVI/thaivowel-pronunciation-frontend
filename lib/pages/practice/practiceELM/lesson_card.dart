import 'package:flutter/material.dart';
import 'package:frontend/services/practice_api.dart';

Color lessonCardColor(LessonProgress l) {
  if (l.isCompleted == null) return Colors.white;
  if (l.isCompleted == true) return const Color(0xFFD4F5E2);
  return const Color(0xFFFFE5CC);
}

Color lessonBorderColor(LessonProgress l) {
  if (l.isCompleted == null) return const Color(0xFFDDDDDD);
  if (l.isCompleted == true) return const Color(0xFF1A7A50);
  return const Color(0xFFFF8C42);
}

class LessonStatusBadge extends StatelessWidget {
  final LessonProgress lesson;
  const LessonStatusBadge(this.lesson, {super.key});

  @override
  Widget build(BuildContext context) {
    if (lesson.isCompleted == null) return const SizedBox.shrink();
    return Positioned(
      top: 6,
      right: 6,
      child: CircleAvatar(
        radius: 10,
        backgroundColor: lesson.isCompleted == true
            ? const Color(0xFF1A7A50)
            : const Color(0xFFFF8C42),
        child: Icon(
          lesson.isCompleted == true ? Icons.check : Icons.close,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

class VowelLessonCard extends StatelessWidget {
  final LessonProgress lesson;
  final VoidCallback onTap;
  const VowelLessonCard(
      {super.key, required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: lessonCardColor(lesson),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: lessonBorderColor(lesson), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lesson.lessonName,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (lesson.unicodePhonetic != null)
                      Text(
                        lesson.unicodePhonetic!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A7A50),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.mic, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          LessonStatusBadge(lesson),
        ],
      ),
    );
  }
}

class WordLessonCard extends StatelessWidget {
  final LessonProgress lesson;
  final VoidCallback onTap;
  const WordLessonCard(
      {super.key, required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: lessonCardColor(lesson),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: lessonBorderColor(lesson), width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lesson.lessonName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (lesson.unicodePhonetic != null)
                    Text(
                      lesson.unicodePhonetic!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                ],
              ),
            ),
          ),
          LessonStatusBadge(lesson),
        ],
      ),
    );
  }
}
