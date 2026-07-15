import 'package:flutter/material.dart';

class IdleView extends StatelessWidget {
  final String word;
  final String? wordIpa;
  final bool isEnglish;
  final int recordSeconds;
  final VoidCallback onBeginFlow;
  final bool isPlayingSample;
  final VoidCallback onToggleSample;

  const IdleView({
    super.key,
    required this.word,
    this.wordIpa,
    required this.isEnglish,
    required this.recordSeconds,
    required this.onBeginFlow,
    required this.isPlayingSample,
    required this.onToggleSample,
  });

  String t(String en, String th) => isEnglish ? en : th;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('idle'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          word,
          style: const TextStyle(
            fontSize: 150,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (wordIpa != null)
          Text(
            wordIpa!,
            style: const TextStyle(fontSize: 30, color: Colors.black45),
          ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onToggleSample,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t('Tap to hear sample audio', 'กดเพื่อฟังเสียงตัวอย่าง'),
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A7A50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPlayingSample ? Icons.stop : Icons.volume_up,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t(
            'Tap the microphone and speak once within $recordSeconds seconds.',
            'กดไมค์แล้วพูด 1 ครั้งภายใน $recordSeconds วินาที',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: onBeginFlow,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1A7A50),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A7A50).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.mic, size: 50, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class GetReadyView extends StatelessWidget {
  final String word;
  final String? wordIpa;
  final bool isEnglish;
  final int readyCountdown;
  final int getReadySeconds;

  const GetReadyView({
    super.key,
    required this.word,
    this.wordIpa,
    required this.isEnglish,
    required this.readyCountdown,
    required this.getReadySeconds,
  });

  String t(String en, String th) => isEnglish ? en : th;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('getReady'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t('Get Ready!', 'เตรียมตัว!'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: readyCountdown / getReadySeconds,
                  strokeWidth: 8,
                  backgroundColor: Colors.black12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF1A7A50)),
                ),
              ),
              Text(
                '$readyCountdown',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          '${t('Say:', 'พูด:')} $word',
          style: const TextStyle(fontSize: 22, color: Colors.black54),
        ),
        if (wordIpa != null)
          Text(
            wordIpa!,
            style: const TextStyle(fontSize: 16, color: Colors.black45),
          ),
      ],
    );
  }
}

class RecordingView extends StatelessWidget {
  final String word;
  final String? wordIpa;
  final bool isEnglish;
  final int remainingSeconds;
  final int recordSeconds;

  const RecordingView({
    super.key,
    required this.word,
    this.wordIpa,
    required this.isEnglish,
    required this.remainingSeconds,
    required this.recordSeconds,
  });

  String t(String en, String th) => isEnglish ? en : th;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('recording'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t('SPEAK', 'พูดได้เลย'),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          word,
          style: const TextStyle(
            fontSize: 130,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (wordIpa != null)
          Text(
            wordIpa!,
            style: const TextStyle(fontSize: 18, color: Colors.black45),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: remainingSeconds / recordSeconds,
                  strokeWidth: 8,
                  backgroundColor: Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
              Text(
                '$remainingSeconds',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnalyzingView extends StatelessWidget {
  final bool isEnglish;
  const AnalyzingView({super.key, required this.isEnglish});

  String t(String en, String th) => isEnglish ? en : th;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('analyzing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Color(0xFF1A7A50)),
        const SizedBox(height: 24),
        Text(
          t('Analysing...', 'กำลังวิเคราะห์...'),
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ],
    );
  }
}
