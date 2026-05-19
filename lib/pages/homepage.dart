import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/lessonspage.dart';
import 'package:frontend/pages/practicepage.dart';
import 'package:frontend/pages/progreespage.dart';
import 'package:get/get.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool isEnglish = true;

  String t(String en, String th) => isEnglish ? en : th;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Color color,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Image.asset(imagePath, width: 56, height: 56),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF4FAF7),
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black26,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          t('Home', 'หน้าหลัก'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => isEnglish = !isEnglish),
            icon: const Icon(Icons.language, color: Colors.black54, size: 26),
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.black54, size: 26),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildCard(
              title: t('Practice', 'ฝึกพูด'),
              subtitle: t('Record your vowels', 'บันทึกเสียงสระของคุณ'),
              color: const Color(0xFFFF828D),
              imagePath: 'assets/picture/practice.png',
              onTap: () => Get.to(() => const Practicepage()),
            ),
            _buildCard(
              title: t('Lessons', 'บทเรียน'),
              subtitle: t('Learn the basics', 'เรียนรู้พื้นฐาน'),
              color: const Color(0xFFC695FE),
              imagePath: 'assets/picture/lessons.png',
              onTap: () => Get.to(() => const Lessonspage()),
            ),
            _buildCard(
              title: t('Your Progress', 'ความก้าวหน้า'),
              subtitle: t('See your stats', 'ดูสถิติของคุณ'),
              color: const Color(0xFFFFA189),
              imagePath: 'assets/picture/yourprogress.png',
              onTap: () => Get.to(() => const Progreespage()),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                t('Have Fun with Thai Vowels', 'สนุกกับสระภาษาไทย'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                'assets/picture/iconpracticepage.png',
                height: 300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
