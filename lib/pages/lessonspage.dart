import 'package:flutter/material.dart';
import 'package:frontend/pages/lessonsELM/new_here_banner.dart';
import 'package:frontend/pages/lessonsELM/tongue_height_section.dart';
import 'package:frontend/pages/lessonsELM/tongue_section.dart';
import 'package:frontend/pages/lessonsELM/vowel_section.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

class Lessonspage extends StatefulWidget {
  const Lessonspage({super.key});

  @override
  State<Lessonspage> createState() => _LessonspageState();
}

class _LessonspageState extends State<Lessonspage> {
  bool isEnglish = true;
  bool loading = true;
  List<VowelDetail> _vowels = [];
  String? _error;

  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; _error = null; });
    try {
      final data = await PracticeApi.fetchVowelDetails(); // #6
      if (!mounted) return;
      setState(() { _vowels = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); loading = false; });
    }
  }

// main display
  @override
  Widget build(BuildContext context) {
    final longVowels  = _vowels.where((v) => v.vowelType == 'long').toList();
    final shortVowels = _vowels.where((v) => v.vowelType == 'short').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          t('Lessons', 'บทเรียน'),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A7A50)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A7A50)),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator( // loading is false and no error, show the content
                  onRefresh: _load,
                  color: const Color(0xFF1A7A50),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      NewHereBanner(isEnglish: isEnglish),
                      const SizedBox(height: 24),
                      TongueSection(isEnglish: isEnglish),
                      const SizedBox(height: 24),
                      TongueHeightSection(isEnglish: isEnglish),
                      const SizedBox(height: 50),
                      Text(
                        t(
                          'Want to know how to pronounce a vowel? Tap on it.',
                          'หากต้องการทราบวิธีออกเสียงสระ ให้กดที่สระนั้น',
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      VowelSection(
                        title: t('Long Vowels', 'สระเสียงยาว'),
                        vowels: longVowels,
                        isEnglish: isEnglish,
                      ),
                      const SizedBox(height: 28),
                      VowelSection(
                        title: t('Short Vowels', 'สระเสียงสั้น'),
                        vowels: shortVowels,
                        isEnglish: isEnglish,
                      ),
                    ],
                  ),
                ),
    );
  }
}

