import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/movies/presentation/pages/home_page.dart';
import 'features/movies/presentation/pages/movie_details_page.dart';
import 'features/movies/presentation/pages/search_page.dart';
import 'features/movies/presentation/pages/video_player_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'movie/:id',
          builder: (context, state) =>
              MovieDetailsPage(movieId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: 'video/:id',
          builder: (context, state) =>
              VideoPlayerPage(youtubeKey: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'search',
          builder: (context, state) => const SearchPage(),
        ),
      ],
    ),
  ],
);
