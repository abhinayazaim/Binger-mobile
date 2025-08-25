import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TMDBService {
  final String apiKey = 'd54c8ae5d997772ae7a6879e252e6785'; 
  final String baseUrl = 'https://api.themoviedb.org/3';

  // Fetch popular movies
  Future<List<Movie>> fetchPopularMovies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/popular?api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      
      return results.map((movieJson) => Movie.fromJson(movieJson)).toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  // Search movies
  Future<List<Movie>> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$query'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      
      return results.map((movieJson) => Movie.fromJson(movieJson)).toList();
    } else {
      throw Exception('Failed to search movies');
    }
  }

  // Get movie details
  Future<MovieDetail> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$movieId?api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return MovieDetail.fromJson(data);
    } else {
      throw Exception('Failed to load movie details');
    }
  }
}

// Movie model for basic movie information
class Movie {
  final int id;
  final String title;
  final String posterPath;
  final String overview;
  final double voteAverage;

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.voteAverage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] as num).toDouble(),
    );
  }
}

// Detailed movie model
class MovieDetail {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final List<String> genres;
  final int runtime;
  final String releaseDate;

  MovieDetail({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.genres,
    required this.runtime,
    required this.releaseDate,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail(
      id: json['id'],
      title: json['title'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] as num).toDouble(),
      genres: (json['genres'] as List)
          .map((genre) => genre['name'] as String)
          .toList(),
      runtime: json['runtime'] ?? 0,
      releaseDate: json['release_date'] ?? '',
    );
  }
}

// Example Usage in a Widget
class MovieTrackerApp extends StatefulWidget {
  const MovieTrackerApp({super.key});

  @override
  _MovieTrackerAppState createState() => _MovieTrackerAppState();
}

class _MovieTrackerAppState extends State<MovieTrackerApp> {
  final TMDBService tmdbService = TMDBService();
  List<Movie> _popularMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPopularMovies();
  }

  Future<void> _fetchPopularMovies() async {
    try {
      final movies = await tmdbService.fetchPopularMovies();
      setState(() {
        _popularMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load movies')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Tracker')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _popularMovies.length,
              itemBuilder: (context, index) {
                final movie = _popularMovies[index];
                return ListTile(
                  title: Text(movie.title),
                  subtitle: Text('Rating: ${movie.voteAverage}'),
                  leading: movie.posterPath.isNotEmpty
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                        )
                      : null,
                );
              },
            ),
    );
  }
}