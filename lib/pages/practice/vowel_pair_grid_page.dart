import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/pair_recording_page.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

class _VowelPair {
  final VowelProgress short;
  final VowelProgress long;

  const _VowelPair(this.short, this.long);
}

/// Grid of vowel pairs that sound alike (e.g. อะ → อา). Pairs are formed by
/// zipping the short/long vowel lists in fetch order — assumes each vowel's
/// short/long counterpart shares the same position in its list.
class VowelPairGridPage extends StatefulWidget {
  const VowelPairGridPage({super.key});

  @override
  State<VowelPairGridPage> createState() => _VowelPairGridPageState();
}

class _VowelPairGridPageState extends State<VowelPairGridPage> {
  bool isEnglish = true;
  List<_VowelPair> pairs = [];
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
      final shorts = await PracticeApi.fetchVowels(firebaseUid, 'short');
      final longs = await PracticeApi.fetchVowels(firebaseUid, 'long');
      final count = shorts.length < longs.length ? shorts.length : longs.length;
      if (!mounted) return;
      setState(() {
        pairs = List.generate(count, (i) => _VowelPair(shorts[i], longs[i]));
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
                      Text(
                        t('Vowel Pairs', 'สระเสียงใกล้เคียงกัน'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(
                          'Record both vowels in one take',
                          'อัดเสียงสระทั้งสองคำในครั้งเดียว',
                        ),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                              onTap: () => Get.to(() => PairRecordingPage(
                                    shortVowel: pair.short,
                                    longVowel: pair.long,
                                    isEnglish: isEnglish,
                                  )),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      pair.short.symbol,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 6),
                                      child: Icon(Icons.arrow_forward,
                                          size: 16, color: Color(0xFF2A9B6A)),
                                    ),
                                    Text(
                                      pair.long.symbol,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
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
