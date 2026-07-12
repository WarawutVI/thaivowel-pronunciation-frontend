import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/practiceELM/mic_check_modal.dart';
import 'package:frontend/pages/practice/vowel_grid_page.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:get/get.dart';

class Practicepage extends StatefulWidget {
  const Practicepage({super.key});

  @override
  State<Practicepage> createState() => _PracticepageState();
}

class _PracticepageState extends State<Practicepage> {
  bool isEnglish = true;

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
  }

  String t(String en, String th) => isEnglish ? en : th;

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Image.asset(imagePath, width: 80, height: 80),
          ],
        ),
      ),
    );
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Ready to practice?\nLet\'s go! 🚀',
                      'พร้อมฝึกแล้วใช่ไหม?\nไปเลย! 🚀'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'Pick a vowel length. Short or long vowel.',
                    'เลือกความยาวสระ สั้นหรือยาว ',
                  ),
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildCategoryCard(
            title: t('Long Vowel', 'สระเสียงยาว'),
            subtitle: t('9 stretched, resonant sounds', '9 เสียงยาวก้องกังวาน'),
            imagePath: 'assets/picture/longvowel.png',
            color: const Color(0xFF4A90D9),
            cardColor: const Color(0xFFB3D9FF),
            onTap: () => Get.to(() => const VowelGridPage(type: 'long')),
          ),
            _buildCategoryCard(
            title: t('Short Vowel', 'สระเสียงสั้น'),
            subtitle: t('9 quick, snappy sounds', '9 เสียงสั้นกระชับ'),
            imagePath: 'assets/picture/shortvowel.png',
            color: const Color(0xFFE05C6A),
            cardColor: const Color(0xFFFFB3BA),
            onTap: () => Get.to(() => const VowelGridPage(type: 'short')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showMicCheckModal(context, isEnglish: isEnglish),
                icon: const Icon(Icons.mic, color: Color(0xFF1A7A50)),
                label: Text(
                  t('Check your microphone', 'เช็คไมโครโฟนของคุณ'),
                  style: const TextStyle(
                    color: Color(0xFF1A7A50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1A7A50)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
