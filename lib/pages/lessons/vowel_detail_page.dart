import 'package:flutter/material.dart';
import 'package:frontend/pages/lessons/lessonELM/info_chip.dart';
import 'package:frontend/pages/practice/word_grid_page.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; 
class VowelDetailPage extends StatefulWidget {
  final VowelDetail vowel;
  final bool isEnglish;

  const VowelDetailPage({
    super.key,
    required this.vowel,
    required this.isEnglish,
  });

  @override
  State<VowelDetailPage> createState() => _VowelDetailPageState();
}

class _VowelDetailPageState extends State<VowelDetailPage> {
  late bool isEnglish;
  YoutubePlayerController? _ytController;

  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
    _initVideo();
  }

  void _initVideo() {
    final url = widget.vowel.linkVideo;
    if (url == null || url.isEmpty) return;

    // ✨ ใช้ความสามารถในการสกัดแยกไอดีของแพ็คเกจใหม่ที่คุณเลือกมา
    final videoId = YoutubePlayer.convertUrlToId(url) ?? url;

    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void deactivate() {
    // พักการเล่นวิดีโอไว้ชั่วคราวหากผู้ใช้กดสลับหน้าจอ (ทำงานได้ดีในระบบของแพ็คเกจนี้)
    _ytController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _ytController?.dispose(); // ✨ ล้างหน่วยความจำให้ถูกต้อง
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vowel = widget.vowel;
    final isLong = vowel.vowelType == 'long';

    Scaffold buildScaffold(Widget? player) => Scaffold(
          backgroundColor: const Color(0xFFF4FAF7),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Get.back(),
            ),
            title: Text(
              t('Lessons', 'บทเรียน'),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              // ── Symbol + type badge + phonetic ──────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vowel.symbol,
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isLong
                                ? t('LONG VOWEL', 'สระเสียงยาว')
                                : t('SHORT VOWEL', 'สระเสียงสั้น'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A7A50),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vowel.unicodePhonetic ?? '',
                          style: const TextStyle(
                              fontSize: 22, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── How to pronounce card ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('HOW TO PRONOUNCE', 'วิธีออกเสียง'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A7A50),
                        letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  (isEnglish ? vowel.descriptionEn : vowel.descriptionTh) ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((isEnglish ? vowel.lipsEn : vowel.lipsTh) != null)
                      InfoChip(
                        label: t('Lips', 'ริมฝีปาก'),
                        value: (isEnglish ? vowel.lipsEn : vowel.lipsTh)!,
                      ),
                    if ((isEnglish ? vowel.tongueEn : vowel.tongueTh) != null)
                      InfoChip(
                        label: t('Tongue', 'ลิ้น'),
                        value: (isEnglish ? vowel.tongueEn : vowel.tongueTh)!,
                      ),
                    // if ((isEnglish ? vowel.jawEn : vowel.jawTh) != null)
                    //   _InfoChip(
                    //     label: t('Jaw', 'ขากรรไกร'),
                    //     value: (isEnglish ? vowel.jawEn : vowel.jawTh)!,
                    //   ),
                    // _InfoChip(
                    //   label: t('Duration', 'ระยะเวลา'),
                    //   value: isLong ? t('Long', 'ยาว') : t('Short', 'สั้น'),
                    // ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── YouTube player component ─────────────────────────────────────
          if (_ytController != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: player, // ✨ สั่ง Render ตัวแปร player ที่แกะมาจากโครงสร้างด้านบนโดยตรง
            ),
            const SizedBox(height: 6),
            
            const SizedBox(height: 20),
          ],

          // ── Go to practice button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(
                () => WordGridPage(
                  vowelId: vowel.id,
                  vowelSymbol: vowel.symbol,
                  vowelType: vowel.vowelType,
                  isEnglish: isEnglish,
                ),
                transition: Transition.rightToLeft,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A7A50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t('Go to practice', 'ไปฝึกออกเสียง'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (_ytController == null) return buildScaffold(null);
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF1A7A50),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF1A7A50),
          handleColor: Color(0xFF1A7A50),
        ),
      ),
      builder: (_, player) => buildScaffold(player),
    );
  }
}
