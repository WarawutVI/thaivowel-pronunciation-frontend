import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/practiceELM/pair_result_modal.dart';
import 'package:frontend/pages/practice/practiceELM/phase_views.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum _PairPhase { idle, getReady, recording, analyzing }

/// Records a single take of two vowels spoken back-to-back (e.g. อะ → อา)
/// and sends it to the backend's /predict_pair endpoint for a combined
/// per-segment result, then saves it via POST /practice_pair_sessions.
class PairRecordingPage extends StatefulWidget {
  final int shortVowelId;
  final String shortSymbol;
  final int longVowelId;
  final String longSymbol;
  final bool isEnglish;

  const PairRecordingPage({
    super.key,
    required this.shortVowelId,
    required this.shortSymbol,
    required this.longVowelId,
    required this.longSymbol,
    this.isEnglish = true,
  });

  @override
  State<PairRecordingPage> createState() => _PairRecordingPageState();
}

class _PairRecordingPageState extends State<PairRecordingPage> {
  static const int _recordSeconds = 4;
  static const int _getReadySeconds = 3;

  late bool isEnglish;
  final AudioRecorder _recorder = AudioRecorder();

  _PairPhase _phase = _PairPhase.idle;
  int _readyCountdown = _getReadySeconds;
  int _remainingSeconds = _recordSeconds;
  Timer? _countdownTimer;

  String get _word => '${widget.shortSymbol} → ${widget.longSymbol}';
  String get firebaseUid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<Uint8List> _getAudioBytes(String path) async {
    if (kIsWeb) {
      final res = await http.get(Uri.parse(path));
      return res.bodyBytes;
    }
    return File(path).readAsBytes();
  }

  Future<void> _beginFlow() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      Get.snackbar(
        t('Permission Denied', 'ไม่ได้รับอนุญาต'),
        t('Microphone access is required', 'ต้องการสิทธิ์เข้าถึงไมโครโฟน'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _phase = _PairPhase.getReady;
      _readyCountdown = _getReadySeconds;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_readyCountdown <= 1) {
        timer.cancel();
        await _startRecording();
      } else {
        setState(() => _readyCountdown--);
      }
    });
  }

  Future<void> _startRecording() async {
    final String path;
    if (kIsWeb) {
      path = 'vowel_pair_recording.wav';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path =
          '${dir.path}/vowel_pair_${widget.shortVowelId}_${widget.longVowelId}.wav';
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    setState(() {
      _phase = _PairPhase.recording;
      _remainingSeconds = _recordSeconds;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        final finalPath = await _recorder.stop();
        setState(() => _phase = _PairPhase.analyzing);
        if (finalPath != null) await _submitToApi(finalPath);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _submitToApi(String filePath) async {
    final recordStart =
        DateTime.now().subtract(Duration(seconds: _recordSeconds));
    try {
      final audioBytes = await _getAudioBytes(filePath);
      final result = await PracticeApi.predictPair(
        audioBytes,
        widget.shortVowelId - 1,
        widget.longVowelId - 1,
      );
      final duration = DateTime.now().difference(recordStart).inSeconds;

      PracticeApi.savePairSession(
        firebaseUid: firebaseUid,
        shortVowelId: widget.shortVowelId,
        longVowelId: widget.longVowelId,
        confidenceShort: result.segment1.confidence,
        confidenceLong: result.segment2.confidence,
        assessmentLevelShort: result.segment1.assessmentLevel,
        assessmentLevelLong: result.segment2.assessmentLevel,
        userF1Short: result.segment1.userF1,
        userF2Short: result.segment1.userF2,
        userF1Long: result.segment2.userF1,
        userF2Long: result.segment2.userF2,
        durationSeconds: duration,
      );

      setState(() => _phase = _PairPhase.idle);

      if (!mounted) return;
      showPairResultModal(
        context,
        isEnglish: isEnglish,
        shortSymbol: widget.shortSymbol,
        longSymbol: widget.longSymbol,
        segment1: result.segment1,
        segment2: result.segment2,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _PairPhase.idle);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          t('Practice', 'ฝึกพูด'),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (_phase) {
              _PairPhase.idle => IdleView(
                  word: _word,
                  isEnglish: isEnglish,
                  recordSeconds: _recordSeconds,
                  onBeginFlow: _beginFlow,
                  isPlayingSample: false,
                  wordFontSize: 72,
                  onToggleSample: () => Get.snackbar(
                    t('No sample', 'ไม่มีเสียงตัวอย่าง'),
                    t(
                      'Sample audio for vowel pairs is not available yet',
                      'ยังไม่มีเสียงตัวอย่างสำหรับคู่สระนี้',
                    ),
                    backgroundColor: const Color(0xFF1A7A50),
                    colorText: Colors.white,
                  ),
                ),
              _PairPhase.getReady => GetReadyView(
                  word: _word,
                  isEnglish: isEnglish,
                  readyCountdown: _readyCountdown,
                  getReadySeconds: _getReadySeconds,
                ),
              _PairPhase.recording => RecordingView(
                  word: _word,
                  isEnglish: isEnglish,
                  remainingSeconds: _remainingSeconds,
                  recordSeconds: _recordSeconds,
                  wordFontSize: 48,
                ),
              _PairPhase.analyzing => AnalyzingView(isEnglish: isEnglish),
            },
          ),
        ),
      ),
    );
  }
}
