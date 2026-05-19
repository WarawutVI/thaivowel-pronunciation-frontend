import 'package:flutter/material.dart';
import 'package:frontend/auth/age.dart';
import 'package:get/get.dart';

class GenderPage extends StatefulWidget {
  final String username;
  final String email;
  final String password;
  final bool isEnglish;

  const GenderPage({
    super.key,
    required this.username,
    required this.email,
    required this.password,
    this.isEnglish = true,
  });

  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  String? selectedGender;
  late bool isEnglish;

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
  }

  String t(String en, String th) => isEnglish ? en : th;

  void _proceed(String? gender) {
    Get.to(() => Agepage(
          username: widget.username,
          email: widget.email,
          password: widget.password,
          gender: gender,
          isEnglish: isEnglish,
        ));
  }

  Widget _buildGenderIcon(String gender) {
    final isSelected = selectedGender == gender;
    final color =
        isSelected ? const Color(0xFF1A7A50) : const Color(0xFFCCCCCC);
    const double circleSize = 58;
    const double bodyWidth = 66;
    const double bodyHeight = 80;

    Widget body;
    if (gender == 'male') {
      body = CustomPaint(
        painter: TrianglePainter(color: color, pointingDown: true),
        size: const Size(bodyWidth, bodyHeight),
      );
    } else if (gender == 'female') {
      body = CustomPaint(
        painter: TrianglePainter(color: color, pointingDown: false),
        size: const Size(bodyWidth, bodyHeight),
      );
    } else {
      body = CustomPaint(
        painter: DiamondPainter(color: color),
        size: const Size(bodyWidth, bodyHeight),
      );
    }

    final label = gender == 'male'
        ? t('Male', 'ชาย')
        : gender == 'female'
            ? t('Female', 'หญิง')
            : t('Other', 'อื่นๆ');

    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: 10),
          body,
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t('Gender', 'เพศ'),
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 14)),
                  GestureDetector(
                    onTap: () => setState(() => isEnglish = !isEnglish),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A9B6A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(isEnglish ? 'EN' : 'TH',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                t("What's your gender?", 'คุณเป็นเพศอะไร?'),
                style: const TextStyle(
                  color: Color(0xFF1A7A50),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    t('Helps us tune your voice analysis',
                        'ช่วยปรับการวิเคราะห์เสียงของคุณ'),
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Text(' ✨'),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildGenderIcon('male')),
                    Container(
                        width: 1, height: 200, color: Colors.grey[200]),
                    Expanded(child: _buildGenderIcon('female')),
                    Container(
                        width: 1, height: 200, color: Colors.grey[200]),
                    Expanded(child: _buildGenderIcon('other')),
                  ],
                ),
              ),
              if (selectedGender != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _proceed(selectedGender),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      t('Continue', 'ดำเนินการต่อ'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Center(
                child: GestureDetector(
                  onTap: () => _proceed(null),
                  child: Text(
                    t('Skip', 'ข้าม'),
                    style: const TextStyle(
                      color: Color(0xFF1A6B45),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final bool pointingDown;

  const TrianglePainter({required this.color, required this.pointingDown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter old) =>
      old.color != color || old.pointingDown != pointingDown;
}

class DiamondPainter extends CustomPainter {
  final Color color;

  const DiamondPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DiamondPainter old) => old.color != color;
}
