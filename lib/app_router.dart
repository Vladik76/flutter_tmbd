import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/movies/presentation/pages/home_page.dart';
import 'features/movies/presentation/pages/movie_details_page.dart';
import 'features/movies/presentation/pages/search_page.dart';
import 'features/movies/presentation/pages/video_player_page.dart';

final appRouter = GoRouter(
  routes: [
    // Корень → /movies
    GoRoute(
      path: '/',
      redirect: (_, __) => '/movies',
    ),

    // /movies  (+ query: q, list, page)
    GoRoute(
      path: '/movies',
      name: 'movies',
      pageBuilder: (context, state) {
        final qp = state.uri.queryParameters;
        final initialQuery = qp['q'];
        final initialList =
            qp['list']; // на будущее: trending|popular|top_rated
        final initialPage = int.tryParse(qp['page'] ?? '1');

        return NoTransitionPage(
          child: HomePage(
            initialQuery: initialQuery,
            initialList: initialList,
            initialPage: initialPage,
          ),
        );
      },
      routes: [
        // /movies/:id
        GoRoute(
          path: ':id',
          name: 'movie-details',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return const NoTransitionPage(
                child: Scaffold(body: Center(child: Text('Invalid movie id'))),
              );
            }
            return NoTransitionPage(child: MovieDetailsPage(movieId: id));
          },
        ),
      ],
    ),

    // ---- Совместимость со старыми путями (необязательно, но удобно) ----
    // /movie/:id → /movies/:id
    GoRoute(
      path: '/movie/:id',
      redirect: (context, state) => '/movies/${state.pathParameters['id']}',
    ),

    // /video/:id (как было)
    GoRoute(
      path: '/video/:id',
      builder: (context, state) =>
          VideoPlayerPage(youtubeKey: state.pathParameters['id']!),
    ),

    // /search (оставляем, если пользуешься отдельно)
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
  ],
  errorPageBuilder: (context, state) => const NoTransitionPage(
    child: Scaffold(body: Center(child: Text('Page not found'))),
  ),
);
