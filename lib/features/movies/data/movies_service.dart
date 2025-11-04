import 'package:dio/dio.dart';
import '../../../core/dio_client.dart';
import '../../../core/tmdb_endpoints.dart';

class MoviesService {
  final Dio _dio;
  MoviesService({Dio? dio}) : _dio = dio ?? buildTMDBDio();

  Future<Map<String, dynamic>> getPopular({int page = 1}) async {
    final res = await _dio.get(TMDB.popular, queryParameters: {'page': page});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getTrendingWeek({int page = 1}) async {
    final res =
        await _dio.get(TMDB.trendingWeek, queryParameters: {'page': page});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getMovieDetails(int id) async {
    final res = await _dio.get(TMDB.movieDetails(id),
        queryParameters: {'append_to_response': 'videos,images'});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getMovieCredits(int id) async {
    final res = await _dio.get(TMDB.movieCredits(id));
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> searchMovies(String query,
      {int page = 1, bool includeAdult = false}) async {
    final res = await _dio.get(TMDB.searchMovie, queryParameters: {
      'query': query,
      'page': page,
      'include_adult': includeAdult,
    });
    return Map<String, dynamic>.from(res.data);
  }
}
