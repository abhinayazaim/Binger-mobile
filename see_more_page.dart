import 'package:flutter/material.dart';
import 'package:bingerr/homepage.dart'; // Import model Movie
import 'moviedetail.dart';

class SeeMorePage extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  const SeeMorePage({super.key, required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(title, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://image.tmdb.org/t/p/w200${movie.posterPath}',
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 75,
                      color: Colors.grey,
                      child: const Icon(Icons.movie_outlined),
                    );
                  },
                ),
              ),
              title: Text(movie.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(movie.voteAverage.toStringAsFixed(1)),
                ],
              ),
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailPage(movieId: movies[index].id, mediaType: movies[index].mediaType),
                ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
