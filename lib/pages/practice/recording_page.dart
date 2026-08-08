import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:frontend/pages/practice/practiceELM/phase_views.dart';
import 'package:frontend/pages/practice/practiceELM/pronunciation_suggestion.dart';
import 'package:frontend/pages/practice/practiceELM/result_modal.dart';
import 'package:frontend/pages/practice/practiceELM/sample_player.dart';
import 'package:frontend/pages/practice/practiceELM/vowel_info_dialog.dart';
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
  late final SamplePlayer _samplePlayer;

  _Phase _phase = _Phase.idle;
  int _readyCountdown = _getReadySeconds;
  int _remainingSeconds = _recordSeconds;
  Timer? _countdownTimer;

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
    _samplePlayer = SamplePlayer(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recorder.dispose();
    _samplePlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleSample() {
    return _samplePlayer.toggle(
      'samples/${widget.vowelId}/${widget.lessonOrder}',
      onError: () => Get.snackbar(
        t('Error', 'เกิดข้อผิดพลาด'),
        t('Sample audio not available', 'ไม่มีเสียงตัวอย่าง'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      ),
    );
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
      } catch (e) {
        debugPrint('fetchVowelFormant(${widget.vowelId}) failed: $e');
      }

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

      debugPrint('userF1=$_userF1 userF2=$_userF2 '
          'ref=${_refFormant == null ? 'null' : '(f1=${_refFormant!.f1}, f2=${_refFormant!.f2}, '
              'f1Min=${_refFormant!.f1Min}, f1Max=${_refFormant!.f1Max}, '
              'f2Min=${_refFormant!.f2Min}, f2Max=${_refFormant!.f2Max})'}');

      final suggestion = buildPronunciationSuggestion(
        ref: _refFormant,
        userF1: _userF1,
        userF2: _userF2,
        isEnglish: isEnglish,
      );

      if (!mounted) return;
      showResultModal(
        context,
        isEnglish: isEnglish,
        confidence: _confidence,
        refSamples: _refSamples,
        userSamples: _userSamples,
        suggestion: suggestion.suggestion,
        userF1: suggestion.userF1,
        userF2: suggestion.userF2,
        ref: suggestion.ref,
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
                      isPlayingSample: _samplePlayer.isPlaying,
                      onToggleSample: _toggleSample,
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
          Positioned(
            top: 16,
            right: 20,
            child: GestureDetector(
              onTap: () => showVowelInfoDialog(
                  context, widget.vowelId, widget.vowelSymbol, isEnglish),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A7A50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
