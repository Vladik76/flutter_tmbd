import 'package:flutter/material.dart';

import '../../data/movies_service.dart';
import '../widgets/poster_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _svc = MoviesService();
  final _controller = TextEditingController();

  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;
  String _error = '';

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      _results = await _svc.searchMovies(q);
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Movie title…',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_controller.text),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.66,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final m = _results[i];
                return PosterTile(
                  movieId: m['id'] as int,
                  posterPath: m['poster_path'] as String?,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
