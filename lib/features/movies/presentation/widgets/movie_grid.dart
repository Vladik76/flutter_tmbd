import 'package:flutter/material.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  final List movies;
  const MovieGrid({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: movies.length,
      itemBuilder: (context, i) => MovieCard(movie: movies[i]),
    );
  }
}
