import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/auth/gender.dart';
import 'package:frontend/auth/login.dart';
import 'package:frontend/wrapper.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  bool isEnglish = true;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  String t(String en, String th) => isEnglish ? en : th;

  signup_google() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        Get.back();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        String displayName = user.displayName?.trim() ?? "Unknown User";
        print(displayName);
        List<String> nameParts = displayName.split(' ');
        String fname = nameParts[0];
        String sname =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";
        // await postdata(user.uid, fname, sname, user.email ?? "");
      }

      await FirebaseAuth.instance.signInWithCredential(credential);

      Get.back();
      Get.offAll(() => Wrapper());
    } catch (e) {
      Get.back();
      print("Error: $e");
      Get.snackbar(
        t("Login Failed", "เข้าสู่ระบบไม่สำเร็จ"),
        t("An error occurred: $e", "เกิดข้อผิดพลาด: $e"),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  sigup_email() async {
    if (username.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty) {
      Get.snackbar(
        t("Notice", "แจ้งเตือน"),
        t("Please fill in all fields", "กรุณากรอกข้อมูลให้ครบถ้วน"),
        backgroundColor: Colors.amber,
      );
      return;
    }

    if (password.text != confirmPassword.text) {
      Get.snackbar(
        t("Notice", "แจ้งเตือน"),
        t("Passwords do not match", "รหัสผ่านไม่ตรงกัน"),
        backgroundColor: Colors.amber,
      );
      return;
    }

    Get.to(() => GenderPage(
          username: username.text.trim(),
          email: email.text.trim(),
          password: password.text,
          isEnglish: isEnglish,
        ));
  }

  // postdata(String uid, String name, String surname, String email) async {
  //   try {
  //     var response = await http.post(
  //       Uri.parse('http://10.0.2.2:3000/users'),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json; charset=UTF-8',
  //       },
  //       body: jsonEncode({
  //         'uid': uid,
  //         'name': name,
  //         'surname': surname,
  //         'email': email,
  //       }),
  //     );
  //     print(response.statusCode);
  //     if (response.statusCode == 200) {
  //       print("complete sign up");
  //     }
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFEBF5EF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _googleLogo() {
    return SizedBox(
      width: 22,
      height: 22,
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
                text: 'G',
                style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A7A50),
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                     
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
                              Text(
                                isEnglish ? 'EN' : 'TH',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('Create\naccount ⭐', 'สร้าง\nบัญชี ⭐'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('Start your vowel journey today',
                        'เริ่มต้นการเดินทางของคุณวันนี้'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('YOUR DETAILS', 'รายละเอียดของคุณ'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: username,
                      hint: t('Username', 'ชื่อผู้ใช้'),
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: email,
                      hint: t('Email address', 'อีเมล'),
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: password,
                      hint: t('Password', 'รหัสผ่าน'),
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isVisible: _passwordVisible,
                      onToggleVisibility: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: confirmPassword,
                      hint: t('Confirm Password', 'ยืนยันรหัสผ่าน'),
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isVisible: _confirmPasswordVisible,
                      onToggleVisibility: () => setState(
                          () => _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: sigup_email,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6B45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          t('Create account', 'สร้างบัญชี'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(t('or', 'หรือ'),
                              style: const TextStyle(color: Colors.grey)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: signup_google,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _googleLogo(),
                            const SizedBox(width: 10),
                            Text(
                              t('continue with Google', 'ดำเนินการต่อด้วย Google'),
                              style: const TextStyle(
                                  color: Color(0xFF1A6B45),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => Get.to(() => const Login()),
                        child: RichText(
                          text: TextSpan(
                            text: t('Already have an account? ',
                                'มีบัญชีอยู่แล้ว? '),
                            style: const TextStyle(color: Colors.black54),
                            children: [
                              TextSpan(
                                text: t('Log in', 'เข้าสู่ระบบ'),
                                style: const TextStyle(
                                  color: Color(0xFF1A6B45),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
