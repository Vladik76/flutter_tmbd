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
  bool _loading = true;
  String _error = '';

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
      if (mounted) _loading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(16), child: Text(_error))),
      );
    }
    final d = _details!;
    final title = (d['title'] ?? d['name'] ?? '').toString();
    final overview = (d['overview'] ?? '').toString();
    final poster = d['poster_path'] as String?;
    final backdrop = d['backdrop_path'] as String?;
    final vote = (d['vote_average'] ?? 0.0) * 1.0;
    final genres = ((d['genres'] as List?) ?? [])
        .cast<Map>()
        .map((g) => g['name'].toString())
        .toList();
    final date = (d['release_date'] ?? '').toString();
    final runtime = d['runtime'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 240,
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdrop != null)
                    Image.network('https://image.tmdb.org/t/p/w780$backdrop',
                        fit: BoxFit.cover),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black45],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth > 720;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (poster != null && poster.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w342$poster',
                            width: wide ? 220 : 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (poster != null && poster.isNotEmpty)
                        const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (poster == null || poster.isEmpty)
                              Text(title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (date.isNotEmpty)
                                  _MetaChip(icon: Icons.event, label: date),
                                if (runtime is num && runtime > 0)
                                  _MetaChip(
                                      icon: Icons.access_time,
                                      label: '${runtime}m'),
                                if (vote > 0)
                                  _MetaChip(
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
                            if (overview.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text('Overview',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
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
          ),
          // ----- TRAILERS (HORIZONTAL STRIP) -----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child:
                  Text('Videos', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalTrailers(details: d),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label));
  }
}

class _HorizontalTrailers extends StatelessWidget {
  const _HorizontalTrailers({required this.details});
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

    // only YouTube, keep common types, normalize to 11-char id
    final vids = raw
        .where((v) => (v['site'] ?? '').toString().toLowerCase() == 'youtube')
        .where((v) {
          final t = (v['type'] ?? '').toString().toLowerCase();
          return t == 'trailer' || t == 'teaser' || t == 'clip';
        })
        .map((v) => {...v, 'key': _ytId((v['key'] ?? '').toString())})
        .where((v) => (v['key'] as String).length == 11)
        .toList();

    if (vids.isEmpty) {
      return const SizedBox.shrink();
    }

    // prioritize official trailers
    vids.sort((a, b) {
      int score(Map x) =>
          ((x['type'] ?? '').toString().toLowerCase() == 'trailer' ? 2 : 0) +
          ((x['official'] == true) ? 1 : 0);
      return score(b).compareTo(score(a));
    });

    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: vids.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final v = vids[i];
          final id = v['key'] as String;
          final title = (v['name'] ?? 'Trailer').toString();
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

          return GestureDetector(
            onTap: open,
            child: SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // thumbnail with overlay play
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(thumb, fit: BoxFit.cover),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black38],
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_fill,
                                size: 56, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
