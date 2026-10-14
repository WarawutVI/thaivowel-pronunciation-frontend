import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/pair_recording_page.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';


class VowelPairGridPage extends StatefulWidget {
  const VowelPairGridPage({super.key});

  @override
  State<VowelPairGridPage> createState() => _VowelPairGridPageState();
}

class _VowelPairGridPageState extends State<VowelPairGridPage> {
  bool isEnglish = true;
  List<VowelPairProgress> pairs = [];
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
      final data = await PracticeApi.fetchVowelPairs(firebaseUid); //#7
      if (!mounted) return;
      setState(() {
        pairs = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  bool _isDone(VowelPairProgress p, bool longFirst) =>
      p.completed(longFirst: longFirst) >= 1;

  Color _cardColor(bool done) =>
      done ? const Color(0xFFD4F5E2) : const Color(0xFFF0F0F0);

  Color _borderColor(bool done) =>
      done ? const Color(0xFF1A7A50) : Colors.transparent;

  
  int get _totalExercises => pairs.length * 2; // total short and long before =18

  int get _completedPairs =>
      pairs.where((p) => _isDone(p, false)).length +
      pairs.where((p) => _isDone(p, true)).length;

  Widget _sectionHeader({required bool longFirst}) {
    final done = pairs.where((p) => _isDone(p, longFirst)).length;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                longFirst
                    ? t('Start with Long Vowel', 'เริ่มจากสระเสียงยาว')
                    : t('Start with Short Vowel', 'เริ่มจากสระเสียงสั้น'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6B45),
                ),
              ),
            ),
            Text(
              '$done / ${pairs.length}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionGrid({required bool longFirst}) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6, // width / height   ratio of each item
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _pairCard(pairs[index], longFirst),
        childCount: pairs.length,
      ),
    );
  }

  Widget _pairCard(VowelPairProgress pair, bool longFirst) {
    final firstSymbol = longFirst ? pair.longSymbol : pair.shortSymbol;
    final secondSymbol = longFirst ? pair.shortSymbol : pair.longSymbol;
    final done = _isDone(pair, longFirst);
    return GestureDetector(
      onTap: () async {
        await Get.to(() => PairRecordingPage(
              shortVowelId: pair.shortVowelId,
              shortSymbol: pair.shortSymbol,
              longVowelId: pair.longVowelId,
              longSymbol: pair.longSymbol,
              longFirst: longFirst,
              isEnglish: isEnglish,
            ));

        if (!mounted) return;
        setState(() => loading = true);
        _load();
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _cardColor(done),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor(done), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      firstSymbol,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward,
                          size: 16, color: Color(0xFF2A9B6A)),
                    ),
                    Text(
                      secondSymbol,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${done ? 1 : 0}/1',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (done)
            const Positioned(
              top: 6,
              right: 6,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Color(0xFF1A7A50),
                child: Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

// main display
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
                          child: Text(t('Retry', 'ลองอีกครั้ง'))),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              t('Vowel Pairs', 'สระเสียงใกล้เคียงกัน'),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A9B6A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_completedPairs / $_totalExercises',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(
                          'Record both vowels in one take',
                          'อัดเสียงสระทั้งสองคำในครั้งเดียว',
                        ),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pairs.isEmpty
                              ? 0
                              : _completedPairs / _totalExercises,
                          backgroundColor: const Color(0xFFDDDDDD),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2A9B6A)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            _sectionHeader(longFirst: false),
                            _sectionGrid(longFirst: false),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 24)),
                            _sectionHeader(longFirst: true),
                            _sectionGrid(longFirst: true),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 20)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
