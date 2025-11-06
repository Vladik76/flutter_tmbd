import 'package:dio/dio.dart';
import '../../../../core/env.dart';

class MoviesService {
  MoviesService._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.themoviedb.org/3',
            headers: {
              'accept': 'application/json',
              'Authorization': 'Bearer ${Env.tmdbV4Token}',
            },
          ),
        );
  static final MoviesService _instance = MoviesService._internal();
  factory MoviesService() => _instance;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getPopular({int page = 1}) async {
    final res = await _dio.get('/movie/popular', queryParameters: {
      'language': Env.language,
      'page': page,
    });
    return (res.data['results'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query,
      {int page = 1, bool includeAdult = false}) async {
    final res = await _dio.get('/search/movie', queryParameters: {
      'query': query,
      'include_adult': includeAdult,
      'language': Env.language,
      'page': page,
    });
    return (res.data['results'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  /// Loads a movie with videos/images/credits (single call).
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final res = await _dio.get('/movie/$movieId', queryParameters: {
      'append_to_response': 'videos,images,credits',
      'language': Env.language,
    });
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Helpers (optional)

  /// Extract only YouTube videos (trailer/teaser/clip) and normalize keys to 11-char ID.
  List<Map<String, dynamic>> youtubeVideosFromDetails(
      Map<String, dynamic> details) {
    String ytId(String raw) {
      final m = RegExp(r'([A-Za-z0-9_-]{11})').firstMatch(raw);
      return m?.group(1) ?? raw;
    }

    final raw = (details['videos']?['results'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final vids = raw
        .where((v) => (v['site'] ?? '').toString().toLowerCase() == 'youtube')
        .where((v) {
          final t = (v['type'] ?? '').toString().toLowerCase();
          return t == 'trailer' || t == 'teaser' || t == 'clip';
        })
        .map((v) => {...v, 'key': ytId((v['key'] ?? '').toString())})
        .where((v) => (v['key'] as String).length == 11)
        .toList();

    vids.sort((a, b) {
      int score(Map x) =>
          ((x['type'] ?? '').toString().toLowerCase() == 'trailer' ? 2 : 0) +
          ((x['official'] == true) ? 1 : 0);
      return score(b).compareTo(score(a));
    });
    return vids;
  }
}
