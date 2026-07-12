import 'package:flutter/material.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/auth/age.dart';
import 'package:get/get.dart';

class GenderPage extends StatefulWidget {
  final String uid;
  final String username;
  final String email;
  final String loginProvider;
  final bool isEnglish;

  const GenderPage({
    super.key,
    required this.uid,
    required this.username,
    required this.email,
    required this.loginProvider,
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
    isEnglish = Get.find<LanguageController>().isEnglish;
  }

  String t(String en, String th) => isEnglish ? en : th;

  void _proceed(String? gender) {
    Get.to(() => Agepage(
          uid: widget.uid,
          username: widget.username,
          email: widget.email,
          gender: gender,
          loginProvider: widget.loginProvider,
          isEnglish: isEnglish,
        ));
  }

  Widget _buildGenderCard(String gender) {
    final isSelected = selectedGender == gender;
    final isFemale = gender == 'female';
    final cardColor = isFemale ? const Color(0xFFFCE4EC) : const Color(0xFFDCEEFF);
    final label = isFemale ? t('Female', 'หญิง') : t('Male', 'ชาย');

    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A7A50) : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A7A50).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              isFemale ? 'assets/picture/female.png' : 'assets/picture/male.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1A7A50) : Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
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
                  LanguageToggleButton(
                    isEnglish: isEnglish,
                    onChanged: (v) => setState(() => isEnglish = v),
                    pillStyle: true,
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
                    Expanded(child: _buildGenderCard('female')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildGenderCard('male')),
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
