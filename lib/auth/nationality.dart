import 'package:flutter/material.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/wrapper.dart';
import 'package:get/get.dart';

class NationalityPage extends StatefulWidget {
  final String uid;
  final String username;
  final String email;
  final String? gender;
  final int age;
  final String loginProvider;

  const NationalityPage({
    super.key,
    required this.uid,
    required this.username,
    required this.email,
    this.gender,
    required this.age,
    required this.loginProvider,
  });

  @override
  State<NationalityPage> createState() => _NationalityPageState();
}

class _NationalityPageState extends State<NationalityPage> {
  late bool isEnglish;
  String? _selected;
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _filtered = [];

  static const _nationalities = [
    'Thai',
    'Chinese',
    'Japanese',
     'Korean',
    'Vietnamese',
    'Burmese',
    'Cambodian',
    'Laotian',
    'Malaysian',
    'Indonesian',
    'Filipino',
    'Singaporean',
    'Bruneian',
    'Bangladeshi',
    'American',
    'British',
    'Australian',
    'Canadian',
    'French',
    'German',
    'Spanish',
    'Italian',
    'Portuguese',
    'Russian',
    'Dutch',
    'Swedish',
    'Norwegian',
    'Danish',
    'Finnish',
    'Polish',
    'Turkish',
    'Arabic',
    'Iranian',
    'Brazilian',
    'Argentinian',
    'Colombian',
    'Mexican',
    'Other',
  ];

  static const _flagLinks = {
    'Thai': 'https://flagcdn.com/w320/th.png',
    'Chinese': 'https://flagcdn.com/w320/cn.png',
    'Japanese': 'https://flagcdn.com/w320/jp.png',
    'Korean': 'https://flagcdn.com/w320/kr.png',
    'Vietnamese': 'https://flagcdn.com/w320/vn.png',
    'Burmese': 'https://flagcdn.com/w320/mm.png',
    'Cambodian': 'https://flagcdn.com/w320/kh.png',
    'Laotian': 'https://flagcdn.com/w320/la.png',
    'Malaysian': 'https://flagcdn.com/w320/my.png',
    'Indonesian': 'https://flagcdn.com/w320/id.png',
    'Filipino': 'https://flagcdn.com/w320/ph.png',
    'Singaporean': 'https://flagcdn.com/w320/sg.png',
    'Bruneian': 'https://flagcdn.com/w320/bn.png',
    'Bangladeshi': 'https://flagcdn.com/w320/bd.png',
    'American': 'https://flagcdn.com/w320/us.png',
    'British': 'https://flagcdn.com/w320/gb.png',
    'Australian': 'https://flagcdn.com/w320/au.png',
    'Canadian': 'https://flagcdn.com/w320/ca.png',
    'French': 'https://flagcdn.com/w320/fr.png',
    'German': 'https://flagcdn.com/w320/de.png',
    'Spanish': 'https://flagcdn.com/w320/es.png',
    'Italian': 'https://flagcdn.com/w320/it.png',
    'Portuguese': 'https://flagcdn.com/w320/pt.png',
    'Russian': 'https://flagcdn.com/w320/ru.png',
    'Dutch': 'https://flagcdn.com/w320/nl.png',
    'Swedish': 'https://flagcdn.com/w320/se.png',
    'Norwegian': 'https://flagcdn.com/w320/no.png',
    'Danish': 'https://flagcdn.com/w320/dk.png',
    'Finnish': 'https://flagcdn.com/w320/fi.png',
    'Polish': 'https://flagcdn.com/w320/pl.png',
    'Turkish': 'https://flagcdn.com/w320/tr.png',
    'Arabic': 'https://flagcdn.com/w320/sa.png', // Uses Saudi Arabia as the standard representative
    'Iranian': 'https://flagcdn.com/w320/ir.png',
    'Brazilian': 'https://flagcdn.com/w320/br.png',
    'Argentinian': 'https://flagcdn.com/w320/ar.png',
    'Colombian': 'https://flagcdn.com/w320/co.png',
    'Mexican': 'https://flagcdn.com/w320/mx.png',
  };

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
    _filtered = List.from(_nationalities);
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _nationalities
          .where((n) => n.toLowerCase().contains(q))
          .toList();
    });
  }

  String t(String en, String th) => isEnglish ? en : th;

  Widget _buildFlag(String nationality, bool isSelected) {
    final url = _flagLinks[nationality];
    if (url == null) {
      return Icon(
        Icons.flag,
        size: 20,
        color: isSelected ? Colors.white : Colors.grey,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.network(
        url,
        width: 28,
        height: 20,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.flag,
          size: 20,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Future<void> _createAccount(String nationality) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await PracticeApi.createUser(
        firebaseUid: widget.uid,
        username: widget.username,
        email: widget.email,
        gender: widget.gender ?? 'other',
        age: widget.age,
        nationality: nationality,
        loginProvider: widget.loginProvider,
      );
      Get.back();
      Get.offAll(() => const Wrapper());
    } catch (e) {
      Get.back();
      Get.snackbar(
        t('Error', 'เกิดข้อผิดพลาด'),
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
                child: LanguageToggleButton(
                  isEnglish: isEnglish,
                  onChanged: (v) => setState(() => isEnglish = v),
                  pillStyle: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t('Where are you from?', 'คุณมาจากไหน?'),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'Helps us compare pronunciation across nationalities.',
                  'ช่วยเปรียบเทียบการออกเสียงระหว่างสัญชาติ',
                ),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: t('Search…', 'ค้นหา…'),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final n = _filtered[i];
                    final isSelected = _selected == n;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = n),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A7A50)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1A7A50)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _buildFlag(n, isSelected),
                                const SizedBox(width: 12),
                                Text(
                                  n,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              const Icon(Icons.check,
                                  color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selected != null
                      ? () => _createAccount(_selected!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7A50),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    t("Let's go!", 'ไปเลย!'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => _createAccount('Other'),
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
