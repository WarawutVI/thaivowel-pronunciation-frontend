import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/pages/lessonspage.dart';
import 'package:frontend/pages/practicepage.dart';
import 'package:frontend/pages/progreespage.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with SingleTickerProviderStateMixin {
  bool isEnglish = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  String? _dbUsername;

  late final AnimationController _fireController;
  late final Animation<double> _fireOffset;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  String get _userName {
    if (_dbUsername != null && _dbUsername!.trim().isNotEmpty) {
      return _dbUsername!.trim().split(' ')[0];
    }
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ')[0];
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@')[0];
    }
    return t('there', 'เพื่อน');
  }

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
    _loadStreak();
    _loadUser();

    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _fireOffset = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _fireController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final profile = await PracticeApi.fetchUser(_uid);
      if (mounted) setState(() => _dbUsername = profile.username);
    } catch (_) {}
  }

  Future<void> _loadStreak() async {
    try {
      final s = await PracticeApi.fetchStreak(_uid);
      if (!mounted) return;
      setState(() {
        _currentStreak = s.currentStreak;
        _longestStreak = s.longestStreak;
      });
    } catch (_) {}
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildStreakBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Get.to(() => const Progreespage()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A7A50),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _fireOffset,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _fireOffset.value),
                    child: child,
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 50)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Hi, $_userName 👋', 'สวัสดี, $_userName 👋'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t('Daily streak', 'วันที่ฝึกต่อเนื่อง'),
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  Text(
                    t('$_currentStreak days ', ' $_currentStreak วัน'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    t('best $_longestStreak', 'สถิติ $_longestStreak'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
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
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right, color: Colors.white, size: 50),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
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
          LanguageToggleButton(
            isEnglish: isEnglish,
            onChanged: (v) {
              setState(() => isEnglish = v);
              Get.find<LanguageController>().setLanguage(v);
            },
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
            _buildStreakBanner(),
            const SizedBox(height: 8),
             _buildCard(
              title: t('Lessons', 'บทเรียน'),
              subtitle: t('Learn the basics', 'เรียนรู้พื้นฐาน'),
              color: const Color(0xFFC695FE),
              imagePath: 'assets/picture/lessons.png',
              onTap: () => Get.to(() => const Lessonspage()),
            ),
            _buildCard(
              title: t('Practice', 'ฝึกพูด'),
              subtitle: t('Record your vowels', 'บันทึกเสียงสระของคุณ'),
              color: const Color.fromARGB(255, 80, 160, 214),
              imagePath: 'assets/picture/practice.png',
              onTap: () => Get.to(() => const Practicepage()),
            ),
          
            _buildCard(
              title: t('Your Progress', 'ความก้าวหน้า'),
              subtitle: t('See your stats', 'ดูสถิติของคุณ'),
              color: const Color(0xFFFFA189),
              imagePath: 'assets/picture/yourprogress.png',
              onTap: () => Get.to(() => const Progreespage()),
            ),
            // const SizedBox(height: 10),
            Center(
              child: Image.asset(
                'assets/picture/iconpracticepage.png',
                height: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
