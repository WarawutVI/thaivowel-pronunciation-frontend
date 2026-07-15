import 'package:flutter/material.dart';
import 'package:frontend/pages/lessons/vowel_detail_page.dart';
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
      final data = await PracticeApi.fetchVowelDetails();
      if (!mounted) return;
      setState(() { _vowels = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); loading = false; });
    }
  }

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
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF1A7A50),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _NewHereBanner(isEnglish: isEnglish),
                      const SizedBox(height: 24),
                      _TongueSection(isEnglish: isEnglish),
                      const SizedBox(height: 24),
                      _TongueHeightSection(isEnglish: isEnglish),
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
                      _VowelSection(
                        title: t('Long Vowels', 'สระเสียงยาว'),
                        vowels: longVowels,
                        isEnglish: isEnglish,
                      ),
                      const SizedBox(height: 28),
                      _VowelSection(
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

// ── "New here?" banner ────────────────────────────────────────────────────────

class _NewHereBanner extends StatelessWidget {
  final bool isEnglish;
  const _NewHereBanner({required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: Color(0xFF1A7A50), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Basic vowel pronunciation' : 'การพื้นฐานออกเสียงสระ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                    children: isEnglish
                        ? const [
                            TextSpan(text: 'Vowel sounds are produced by the '),
                            TextSpan(
                              text: '"part of the tongue"',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: '"tongue height"',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text:
                                  ' used, which vary to create diverse and distinct vowel sounds.',
                            ),
                          ]
                        : const [
                            TextSpan(text: 'การออกเสียงสระเกิดจากการกำหนด '),
                            TextSpan(
                              text: '"ส่วนของลิ้น"',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(text: 'เเละ '),
                            TextSpan(
                              text: '"ระดับของลิ้น"',
                              style: TextStyle(color: Colors.black87),
                            ),
                            TextSpan(
                              text:
                                  'ที่เเตกต่างกันทำให้เกิดเสียงสระที่หลากหลายเเละชัดเจน',
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── "Parts of the tongue" section ───────────────────────────────────────────

class _TongueSection extends StatelessWidget {
  final bool isEnglish;
  const _TongueSection({required this.isEnglish});

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

// ── "Tongue height" section ─────────────────────────────────────────────────

class _TongueHeightSection extends StatefulWidget {
  final bool isEnglish;
  const _TongueHeightSection({required this.isEnglish});

  @override
  State<_TongueHeightSection> createState() => _TongueHeightSectionState();
}

class _TongueHeightSectionState extends State<_TongueHeightSection> {
  static const _levels = [
    (image: 1, en: 'High', th: 'สูง'),
    (image: 2, en: 'Semi-high', th: 'กึ่งสูง'),
    (image: 3, en: 'Semi-low', th: 'กึ่งต่ำ'),
    (image: 4, en: 'Low', th: 'ต่ำ'),
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.isEnglish
        ? (String en, String th) => en
        : (String en, String th) => th;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Tongue Height', 'ระดับของลิ้น'),
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
            'assets/lessons/slide/${_levels[_selected].image}.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < _levels.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selected == i
                          ? const Color(0xFF1A7A50)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selected == i
                            ? const Color(0xFF1A7A50)
                            : Colors.black12,
                      ),
                    ),
                    child: Text(
                      t(_levels[i].en, _levels[i].th),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selected == i ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Section (Long / Short) with 3×3 grid ─────────────────────────────────────

class _VowelSection extends StatelessWidget {
  final String title;
  final List<VowelDetail> vowels;
  final bool isEnglish;

  const _VowelSection({
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
          itemBuilder: (_, i) => _VowelCard(vowel: vowels[i], isEnglish: isEnglish),
        ),
      ],
    );
  }
}

// ── Individual vowel card ─────────────────────────────────────────────────────

class _VowelCard extends StatelessWidget {
  final VowelDetail vowel;
  final bool isEnglish;
  const _VowelCard({required this.vowel, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => VowelDetailPage(vowel: vowel, isEnglish: isEnglish),
        transition: Transition.rightToLeft,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vowel.symbol,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vowel.unicodePhonetic ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A7A50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
