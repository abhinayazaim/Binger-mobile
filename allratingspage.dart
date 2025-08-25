import 'package:flutter/material.dart';
import 'moviedetail.dart';


class AllRatingsPage extends StatefulWidget {
  final List<Map<String, dynamic>> ratings;
  
  const AllRatingsPage({
    super.key,
    required this.ratings,
  });

  @override
  _AllRatingsPageState createState() => _AllRatingsPageState();
}

class _AllRatingsPageState extends State<AllRatingsPage> {
  List<Map<String, dynamic>> filteredRatings = [];
  String _sortBy = 'rating'; // Default sort by rating
  bool _ascending = false; // Default descending (highest first)
  
  @override
  void initState() {
    super.initState();
    filteredRatings = List.from(widget.ratings);
    _sortRatings();
  }
  
  void _sortRatings() {
    setState(() {
      if (_sortBy == 'rating') {
        filteredRatings.sort((a, b) {
          final comparison = (a['rating'] as double).compareTo(b['rating'] as double);
          return _ascending ? comparison : -comparison;
        });
      } else if (_sortBy == 'title') {
        filteredRatings.sort((a, b) {
          final comparison = (a['title'] as String).compareTo(b['title'] as String);
          return _ascending ? comparison : -comparison;
        });
      } else if (_sortBy == 'date') {
        filteredRatings.sort((a, b) {
          final aTime = a['timestamp'] ?? 0;
          final bTime = b['timestamp'] ?? 0;
          final comparison = aTime.compareTo(bTime);
          return _ascending ? comparison : -comparison;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Your Ratings'),
        backgroundColor: Colors.amber,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              if (value == _sortBy) {
                setState(() {
                  _ascending = !_ascending;
                });
              } else {
                setState(() {
                  _sortBy = value;
                  _ascending = false; // Reset to descending when changing sort type
                });
              }
              _sortRatings();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rating',
                child: Text('Sort by Rating'),
              ),
              const PopupMenuItem(
                value: 'title',
                child: Text('Sort by Title'),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Recently Rated'),
              ),
            ],
          ),
        ],
      ),
      body: filteredRatings.isEmpty
          ? const Center(
              child: Text('No rated movies yet', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              itemCount: filteredRatings.length,
              itemBuilder: (context, index) {
                final movie = filteredRatings[index];
                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    child: movie['poster_path'] != null
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 30),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.movie, size: 30),
                          ),
                  ),
                  title: Text(
                    movie['title'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    movie['media_type'] == 'tv' ? 'TV Show' : 'Movie',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        (movie['rating'] as double).toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailPage(
          movieId: movie['id'], 
          mediaType: movie['media_type'] ?? 'movie',
        ),
      ),
    );
  },
                );
              },
            ),
    );
  }
}