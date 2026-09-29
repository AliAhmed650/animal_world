import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'wiki_service.dart';

/// One shared player so only one animal is heard at a time.
class SoundPlayer {
  SoundPlayer._();

  static final AudioPlayer player = AudioPlayer();
  static String? currentUrl;
  static Timer? _timer;

  /// Plays at most 15 seconds of the recording.
  static Future<bool> play(SoundInfo s) async {
    try {
      _timer?.cancel();
      await player.stop();
      currentUrl = s.url;
      await player.setUrl(s.url, headers: kHeaders);
      unawaited(player.play());
      _timer = Timer(const Duration(seconds: 15), () {
        player.stop();
      });
      return true;
    } catch (_) {
      currentUrl = null;
      return false;
    }
  }

  static Future<void> stop() async {
    _timer?.cancel();
    try {
      await player.stop();
    } catch (_) {}
  }
}
