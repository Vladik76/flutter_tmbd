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
                    padding: const EdgeInsets.all(16),
                    child: Text(_error),
                  ),
                )
              : d == null
                  ? const Center(child: Text('No details'))
                  : _Content(details: d),
    );
  }
}

/// Pretty, information-dense layout with backdrop, poster, meta, overview, and videos.
class _Content extends StatelessWidget {
  const _Content({required this.details});
  final Map<String, dynamic> details;

  String _img(String? path, String size) => (path == null || path.isEmpty)
      ? ''
      : 'https://image.tmdb.org/t/p/$size$path';

  @override
  Widget build(BuildContext context) {
    final title = (details['title'] ?? details['name'] ?? '').toString();
    final overview = (details['overview'] ?? '').toString();
    final poster = _img(details['poster_path'] as String?, 'w342');
    final backdrop = _img(details['backdrop_path'] as String?, 'w780');
    final vote = (details['vote_average'] ?? 0.0) * 1.0;
    final genres = ((details['genres'] as List?) ?? [])
        .cast<Map>()
        .map((g) => g['name'].toString())
        .toList();
    final runtime = details['runtime'];
    final date = (details['release_date'] ?? '').toString();

    return ListView(
      children: [
        // Backdrop header
        if (backdrop.isNotEmpty)
          _BackdropHeader(imageUrl: backdrop, title: title, voteAverage: vote),

        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth > 700;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster
                  if (poster.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        poster,
                        width: isWide ? 220 : 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (poster.isNotEmpty) const SizedBox(width: 16),

                  // Meta + overview
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (poster.isEmpty)
                          Text(title,
                              style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (date.isNotEmpty)
                              _Chip(icon: Icons.event, label: date),
                            if (runtime is num && runtime > 0)
                              _Chip(
                                  icon: Icons.access_time,
                                  label: '${runtime}m'),
                            if (vote > 0)
                              _Chip(
                                  icon: Icons.star_rounded,
                                  label: vote.toStringAsFixed(1)),
                          ],
                        ),
                        if (genres.isNotEmpty) const SizedBox(height: 10),
                        if (genres.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: genres
                                .map((g) => Chip(
                                      label: Text(g),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                    ))
                                .toList(),
                          ),
                        const SizedBox(height: 16),
                        if (overview.isNotEmpty) ...[
                          Text('Overview',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(overview),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Videos
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: _VideosSection(details: details),
        ),
      ],
    );
  }
}

class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({
    required this.imageUrl,
    required this.title,
    required this.voteAverage,
  });

  final String imageUrl;
  final String title;
  final double voteAverage;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(imageUrl, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black38],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                    ),
                  ),
                ),
                if (voteAverage > 0) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    voteAverage.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

/// Videos list with thumbnail preview and Android/iOS embed guard.
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

    // Prioritize official trailers
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
}
