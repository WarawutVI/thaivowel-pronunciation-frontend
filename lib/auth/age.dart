import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/wrapper.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Agepage extends StatefulWidget {
  final String username;
  final String email;
  final String password;
  final String? gender;
  final bool isEnglish;

  const Agepage({
    super.key,
    required this.username,
    required this.email,
    required this.password,
    this.gender,
    this.isEnglish = true,
  });

  @override
  State<Agepage> createState() => _AgepageState();
}

class _AgepageState extends State<Agepage> {
  late FixedExtentScrollController _scrollController;
  late bool isEnglish;
  int selectedAge = 17;
  final List<int> ages = List.generate(86, (i) => i + 5); // 5–90
  final List<int> quickAges = [14, 17, 21, 30, 45];

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
    _scrollController =
        FixedExtentScrollController(initialItem: ages.indexOf(selectedAge));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String t(String en, String th) => isEnglish ? en : th;

  void _selectQuickAge(int age) {
    setState(() => selectedAge = age);
    _scrollController.animateToItem(
      ages.indexOf(age),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createAccount() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      final uid = userCredential.user?.uid;
      if (uid != null) {
        await postdata(uid, widget.username, widget.email, widget.gender, selectedAge);
      }

      Get.back();
      Get.offAll(() => const Wrapper());
    } on FirebaseAuthException catch (e) {
      Get.back();
      String message = t("Sign up failed", "สมัครสมาชิกไม่สำเร็จ");
      if (e.code == 'email-already-in-use') {
        message = t("This email is already in use", "อีเมลนี้ถูกใช้งานไปแล้ว");
      } else if (e.code == 'weak-password') {
        message = t("Password must be at least 6 characters",
            "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร");
      } else if (e.code == 'invalid-email') {
        message = t("Invalid email format", "รูปแบบอีเมลไม่ถูกต้อง");
      }
      Get.snackbar(
        t("Error", "เกิดข้อผิดพลาด"),
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> postdata(String uid, String name, String email, String? gender, int? age) async {
    try {
      var response = await http.post(
        Uri.parse('http://10.0.2.2:3000/users'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'uid': uid,
          'name': name,
          'surname': '',
          'email': email,
          'gender': gender,
          'age': age,
        }),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        print("complete sign up");
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF8F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => isEnglish = !isEnglish),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A9B6A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          isEnglish ? 'EN' : 'TH',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t('How old are you?', 'คุณอายุเท่าไหร่?'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t("We'll calibrate the model to your age range.",
                    "เราจะปรับโมเดลให้เหมาะกับช่วงอายุของคุณ"),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: CupertinoPicker(
                  scrollController: _scrollController,
                  itemExtent: 54,
                  onSelectedItemChanged: (index) =>
                      setState(() => selectedAge = ages[index]),
                  selectionOverlay: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0F0E4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  children: ages
                      .map((age) => Center(
                            child: Text(
                              '$age',
                              style: TextStyle(
                                fontSize: selectedAge == age ? 30 : 22,
                                fontWeight: selectedAge == age
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selectedAge == age
                                    ? const Color(0xFF1A7A50)
                                    : Colors.grey[400],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: quickAges.map((age) {
                  final isSelected = selectedAge == age;
                  return GestureDetector(
                    onTap: () => _selectQuickAge(age),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF1A7A50)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A7A50)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$age',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7A50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    t("Let's go!", "ไปเลย!"),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
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
