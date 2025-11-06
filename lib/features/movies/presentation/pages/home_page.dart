import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/movies_service.dart';
import '../widgets/poster_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.initialQuery,
    this.initialList,
    this.initialPage,
  });

  final String? initialQuery; // ?q=...
  final String? initialList; // ?list=trending|popular|top_rated (на будущее)
  final int? initialPage; // ?page=...

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _svc = MoviesService();

  bool get _isSearchMode =>
      (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty);

  late String _query; // активный поисковый запрос
  late int _page; // активная страница поиска

  Future<List<Map<String, dynamic>>>? _future; // текущий future для списка


  @override
  void initState() {
    super.initState();
    _future = _svc.getPopular();
  }

  @override
  Widget build(BuildContext context) {
     // Если режим поиска по URL → показываем поиск
    if (_isSearchMode && _future != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Search: $_query'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final movies = snap.data ?? const [];
            if (movies.isEmpty) {
              return const Center(child: Text('No results'));
            }

            // оставляю твой же виджет сетки/плиток
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // как у тебя
                childAspectRatio: .66,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: movies.length,
              itemBuilder: (context, i) {
                final m = movies[i];
                return PosterTile(
                  movieId: m['id'] as int,
                  posterPath: m['poster_path'] as String?,
                );
              },
            );
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load: ${snap.error}'),
              ),
            );
          }
          final movies = snap.data ?? const [];
          if (movies.isEmpty) return const Center(child: Text('No movies'));

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.66,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: movies.length,
            itemBuilder: (context, i) {
              final m = movies[i];
              return PosterTile(
                movieId: m['id'] as int,
                posterPath: m['poster_path'] as String?,
              );
            },
          );
        },
      ),
    );
  }
}
