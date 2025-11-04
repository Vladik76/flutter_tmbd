import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PosterTile extends StatelessWidget {
  final int movieId;
  final String? posterPath;
  final double borderRadius;

  const PosterTile({
    super.key,
    required this.movieId,
    required this.posterPath,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final url = (posterPath ?? '').isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: Colors.grey.shade200,
        child: InkWell(
          onTap: () => context.push('/movie/$movieId'),
          child: url != null
              ? Ink.image(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                  child: const SizedBox.expand(),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}
