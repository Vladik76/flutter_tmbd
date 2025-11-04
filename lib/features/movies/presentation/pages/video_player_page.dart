import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoPlayerPage extends StatefulWidget {
  final String youtubeKey;
  const VideoPlayerPage({super.key, required this.youtubeKey});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  YoutubePlayerController? _yt;
  bool _checked = false;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initController(_ensureVideoId(widget.youtubeKey));
      _checked = true;
    } else if (_isMobile) {
      _guardPlayOnMobile();
    } else {
      _checked = true; // desktop: показываем фолбэк
      setState(() {});
    }
  }

  @override
  void dispose() {
    _yt?.close();
    super.dispose();
  }

  String _ensureVideoId(String raw) {
    final m = RegExp(r'([A-Za-z0-9_-]{11})').firstMatch(raw);
    return m?.group(1) ?? raw;
  }

  Future<void> _guardPlayOnMobile() async {
    final id = _ensureVideoId(widget.youtubeKey);
    final uri = Uri.parse(
      'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$id&format=json',
    );

    bool embeddable = false;
    try {
      final r = await http.get(uri);
      embeddable = r.statusCode == 200;
    } catch (_) {
      embeddable = false;
    }

    if (!mounted) return;

    if (embeddable) {
      _initController(id);
      _checked = true;
      setState(() {});
    } else {
      await _openExternally(id);
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  void _initController(String id) {
    _yt = YoutubePlayerController.fromVideoId(
      videoId: id,
      autoPlay: true,
      params: const YoutubePlayerParams(
        playsInline: true,
        showFullscreenButton: true,
        strictRelatedVideos: false,
      ),
    );
  }

  Future<void> _openExternally(String id) async {
    final url = 'https://www.youtube.com/watch?v=$id';
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final id = _ensureVideoId(widget.youtubeKey);
    final externalUrl = 'https://www.youtube.com/watch?v=$id';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trailer'),
        actions: [
          IconButton(
            tooltip: 'Open in YouTube',
            onPressed: () => launchUrlString(externalUrl,
                mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Center(
        child: kIsWeb
            ? AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(controller: _yt!, aspectRatio: 16 / 9),
              )
            : _isMobile
                ? (!_checked
                    ? const SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator())
                    : _yt != null
                        ? AspectRatio(
                            aspectRatio: 16 / 9,
                            child: YoutubePlayer(
                                controller: _yt!, aspectRatio: 16 / 9),
                          )
                        : const Text('Opening in YouTube…'))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            'Inline playback is not available on desktop.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => launchUrlString(externalUrl,
                              mode: LaunchMode.externalApplication),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Open in YouTube'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
