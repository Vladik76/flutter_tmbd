import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/env.dart';

class MovieDetailsPage extends StatefulWidget {
  final int movieId;
  const MovieDetailsPage({super.key, required this.movieId});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  late final Dio _dio;
  Map<String, dynamic>? _details;
  String _error = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.themoviedb.org/3',
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer ${Env.tmdbV4Token}',
        },
      ),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final res = await _dio.get(
        '/movie/${widget.movieId}',
        queryParameters: {
          'append_to_response': 'videos,images,credits',
          'language': Env.language,
        },
      );
      _details = (res.data as Map).cast<String, dynamic>();
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _details;
    return Scaffold(
      appBar: AppBar(title: Text('Movie #${widget.movieId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16), child: Text(_error)))
              : d == null
                  ? const Center(child: Text('No details'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if ((d['title'] ?? d['name']) != null)
                          Text(
                            (d['title'] ?? d['name']).toString(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        if ((d['overview'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(d['overview']),
                        ],
                        const SizedBox(height: 24),
                        _VideosSection(details: d),
                      ],
                    ),
    );
  }
}

class _VideosSection extends StatelessWidget {
  const _VideosSection({required this.details});
  final Map<String, dynamic> details;

  String _ytId(String raw) {
    final m = RegExp(r'([A-Za-z0-9_-]{11})').firstMatch(raw);
    return m?.group(1) ?? raw;
  }

  Future<bool> _ytEmbeddable(String id) async {
    final uri = Uri.parse(
      'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$id&format=json',
    );
    try {
      final r = await http.get(uri);
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openExternally(String id) async {
    final url = 'https://www.youtube.com/watch?v=$id';
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  Widget _videoCard(BuildContext context, Map<String, dynamic> v) {
    final id = v['key'] as String;
    final title = (v['name'] ?? 'Trailer').toString();
    final subtitle = [
      (v['type'] ?? '').toString(),
      if (v['official'] == true) 'Official',
    ].where((e) => e.isNotEmpty).join(' • ');
    final thumb = 'https://img.youtube.com/vi/$id/hqdefault.jpg';

    Future<void> open() async {
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        if (context.mounted) context.push('/video/$id');
        return;
      }
      final ok = await _ytEmbeddable(id);
      if (ok) {
        if (context.mounted) context.push('/video/$id');
      } else {
        await _openExternally(id);
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Row(
          children: [
            SizedBox(
              width: 160,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0x11000000),
                    child: Center(child: Icon(Icons.play_circle_outline)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Open in YouTube',
              onPressed: () => _openExternally(id),
              icon: const Icon(Icons.open_in_new),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = (details['videos']?['results'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    final yt = raw
        .where((v) => (v['site'] ?? '').toString().toLowerCase() == 'youtube')
        .map((v) {
          final key = _ytId((v['key'] ?? '').toString());
          return {...v, 'key': key};
        })
        .where((v) => (v['key'] as String).length == 11)
        .toList();

    if (yt.isEmpty) return const SizedBox.shrink();

    yt.sort((a, b) {
      final aPri =
          ((a['type'] ?? '').toString().toLowerCase() == 'trailer' ? 1 : 0) +
              ((a['official'] == true) ? 1 : 0);
      final bPri =
          ((b['type'] ?? '').toString().toLowerCase() == 'trailer' ? 1 : 0) +
              ((b['official'] == true) ? 1 : 0);
      return bPri.compareTo(aPri);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Videos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: yt.length,
          itemBuilder: (c, i) => _videoCard(c, yt[i]),
        ),
      ],
    );
  }
}
