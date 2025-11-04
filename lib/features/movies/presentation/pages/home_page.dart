import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/env.dart';
import '../widgets/poster_tile.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Dio _dio;

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
  }

  Future<List<Map<String, dynamic>>> _fetchPopular({int page = 1}) async {
    final res = await _dio.get('/movie/popular', queryParameters: {
      'language': Env.language,
      'page': page,
    });
    return (res.data['results'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular'),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPopular(),
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
