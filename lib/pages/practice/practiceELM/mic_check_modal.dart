import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum MicCheckStatus { idle, recording, tooQuiet, good }

/// Call this before entering practice mode:
///
/// ```dart
/// await showMicCheckModal(context, isEnglish: isEnglish);
/// ```
Future<void> showMicCheckModal(BuildContext context, {required bool isEnglish}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _MicCheckDialog(isEnglish: isEnglish),
  );
}

class _MicCheckDialog extends StatefulWidget {
  final bool isEnglish;
  const _MicCheckDialog({required this.isEnglish});

  @override
  State<_MicCheckDialog> createState() => _MicCheckDialogState();
}

class _MicCheckDialogState extends State<_MicCheckDialog> {
  
  static const double _quietThresholdDb = -30.0; // below this: too quiet

  static const int _checkDurationSeconds = 3;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _countdownTimer;

  MicCheckStatus _status = MicCheckStatus.idle;
  int _remainingSeconds = _checkDurationSeconds;

  double _sumCurrentDb = 0;
  int _sampleCount = 0;

  double get _avgCurrentDb =>
      _sampleCount == 0 ? -double.infinity : _sumCurrentDb / _sampleCount;

  String t(String en, String th) => widget.isEnglish ? en : th;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startCheck() async {
    if (!await _recorder.hasPermission()) return;

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/mic_check.wav';

    setState(() {
      _status = MicCheckStatus.recording;
      _remainingSeconds = _checkDurationSeconds;
      _sumCurrentDb = 0;
      _sampleCount = 0;
    });

    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );

    await _recorder.start(config, path: path);

    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      if (amp.current.isFinite) {
        _sumCurrentDb += amp.current;
        _sampleCount++;
      }
    });

    _countdownTimer?.cancel();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        await _finishCheck();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _finishCheck() async {
    await _amplitudeSub?.cancel();
    await _recorder.stop();

    final avgDb = _avgCurrentDb;

    final result = avgDb < _quietThresholdDb
        ? MicCheckStatus.tooQuiet
        : MicCheckStatus.good;

    setState(() => _status = result);
  }

  String get _statusText {
    switch (_status) {
      case MicCheckStatus.idle:
        return t(
          'Press the mic and say "ah" briefly\nto check your volume before practicing',
          'กดปุ่มไมค์แล้วพูดคำว่า "อา" สั้นๆ\nเพื่อเช็คระดับเสียงก่อนเริ่มฝึก',
        );
      case MicCheckStatus.recording:
        return t(
          'Listening... ($_remainingSeconds s)\nSpeak now',
          'กำลังฟัง... ($_remainingSeconds วิ)\nพูดออกเสียงได้เลย',
        );
      case MicCheckStatus.tooQuiet:
        return t(
          'A bit too quiet 🔉\nTry moving the mic closer to your mouth',
          'เสียงเบาไปหน่อยนะ 🔉\nลองขยับไมค์เข้ามาใกล้ปากอีกนิด',
        );
      case MicCheckStatus.good:
        return t(
          'Volume is good ✅\nReady to start practicing',
          'ระดับเสียงพอดี ✅\nพร้อมเริ่มฝึกได้เลย',
        );
    }
  }

  Color get _statusColor {
    switch (_status) {
      case MicCheckStatus.tooQuiet:
        return Colors.red;
      case MicCheckStatus.good:
        return Colors.green;
      case MicCheckStatus.recording:
        return Colors.blue;
      case MicCheckStatus.idle:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case MicCheckStatus.tooQuiet:
        return Icons.volume_down;
      case MicCheckStatus.good:
        return Icons.check_circle;
      case MicCheckStatus.recording:
        return Icons.mic;
      case MicCheckStatus.idle:
        return Icons.mic_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _status == MicCheckStatus.recording;
    final passed = _status == MicCheckStatus.good;
    final showDb = _status == MicCheckStatus.tooQuiet || passed;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t('Mic Check', 'เช็คไมโครโฟน'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                Icon(_statusIcon, size: 64, color: _statusColor),
                const SizedBox(height: 16),

                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                if (showDb) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${_avgCurrentDb.toStringAsFixed(1)} dB',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 28),

                GestureDetector(
                  onTap: isRecording ? null : _startCheck,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isRecording ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        passed ? () => Navigator.pop(context) : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(t('Done', 'เสร็จสิ้น')),
                  ),
                ),

                if (_status == MicCheckStatus.tooQuiet) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _startCheck,
                    child: Text(t('Try again', 'ลองใหม่อีกครั้ง')),
                  ),
                ],
              ],
            ),
          ),

          // Close button (top-right)
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.grey[700], size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
