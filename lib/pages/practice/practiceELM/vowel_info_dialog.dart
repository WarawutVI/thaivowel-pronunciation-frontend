import 'package:flutter/material.dart';
import 'package:frontend/services/practice_api.dart';

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

  String t(String en, String th) => widget.isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await PracticeApi.fetchVowelDetails();
      final match = all.where((v) => v.id == widget.vowelId).firstOrNull;
      if (mounted) setState(() { _detail = match; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((widget.isEnglish
                                ? _detail!.lipsEn
                                : _detail!.lipsTh) !=
                            null)
                          _Chip(
                            label: t('Lips', 'ริมฝีปาก'),
                            value: (widget.isEnglish
                                ? _detail!.lipsEn
                                : _detail!.lipsTh)!,
                          ),
                        if ((widget.isEnglish
                                ? _detail!.tongueEn
                                : _detail!.tongueTh) !=
                            null)
                          _Chip(
                            label: t('Tongue', 'ลิ้น'),
                            value: (widget.isEnglish
                                ? _detail!.tongueEn
                                : _detail!.tongueTh)!,
                          ),
                        if ((widget.isEnglish
                                ? _detail!.jawEn
                                : _detail!.jawTh) !=
                            null)
                          _Chip(
                            label: t('Jaw', 'ขากรรไกร'),
                            value: (widget.isEnglish
                                ? _detail!.jawEn
                                : _detail!.jawTh)!,
                          ),
                      ],
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
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF8F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
