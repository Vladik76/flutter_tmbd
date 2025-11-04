class TMDBImage {
  static const _base = 'https://image.tmdb.org/t/p/';
  static String w500(String? path) => path == null ? '' : '${_base}w500$path';
  static String original(String? path) =>
      path == null ? '' : '${_base}original$path';
}
