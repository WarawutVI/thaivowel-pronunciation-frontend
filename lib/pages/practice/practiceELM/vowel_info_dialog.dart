import 'package:flutter/material.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:frontend/widgets/pronunciation_info_card.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void showVowelInfoDialog(
    BuildContext context, int vowelId, String vowelSymbol, bool isEnglish) {
  showDialog(
    context: context,
    builder: (_) => _VowelInfoDialog(
      vowelId: vowelId,
      vowelSymbol: vowelSymbol,
      isEnglish: isEnglish,
    ),
  );
}

class _VowelInfoDialog extends StatefulWidget {
  final int vowelId;
  final String vowelSymbol;
  final bool isEnglish;

  const _VowelInfoDialog({
    required this.vowelId,
    required this.vowelSymbol,
    required this.isEnglish,
  });

  @override
  State<_VowelInfoDialog> createState() => _VowelInfoDialogState();
}

class _VowelInfoDialogState extends State<_VowelInfoDialog> {
  VowelDetail? _detail;
  bool _loading = true;
  YoutubePlayerController? _ytController;

  String t(String en, String th) => widget.isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await PracticeApi.fetchVowelDetails();
      final match = all.where((v) => v.id == widget.vowelId).firstOrNull;
      _initVideo(match?.linkVideo);
      if (mounted) setState(() { _detail = match; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initVideo(String? url) {
    if (url == null || url.isEmpty) return;
    final videoId = YoutubePlayer.convertUrlToId(url) ?? url;
    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget buildDialog(Widget? player) => AlertDialog(
      title: Text(
        t('How to pronounce ${widget.vowelSymbol}',
            'วิธีออกเสียง ${widget.vowelSymbol}'),
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF1A7A50)),
      ),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF1A7A50)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t('Articulation Guide', 'คำแนะนำการออกเสียง'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _detail != null
                        ? (widget.isEnglish
                                ? _detail!.descriptionEn
                                : _detail!.descriptionTh) ??
                            ''
                        : t('No description available.',
                            'ไม่มีคำอธิบาย'),
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.5),
                  ),
                  if (_detail != null) ...[
                    const SizedBox(height: 14),
                    PronunciationInfoGrid(
                      items: [
                        if ((widget.isEnglish
                                ? _detail!.lipsEn
                                : _detail!.lipsTh) !=
                            null)
                          MapEntry(
                            t('Lip Shape', 'รูปปาก'),
                            (widget.isEnglish
                                ? _detail!.lipsEn
                                : _detail!.lipsTh)!,
                          ),
                        if ((widget.isEnglish
                                ? _detail!.tongueLevelEn
                                : _detail!.tongueLevelTh) !=
                            null)
                          MapEntry(
                            t('Tongue Height', 'ระดับลิ้น'),
                            (widget.isEnglish
                                ? _detail!.tongueLevelEn
                                : _detail!.tongueLevelTh)!,
                          ),
                        if ((widget.isEnglish
                                ? _detail!.tongueEn
                                : _detail!.tongueTh) !=
                            null)
                          MapEntry(
                            t('Tongue Part Used', 'ส่วนของลิ้นที่ใช้'),
                            (widget.isEnglish
                                ? _detail!.tongueEn
                                : _detail!.tongueTh)!,
                          ),
                        MapEntry(
                          t('Duration', 'ระยะเวลา'),
                          _detail!.vowelType == 'long'
                              ? t('Long', 'ยาว')
                              : t('Short', 'สั้น'),
                        ),
                      ],
                    ),
                  ],
                  if (player != null) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: player,
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('Close', 'ปิด'),
              style: const TextStyle(color: Color(0xFF1A7A50))),
        ),
      ],
    );

    if (_ytController == null) return buildDialog(null);
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
      builder: (_, player) => buildDialog(player),
    );
  }
}
