import 'package:dio/dio.dart';
import 'env.dart';

Dio buildTMDBDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'accept': 'application/json',
        if (Env.tmdbV4Token.isNotEmpty)
          'Authorization': 'Bearer ${Env.tmdbV4Token}',
      },
      queryParameters: {
        if (Env.tmdbV4Token.isEmpty && Env.tmdbV3Key.isNotEmpty)
          'api_key': Env.tmdbV3Key,
        'language': Env.language,
      },
    ),
  );

  dio.interceptors.add(LogInterceptor(responseBody: false));
  return dio;
}
