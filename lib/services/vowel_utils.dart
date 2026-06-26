import 'dart:typed_data';
import 'package:flutter/material.dart';

// Maps vowelId (1–18 from DB) to Flask index (0–17) and asset filename.
int vowelIdToIndex(int vowelId) => vowelId - 1;

String vowelIndexToAssetName(int index) {
  if (index < 9) return '0${index + 1}';
  return 's${index - 8}';
}

/// Walks RIFF chunks to find "data" then decodes 16-bit PCM to
/// normalised [-1, 1] and downsamples to [targetPoints] for display.
List<double> decodePcmWav(Uint8List bytes, {int targetPoints = 200}) {
  if (bytes.length < 44) {
    debugPrint('[WAV] file too small: ${bytes.length}');
    return [];
  }

  final bd = ByteData.sublistView(bytes);
  final riff = String.fromCharCodes(bytes.sublist(0, 4));
  if (riff != 'RIFF') {
    debugPrint('[WAV] not RIFF (got "$riff")');
    return [];
  }

  int offset = 12;
  int dataStart = -1;
  int dataLen = 0;

  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final chunkSize = bd.getUint32(offset + 4, Endian.little);
    if (id == 'data') {
      dataStart = offset + 8;
      dataLen = chunkSize;
      break;
    }
    offset += 8 + chunkSize + (chunkSize.isOdd ? 1 : 0);
  }

  if (dataStart < 0 || dataLen == 0) {
    debugPrint('[WAV] "data" chunk not found');
    return [];
  }

  final end = (dataStart + dataLen).clamp(0, bytes.length);
  final pcm = bytes.sublist(dataStart, end);
  final sampleCount = pcm.length ~/ 2;
  if (sampleCount == 0) return [];

  final raw = List<double>.filled(sampleCount, 0.0);
  for (int i = 0; i < sampleCount; i++) {
    int s = (pcm[i * 2 + 1] << 8) | pcm[i * 2];
    if (s >= 0x8000) s -= 0x10000;
    raw[i] = s / 32768.0;
  }

  final step = raw.length / targetPoints;
  final result = List<double>.generate(
    targetPoints,
    (i) => raw[(i * step).toInt().clamp(0, raw.length - 1)],
  );

  final maxAbs =
      result.map((v) => v.abs()).fold(0.0, (a, b) => a > b ? a : b);
  if (maxAbs > 0) return result.map((v) => v / maxAbs).toList();
  return result;
}

/// Strips silence from both ends, then keeps the middle 50% of the signal.
List<double> preprocessSamples(List<double> samples,
    {double silenceThreshold = 0.02}) {
  if (samples.isEmpty) return [];

  int start = 0;
  while (start < samples.length && samples[start].abs() < silenceThreshold) {
    start++;
  }
  int end = samples.length - 1;
  while (end > start && samples[end].abs() < silenceThreshold) {
    end--;
  }

  final trimmed = samples.sublist(start, end + 1);
  if (trimmed.length < 10) return samples;

  final cropAmt = (trimmed.length * 0.25).round();
  final cropped = trimmed.sublist(cropAmt, trimmed.length - cropAmt);
  return cropped.length < 10 ? trimmed : cropped;
}

/// Draws reference (orange) and user (green) waveforms on a canvas.
class WaveformPainter extends CustomPainter {
  final List<double> refSamples;
  final List<double> userSamples;

  const WaveformPainter({required this.refSamples, required this.userSamples});

  void _drawWave(
      Canvas canvas, Size size, List<double> samples, Color color, double width) {
    if (samples.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final midY = size.height / 2;
    final path = Path();
    for (int i = 0; i < samples.length; i++) {
      final x = (i / (samples.length - 1)) * size.width;
      final y = midY - (samples[i] * midY * 0.85);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 0.8,
    );
    _drawWave(canvas, size, refSamples, Colors.orange.withValues(alpha: 0.9), 2.0);
    _drawWave(canvas, size, userSamples, const Color(0xFF2ECC71).withValues(alpha: 0.9), 1.8);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter old) =>
      old.refSamples != refSamples || old.userSamples != userSamples;
}

/// Draws a single waveform as filled vertical bars (mirrored above and below center).
class BarWaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;

  const BarWaveformPainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final midY = size.height / 2;
    final barW = ((size.width / samples.length) * 0.65).clamp(1.0, 4.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < samples.length; i++) {
      final x = (i / samples.length) * size.width + barW / 2;
      final h = (samples[i].abs() * midY * 0.9).clamp(1.5, midY);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, midY),
            width: barW,
            height: h * 2,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarWaveformPainter old) =>
      old.samples != samples || old.color != color;
}

/// Draws reference (orange) and user (green) as paired bars side by side.
/// Each position shows: [orange ref] [green user] so height differences are obvious.
class DualBarWaveformPainter extends CustomPainter {
  final List<double> refSamples;
  final List<double> userSamples;
  final int barCount;

  const DualBarWaveformPainter({
    required this.refSamples,
    required this.userSamples,
    this.barCount = 40,
  });

  List<double> _downsample(List<double> samples, int n) {
    if (samples.isEmpty) return List.filled(n, 0.0);
    final result    = List<double>.filled(n, 0.0);
    final groupSize = samples.length / n;
    for (int i = 0; i < n; i++) {
      final start = (i * groupSize).floor();
      final end   = ((i + 1) * groupSize).ceil().clamp(0, samples.length);
      double peak = 0.0;
      for (int j = start; j < end; j++) {
        final v = samples[j].abs();
        if (v > peak) peak = v;
      }
      result[i] = peak;
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ref  = _downsample(refSamples,  barCount);
    final user = _downsample(userSamples, barCount);

    final midY    = size.height / 2;
    final slot    = size.width / barCount;   // width per pair
    final barW    = (slot * 0.38).clamp(1.5, 6.0);
    final gap     = barW * 0.3;

    final refPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    final userPaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final centerX = slot * i + slot / 2;

      // orange ref — left of center
      final rh = (ref[i]  * midY * 0.9).clamp(1.5, midY);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX - barW / 2 - gap / 2, midY),
            width: barW, height: rh * 2,
          ),
          const Radius.circular(3),
        ),
        refPaint,
      );

      // green user — right of center
      final uh = (user[i] * midY * 0.9).clamp(1.5, midY);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX + barW / 2 + gap / 2, midY),
            width: barW, height: uh * 2,
          ),
          const Radius.circular(3),
        ),
        userPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DualBarWaveformPainter old) =>
      old.refSamples != refSamples ||
      old.userSamples != userSamples ||
      old.barCount != barCount;
}
