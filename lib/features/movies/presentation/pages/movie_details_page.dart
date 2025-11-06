// lib/features/movies/presentation/pages/movie_details_page.dart
import 'dart:io' show Platform;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

import '../../data/movies_service.dart';

class MovieDetailsPage extends StatefulWidget {
  final int movieId;
  const MovieDetailsPage({super.key, required this.movieId});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  final _svc = MoviesService();

  Map<String, dynamic>? _details;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      _details = await _svc.getMovieDetails(widget.movieId);
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error.isNotEmpty) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(_error)));
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

    // --- Windows-friendly scroll behavior (mouse + trackpad + touch) ---
    final behavior = const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      },
    );

    return Scaffold(
      body: ScrollConfiguration(
        behavior: behavior,
        child: Scrollbar(
          thumbVisibility: false,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 320, // выше, чтобы баннер выглядел «богаче»
                title:
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: _BackdropHeader(
                    backdropPath: backdrop,
                    posterPath: poster,
                    title: title,
                    voteAverage: vote,
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
                            _PosterCard(
                              path: poster,
                              width: wide ? 240 : 180,
                            ),
                          if (poster != null && poster.isNotEmpty)
                            const SizedBox(width: 16),
                          // ---- META + OVERVIEW
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
                                      const _MetaIcon(icon: Icons.event),
                                    if (date.isNotEmpty) Text(date),
                                    if (runtime is num && runtime > 0) ...[
                                      const _MetaIcon(icon: Icons.access_time),
                                      Text('${runtime}m'),
                                    ],
                                    if (vote > 0) ...[
                                      const _MetaIcon(icon: Icons.star_rounded),
                                      Text(vote.toStringAsFixed(1)),
                                    ],
                                  ],
                                ),
                                if (genres.isNotEmpty)
                                  const SizedBox(height: 10),
                                if (genres.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: genres
                                        .map(
                                          (g) => Chip(
                                            label: Text(g),
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                if (overview.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text('Overview',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
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
              // ----- Horizontal trailers -----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Videos',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              SliverToBoxAdapter(
                child: _HorizontalTrailers(
                  details: d,
                  svc: _svc,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== UI PIECES =================================================================

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 16);
  }
}

/// Backdrop header tuned for desktop (Windows): high-res + dark gradient.
class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({
    required this.backdropPath,
    required this.posterPath,
    required this.title,
    required this.voteAverage,
  });

  final String? backdropPath;
  final String? posterPath;
  final String title;
  final double voteAverage;

  @override
  Widget build(BuildContext context) {
    final bg = backdropPath != null && backdropPath!.isNotEmpty
        ? 'https://image.tmdb.org/t/p/original$backdropPath' // high-res
        : (posterPath != null && posterPath!.isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500$posterPath'
            : null);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (bg != null)
          Image.network(bg,
              fit: BoxFit.cover, filterQuality: FilterQuality.medium)
        else
          Container(color: Colors.black12),
        // Soft overlay to improve readability
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black45],
            ),
          ),
        ),
        // Title + vote at bottom-left (desktop friendly)
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
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
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Poster shows full image (2:3) and opens fullscreen dialog with zoom.
class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.path, required this.width});

  final String path;
  final double width;

  void _showFullPoster(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          minScale: 0.7,
          maxScale: 5,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thumb = 'https://image.tmdb.org/t/p/w500$path';
    final full = 'https://image.tmdb.org/t/p/original$path';

    return GestureDetector(
      onTap: () => _showFullPoster(context, full),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Image.network(thumb, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ===== HORIZONTAL TRAILERS ======================================================

class _HorizontalTrailers extends StatelessWidget {
  const _HorizontalTrailers({required this.details, required this.svc});
  final Map<String, dynamic> details;
  final MoviesService svc;

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
    final vids = svc.youtubeVideosFromDetails(details);
    if (vids.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
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
              if (context.mounted) context.go('/video/$id');
              return;
            }
            final ok = await _ytEmbeddable(id);
            if (ok) {
              if (context.mounted) context.go('/video/$id');
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
                  // thumbnail + overlay
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
