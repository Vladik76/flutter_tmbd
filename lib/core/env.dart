import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get tmdbV4Token =>
      dotenv.env['TMDB_V4_TOKEN'] ??
      const String.fromEnvironment('TMDB_V4_TOKEN');

  static String get tmdbV3Key =>
      dotenv.env['TMDB_V3_KEY'] ?? const String.fromEnvironment('TMDB_V3_KEY');

  static String get language =>
      dotenv.env['TMDB_LANG'] ??
      const String.fromEnvironment('TMDB_LANG', defaultValue: 'en-US');
}
