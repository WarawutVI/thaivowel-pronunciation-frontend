import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:frontend/pages/progressELM/progress_shared.dart';
import 'package:frontend/services/language_controller.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:frontend/widgets/waveform_display.dart';
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
  final String vowelSymbol;
  final bool isEnglish;

  const RecordingPage({
    super.key,
    required this.lessonId,
    required this.lessonOrder,
    required this.vowelId,
    required this.word,
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

      _showResultModal();
    } catch (e) {
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
    const f1Threshold = 100.0;
    const f2Threshold = 200.0;

    final List<String> partsEn = [];
    final List<String> partsTh = [];

    if (f1Diff > f1Threshold) {
      partsEn.addAll(['closing your mouth slightly', 'raising your tongue']);
      partsTh.addAll(['ปิดปากลงเล็กน้อย', 'ยกลิ้นขึ้น']);
    } else if (f1Diff < -f1Threshold) {
      partsEn.addAll(['opening your mouth wider', 'lowering your tongue']);
      partsTh.addAll(['อ้าปากให้กว้างขึ้น', 'วางลิ้นให้ต่ำลง']);
    }

    if (f2Diff > f2Threshold) {
      partsEn.add('moving your tongue slightly back');
      partsTh.add('เลื่อนลิ้นไปด้านหลังเล็กน้อย');
    } else if (f2Diff < -f2Threshold) {
      partsEn.addAll(['moving your tongue slightly forward', 'relaxing your lips']);
      partsTh.addAll(['เลื่อนลิ้นไปด้านหน้าเล็กน้อย', 'ผ่อนคลายริมฝีปาก']);
    }

    if (partsEn.isEmpty) return '';
    return isEnglish
        ? 'Try ${partsEn.join(', ')}.'
        : 'ลอง${partsTh.join(' ')}';
  }

  void _showResultModal() {
    final passed     = _confidence >= 0.51;
    final level      = assessmentLabel(_confidence, isEnglish);
    final suggestion = _buildSuggestion();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      passed ? '$level 🎉' : level,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: accuracyColor(_confidence),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  WaveformDisplay(
                    refSamples: _refSamples,
                    userSamples: _userSamples,
                    refLabel: t('Sample Audio', 'เสียงตัวอย่าง'),
                    userLabel: t('Your Audio', 'เสียงของคุณ'),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      t(
                        'accuracy ${(_confidence * 100).toStringAsFixed(0)}%',
                        'ความแม่นยำ ${(_confidence * 100).toStringAsFixed(0)}%',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (suggestion.isNotEmpty && !passed) ...[
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${t('suggestion', 'คำแนะนำ')} : ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: suggestion,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1A7A50)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(t('Try Again', 'ลองอีกครั้ง'),
                              style: const TextStyle(color: Color(0xFF1A7A50))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A7A50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(t('Finish', 'เสร็จสิ้น'),
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[200], shape: BoxShape.circle),
                  child: Icon(Icons.close, color: Colors.grey[700], size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Phase-specific views ──────────────────────────────────────────────────────

  Widget _buildIdleView() {
    return Column(
      key: const ValueKey(_Phase.idle),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.word,
          style: const TextStyle(
            fontSize: 170,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t(
            'Press the mic and speak for $_recordSeconds seconds.',
            'กดไมค์แล้วพูด $_recordSeconds วินาที',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: _beginFlow,
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

  Widget _buildGetReadyView() {
    return Column(
      key: const ValueKey(_Phase.getReady),
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
                  value: _readyCountdown / _getReadySeconds,
                  strokeWidth: 8,
                  backgroundColor: Colors.black12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF1A7A50)),
                ),
              ),
              Text(
                '$_readyCountdown',
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
          '${t('Say:', 'พูด:')} ${widget.word}',
          style: const TextStyle(fontSize: 22, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildRecordingView() {
    return Column(
      key: const ValueKey(_Phase.recording),
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
          widget.word,
          style: const TextStyle(
            fontSize: 130,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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
                  value: _remainingSeconds / _recordSeconds,
                  strokeWidth: 8,
                  backgroundColor: Colors.black12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
              Text(
                '$_remainingSeconds',
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

  Widget _buildAnalyzingView() {
    return Column(
      key: const ValueKey(_Phase.analyzing),
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
              _Phase.idle      => _buildIdleView(),
              _Phase.getReady  => _buildGetReadyView(),
              _Phase.recording => _buildRecordingView(),
              _Phase.analyzing => _buildAnalyzingView(),
            },
          ),
        ),
      ),
    );
  }
}
