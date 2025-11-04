class TMDB {
  static const trendingWeek = '/trending/movie/week';
  static const popular = '/movie/popular';
  static String movieDetails(int id) => '/movie/$id';
  static String movieCredits(int id) => '/movie/$id/credits';
  static const searchMovie = '/search/movie';
}
