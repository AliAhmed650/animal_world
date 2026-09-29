import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'wiki_service.dart';

/// One shared player so only one animal is heard at a time.
class SoundPlayer {
  SoundPlayer._();

  // The User-Agent is set on the player itself (no local proxy needed).
  static final AudioPlayer player =
      AudioPlayer(userAgent: kHeaders['User-Agent']);

  /// The recording that is currently loaded (always the original file URL).
  static String? currentUrl;

  /// Last playback error, shown in the UI to make problems easy to diagnose.
  static String? lastError;

  static Timer? _timer;

  // Commons keeps an MP3 copy of most audio files. It is a good fallback for
  // phones that can't decode the original .ogg/.oga/.opus file.
  static List<String> _candidates(String url) {
    final list = <String>[url];
    final m = RegExp(r'^(https://upload\.wikimedia\.org/wikipedia/commons)/([0-9a-f]/[0-9a-f]{2})/([^/]+)$')
        .firstMatch(url);
    if (m != null && !url.toLowerCase().endsWith('.mp3')) {
      list.add('${m[1]}/transcoded/${m[2]}/${m[3]}/${m[3]}.mp3');
    }
    return list;
  }

  /// Plays at most 15 seconds of the recording.
  static Future<bool> play(SoundInfo s) async {
    _timer?.cancel();
    lastError = null;
    try {
      await player.stop();
    } catch (_) {}
    currentUrl = s.url;
    for (final url in _candidates(s.url)) {
      try {
        await player.setUrl(url);
        unawaited(player.play());
        _timer = Timer(const Duration(seconds: 15), () {
          player.stop();
        });
        return true;
      } catch (e) {
        lastError = e.toString();
      }
    }
    currentUrl = null;
    return false;
  }

  static Future<void> stop() async {
    _timer?.cancel();
    try {
      await player.stop();
    } catch (_) {}
  }
}
