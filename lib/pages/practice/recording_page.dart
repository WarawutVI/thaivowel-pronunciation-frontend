import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/practiceELM/phase_views.dart';
import 'package:frontend/pages/practice/practiceELM/result_modal.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum _Phase { idle, getReady, recording, analyzing }

class RecordingPage extends StatefulWidget {
  final int lessonId;
  final int lessonOrder;
  final int vowelId;
  final String word;
  final String? wordIpa;
  final String vowelSymbol;
  final bool isEnglish;

  const RecordingPage({
    super.key,
    required this.lessonId,
    required this.lessonOrder,
    required this.vowelId,
    required this.word,
    this.wordIpa,
    required this.vowelSymbol,
    this.isEnglish = true,
  });

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  static const int _recordSeconds = 3;
  static const int _getReadySeconds = 3;

  late bool isEnglish;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _samplePlayer = AudioPlayer();

  _Phase _phase = _Phase.idle;
  int _readyCountdown = _getReadySeconds;
  int _remainingSeconds = _recordSeconds;
  Timer? _countdownTimer;
  bool _isPlayingSample = false;

  List<double> _refSamples = [];
  List<double> _userSamples = [];
  double _confidence = 0;
  double _userF1 = 0;
  double _userF2 = 0;
  VowelFormant? _refFormant;

  String get firebaseUid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  int get _vowelIndex => widget.vowelId - 1;

  @override
  void initState() {
    super.initState();
    isEnglish = Get.find<LanguageController>().isEnglish;
    _samplePlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingSample = false);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recorder.dispose();
    _samplePlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleSample() async {
    if (_isPlayingSample) {
      await _samplePlayer.stop();
      setState(() => _isPlayingSample = false);
      return;
    }
    try {
      setState(() => _isPlayingSample = true);
      await _samplePlayer.play(
        AssetSource('samples/${widget.vowelId}/${widget.lessonOrder}.wav'),
      );
    } catch (_) {
      setState(() => _isPlayingSample = false);
      Get.snackbar(
        t('Error', 'เกิดข้อผิดพลาด'),
        t('Sample audio not available', 'ไม่มีเสียงตัวอย่าง'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
      _phase = _Phase.getReady;
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
      path = 'vowel_recording.wav';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/vowel_${widget.vowelId}.wav';
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
      _phase = _Phase.recording;
      _remainingSeconds = _recordSeconds;
      _refSamples = [];
      _userSamples = [];
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        final finalPath = await _recorder.stop();
        setState(() => _phase = _Phase.analyzing);
        if (finalPath != null) await _submitToApi(finalPath);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _submitToApi(String filePath) async {
    final recordStart = DateTime.now().subtract(Duration(seconds: _recordSeconds));
    try {
      final audioBytes = await _getAudioBytes(filePath);

      final result = await PracticeApi.predict(audioBytes, _vowelIndex);
      final duration = DateTime.now().difference(recordStart).inSeconds;

      VowelFormant? refFormant;
      try {
        refFormant = await PracticeApi.fetchVowelFormant(widget.vowelId);
      } catch (_) {}

      PracticeApi.saveSession(
        firebaseUid: firebaseUid,
        lessonId: widget.lessonId,
        confidence: result.confidence,
        assessmentLevel: result.assessmentLevel,
        isPassed: result.isPassed,
        durationSeconds: duration,
      );
      PracticeApi.saveProgress(
        firebaseUid: firebaseUid,
        lessonId: widget.lessonId,
        isCompleted: result.isPassed,
        bestAccuracy: result.confidence,
        assessmentLevel: result.assessmentLevel,
      );
      PracticeApi.updateStreak(firebaseUid);

      setState(() {
        _confidence  = result.confidence;
        _userF1      = result.userF1;
        _userF2      = result.userF2;
        _refFormant  = refFormant;
        _refSamples  = result.refWave;
        _userSamples = result.userWave;
        _phase       = _Phase.idle;
      });

      if (!mounted) return;
      showResultModal(
        context,
        isEnglish: isEnglish,
        confidence: _confidence,
        refSamples: _refSamples,
        userSamples: _userSamples,
        suggestion: _buildSuggestion(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.idle);
      Get.snackbar(
        t('Error', 'เกิดข้อผิดพลาด'),
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _buildSuggestion() {
    final ref = _refFormant;
    if (ref == null || (_userF1 == 0 && _userF2 == 0)) return '';

    final f1Diff = _userF1 - ref.f1;
    final f2Diff = _userF2 - ref.f2;
    const f1Threshold = 200.0;
    const f2Threshold = 200.0;

    final List<String> partsEn = [];
    final List<String> partsTh = [];

    if (f1Diff > f1Threshold) {
      partsEn.addAll(['closing your mouth slightly', 'raising your tongue']);
      partsTh.addAll(['ปิดปากลงเล็กน้อย', 'ยกลิ้นขึ้น']);
    } else if (f1Diff <  f1Threshold) {
      partsEn.addAll(['opening your mouth wider', 'lowering your tongue']);
      partsTh.addAll(['อ้าปากให้กว้างขึ้น', 'วางลิ้นให้ต่ำลง']);
    }

    if (f2Diff > f2Threshold) {
      partsEn.add('moving your tongue slightly back');
      partsTh.add('เลื่อนลิ้นไปด้านหลังเล็กน้อย');
    } else if (f2Diff < f2Threshold) {
      partsEn.addAll(['moving your tongue slightly forward', 'relaxing your lips']);
      partsTh.addAll(['เลื่อนลิ้นไปด้านหน้าเล็กน้อย', 'ผ่อนคลายริมฝีปาก']);
    }

    if (partsEn.isEmpty) return '';
    return isEnglish
        ? 'Try ${partsEn.join(', ')}.'
        : 'ลอง${partsTh.join(' ')}';
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
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: switch (_phase) {
                  _Phase.idle => IdleView(
                      word: widget.word,
                      wordIpa: widget.wordIpa,
                      isEnglish: isEnglish,
                      recordSeconds: _recordSeconds,
                      onBeginFlow: _beginFlow,
                    ),
                  _Phase.getReady => GetReadyView(
                      word: widget.word,
                      wordIpa: widget.wordIpa,
                      isEnglish: isEnglish,
                      readyCountdown: _readyCountdown,
                      getReadySeconds: _getReadySeconds,
                    ),
                  _Phase.recording => RecordingView(
                      word: widget.word,
                      wordIpa: widget.wordIpa,
                      isEnglish: isEnglish,
                      remainingSeconds: _remainingSeconds,
                      recordSeconds: _recordSeconds,
                    ),
                  _Phase.analyzing => AnalyzingView(isEnglish: isEnglish),
                },
              ),
            ),
          ),
          if (_phase == _Phase.idle)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleSample,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A7A50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isPlayingSample ? Icons.stop : Icons.volume_up,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
