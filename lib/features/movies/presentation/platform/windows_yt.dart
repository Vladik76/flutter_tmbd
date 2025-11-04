import 'package:flutter/services.dart';

class WindowsYT {
  static const _ch = MethodChannel('win_yt');

  static Future<void> showYouTubeEmbed(String youtubeKey) async {
    final url = 'https://www.youtube.com/embed/$youtubeKey'
        '?autoplay=1&modestbranding=1&rel=0';
    await _ch.invokeMethod('showYouTube', {'url': url});
  }

  static Future<void> navigate(String youtubeKey) async {
    final url = 'https://www.youtube.com/embed/$youtubeKey'
        '?autoplay=1&modestbranding=1&rel=0';
    await _ch.invokeMethod('navigate', {'url': url});
  }

  static Future<void> close() async {
    await _ch.invokeMethod('close');
  }
}
