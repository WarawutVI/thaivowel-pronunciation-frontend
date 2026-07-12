import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

class SamplePlayer {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;

  SamplePlayer({required VoidCallback onStateChanged}) {
    _player.onPlayerComplete.listen((_) {
      isPlaying = false;
      onStateChanged();
    });
  }

  static const _extensions = ['wav', 'm4a'];

  /// [basePath] should omit the file extension — each candidate in
  /// [_extensions] is tried in turn, since sample files aren't all the
  /// same format.
  Future<void> toggle(String basePath, {required VoidCallback onError}) async {
    if (isPlaying) {
      await _player.stop();
      isPlaying = false;
      return;
    }
    isPlaying = true;
    for (final ext in _extensions) {
      try {
        await _player.play(AssetSource('$basePath.$ext'));
        return;
      } catch (_) {
        // Try the next extension.
      }
    }
    isPlaying = false;
    onError();
  }

  void dispose() => _player.dispose();
}
