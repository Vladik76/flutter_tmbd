import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/tmdb_image.dart';

class MovieCard extends StatelessWidget {
  final Map movie;
  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final int? id = movie['id'] is int
        ? movie['id'] as int
        : int.tryParse('${movie['id']}');
    final String title = (movie['title'] ?? 'Untitled').toString();
    final posterUrl = TMDBImage.w500(movie['poster_path']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (id == null)
            ? null
            : () {
                // Use the named route defined in app_router.dart:
                // GoRoute name: 'movie_details', path: '/movie/:id'
                context.pushNamed(
                  'movie_details',
                  pathParameters: {'id': id.toString()},
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Optional: Hero for smooth transition
              Hero(
                tag: 'movie:$id',
                child: posterUrl.isNotEmpty
                    ? Image.network(posterUrl, fit: BoxFit.cover)
                    : Container(color: Colors.black12),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  color: Colors.black54,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
