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

  Future<void> toggle(String assetPath, {required VoidCallback onError}) async {
    if (isPlaying) {
      await _player.stop();
      isPlaying = false;
      return;
    }
    try {
      isPlaying = true;
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      isPlaying = false;
      onError();
    }
  }

  void dispose() => _player.dispose();
}
