import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/homepage.dart';
import 'package:frontend/pages/practice/practiceELM/lesson_card.dart';
import 'package:frontend/pages/practice/practiceELM/section_badge.dart';
import 'package:frontend/pages/practice/practiceELM/vowel_info_dialog.dart';
import 'package:frontend/pages/practice/recording_page.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

class WordGridPage extends StatefulWidget {
  final int vowelId;
  final String vowelSymbol;
  final String vowelType;
  final bool isEnglish;

  const WordGridPage({
    super.key,
    required this.vowelId,
    required this.vowelSymbol,
    required this.vowelType,
    this.isEnglish = true,
  });

  @override
  State<WordGridPage> createState() => _WordGridPageState();
}

class _WordGridPageState extends State<WordGridPage> {
  late bool isEnglish;
  LessonProgress? _vowelLesson;
  List<LessonProgress> _wordLessons = [];
  bool loading = true;
  String? error;

  String get firebaseUid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await PracticeApi.fetchLessons(firebaseUid, widget.vowelId);
      setState(() {
        _vowelLesson = data.where((l) => l.lessonOrder == 1).firstOrNull;
        _wordLessons = data.where((l) => l.lessonOrder != 1).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _tapLesson(LessonProgress l) async {
    await Get.to(() => RecordingPage(
          lessonId: l.lessonId,
          lessonOrder: l.lessonOrder,
          vowelId: widget.vowelId,
          word: l.lessonName,
          wordIpa: l.unicodePhonetic,
          vowelSymbol: widget.vowelSymbol,
          isEnglish: isEnglish,
        ));
    setState(() => loading = true);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          t('Practice', 'ฝึกพูด'),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            loading = true;
                            error = null;
                          });
                          _load();
                        },
                        child: Text(t('Retry', 'ลองอีกครั้ง')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vowel symbol + info button
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.vowelSymbol,
                                  style: const TextStyle(
                                    fontSize: 70,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => showVowelInfoDialog(
                                      context,
                                      widget.vowelId,
                                      widget.vowelSymbol,
                                      isEnglish),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A7A50),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.info_outline,
                                        color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Section 1: just the vowel
                            if (_vowelLesson != null) ...[
                              Row(
                                children: [
                                  const SectionBadge(1),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('just the vowel', 'แค่สระ'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('say it alone', 'ออกเสียงเดี่ยว'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              VowelLessonCard(
                                lesson: _vowelLesson!,
                                onTap: () => _tapLesson(_vowelLesson!),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Section 2: with letters
                            if (_wordLessons.isNotEmpty) ...[
                              Row(
                                children: [
                                  const SectionBadge(2),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('With letters', 'คำที่ใช้สระนี้'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('${_wordLessons.length} words',
                                        '${_wordLessons.length} คำ'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: _wordLessons.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                                itemBuilder: (context, index) {
                                  final l = _wordLessons[index];
                                  return WordLessonCard(
                                    lesson: l,
                                    onTap: () => _tapLesson(l),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Home button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: GestureDetector(
                        onTap: () => Get.offAll(() => Homepage()),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A6B45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
