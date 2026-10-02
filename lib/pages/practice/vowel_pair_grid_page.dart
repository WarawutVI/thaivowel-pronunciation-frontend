import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/pair_recording_page.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

/// Grid of vowel pairs that sound alike (e.g. อะ → อา), backed by
/// GET /vowel_pairs. Tapping a card opens PairRecordingPage.
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
      final data = await PracticeApi.fetchVowelPairs(firebaseUid);
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

  bool _isDone(VowelPairProgress p) => p.completed >= 1;

  Color _cardColor(VowelPairProgress p) =>
      _isDone(p) ? const Color(0xFFD4F5E2) : const Color(0xFFF0F0F0);

  Color _borderColor(VowelPairProgress p) =>
      _isDone(p) ? const Color(0xFF1A7A50) : Colors.transparent;

  int get _completedPairs => pairs.where(_isDone).length;

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
                              '$_completedPairs / ${pairs.length}',
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
                              : _completedPairs / pairs.length,
                          backgroundColor: const Color(0xFFDDDDDD),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2A9B6A)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          itemCount: pairs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.6,
                          ),
                          itemBuilder: (context, index) {
                            final pair = pairs[index];
                            return GestureDetector(
                              onTap: () async {
                                await Get.to(() => PairRecordingPage(
                                      shortVowelId: pair.shortVowelId,
                                      shortSymbol: pair.shortSymbol,
                                      longVowelId: pair.longVowelId,
                                      longSymbol: pair.longSymbol,
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
                                      color: _cardColor(pair),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: _borderColor(pair), width: 2),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              pair.shortSymbol,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6),
                                              child: Icon(Icons.arrow_forward,
                                                  size: 16,
                                                  color: Color(0xFF2A9B6A)),
                                            ),
                                            Text(
                                              pair.longSymbol,
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
                                          '${_isDone(pair) ? 1 : 0}/1',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isDone(pair))
                                    const Positioned(
                                      top: 6,
                                      right: 6,
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Color(0xFF1A7A50),
                                        child: Icon(Icons.check,
                                            size: 12, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
