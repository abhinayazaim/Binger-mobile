import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'episode_detail.dart';

const String apiKey = 'd54c8ae5d997772ae7a6879e252e6785';

class MovieDetailPage extends StatefulWidget {
  final int movieId;
  final String mediaType; 
  
  

  const MovieDetailPage({super.key, required this.movieId, required this.mediaType});
  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  MovieDetail? _movieDetail;
  List<Season>? _seasons;
  List<Episode>? _episodes;
  bool _isLoading = true;
  double _userRating = 0;
  bool _hasUserRating = false;
  int _selectedSeasonIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchMovieDetails();
    _loadUserRating(); // Add this call to load ratings
  }

  Future<void> _fetchMovieDetails() async {
    setState(() => _isLoading = true);
    
    final detailsUrl =
      'https://api.themoviedb.org/3/${widget.mediaType}/${widget.movieId}?api_key=$apiKey&append_to_response=credits';

    try {
      final response = await http.get(Uri.parse(detailsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _movieDetail = MovieDetail.fromJson(data, widget.mediaType);
          _isLoading = false;
        });
        
        if (widget.mediaType == 'tv') {
          await _fetchSeasons();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSeasons() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/${widget.movieId}?api_key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> seasonData = data['seasons'] ?? [];
        
        setState(() {
          _seasons = seasonData
              .map((season) => Season.fromJson(season))
              .where((season) => season.seasonNumber > 0) 
              .toList();
        });
        
        if (_seasons != null && _seasons!.isNotEmpty) {
          await _fetchEpisodes(_seasons![0].seasonNumber);
        }
      }
    } catch (e) {
      print('Error fetching seasons: $e');
    }
  }

  Future<void> _fetchEpisodes(int seasonNumber) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/${widget.movieId}/season/$seasonNumber?api_key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> episodeData = data['episodes'] ?? [];
        
        setState(() {
          _episodes = episodeData.map((episode) => Episode.fromJson(episode)).toList();
        });
      }
    } catch (e) {
      print('Error fetching episodes: $e');
    }
  }

  void _selectSeason(int index) {
    if (_seasons != null && index < _seasons!.length) {
      setState(() {
        _selectedSeasonIndex = index;
        _episodes = null; 
      });
      _fetchEpisodes(_seasons![index].seasonNumber);
    }
  }

Future<void> _loadUserRating() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ratingsData = prefs.getString('movie_ratings');
    
    if (ratingsData != null) {
      final ratings = json.decode(ratingsData);
      if (ratings.containsKey(widget.movieId.toString())) {
        setState(() {
          _userRating = ratings[widget.movieId.toString()]['rating'];
          _hasUserRating = true;
        });
      }
    }
  }

   Future<void> _saveRating(double rating) async {
    final prefs = await SharedPreferences.getInstance();
    final String? ratingsData = prefs.getString('movie_ratings');
    
    Map<String, dynamic> ratings = {};
    if (ratingsData != null) {
      ratings = json.decode(ratingsData);
    }
    
    ratings[widget.movieId.toString()] = {
      'id': widget.movieId,
      'title': _movieDetail?.title ?? 'Unknown',
      'rating': rating,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'poster_path': _movieDetail?.posterPath,
      'media_type': widget.mediaType,
    };
    
    await prefs.setString('movie_ratings', json.encode(ratings));
    
    setState(() {
      _userRating = rating;
      _hasUserRating = true;
    });
  }

  void _showRatingDialog() {
  double tempRating = _userRating;
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Rate ${_movieDetail?.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tempRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                  ],
                ),
                const SizedBox(height: 20),
                Slider(
                  value: tempRating,
                  min: 0.0,
                  max: 10.0,
                  divisions: 100,
                  activeColor: Colors.amber,
                  label: tempRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      tempRating = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Save', style: TextStyle(color: Colors.amber)),
                onPressed: () {
                  _saveRating(tempRating);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rating saved for ${_movieDetail?.title}')),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading ? const Text("Loading...") : Text(_movieDetail!.title),
        backgroundColor: Colors.amber,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movieDetail == null
              ? const Center(child: Text("Error loading details"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w500${_movieDetail!.posterPath}',
                            width: 300,
                            height: 450,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 300,
                                height: 450,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, size: 50),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        _movieDetail!.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _movieDetail!.releaseDate,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            _movieDetail!.rating.toString(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Add these lines right here:
                      _buildUserRatingSection(),  // This will display the user rating widget
                      const SizedBox(height: 16),
                      // Then the original code continues:
                      const Text(
                        "Synopsis:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_movieDetail!.overview, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      
                      // Show creator for TV shows, director for movies
                      Text(
                        widget.mediaType == 'tv' ? "Creator:" : "Director:",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(_movieDetail!.director, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      
                      const Text(
                        "Actors:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(_movieDetail!.actors.join(', '), style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      
                      const Text(
                        "Genres:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(_movieDetail!.genres.join(', '), style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      
                      // Show different info based on media type
                      if (widget.mediaType == 'movie')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Runtime:",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text("${_movieDetail!.runtime} minutes", style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      
                      // Show seasons and episodes for TV shows
                      if (widget.mediaType == 'tv' && _seasons != null && _seasons!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              "Seasons:",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildSeasonSelector(),
                            const SizedBox(height: 16),
                            const Text(
                              "Episodes:",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildEpisodesList(),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserRatingSection() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Rating',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _hasUserRating
            ? Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    _userRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showRatingDialog(),
                    child: const Text('Change'),
                  )
                ],
              )
            : Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star),
                  label: const Text('Rate This'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () => _showRatingDialog(),
                ),
              ),
      ],
    ),
  );
}

  Widget _buildSeasonSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _seasons?.length ?? 0,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _selectSeason(index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedSeasonIndex == index ? Colors.amber : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  "Season ${_seasons![index].seasonNumber}",
                  style: TextStyle(
                    color: _selectedSeasonIndex == index ? Colors.black : Colors.black87,
                    fontWeight: _selectedSeasonIndex == index ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

Widget _buildEpisodesList() {
  if (_episodes == null) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_episodes!.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("No episodes available for this season."),
    );
  }

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _episodes!.length,
    itemBuilder: (context, index) {
      final episode = _episodes![index];
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: episode.stillPath.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w300${episode.stillPath}',
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                )
              : Container(
                  width: 80,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.tv)),
                ),
          title: Text(
            "E${episode.episodeNumber}. ${episode.name}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                episode.airDate.isNotEmpty ? "Air date: ${episode.airDate}" : "No air date",
                style: const TextStyle(fontSize: 12),
              ),
              if (episode.overview.isNotEmpty)
                Text(
                  episode.overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              Text(
                episode.voteAverage.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EpisodeDetailPage(
                  tvShowId: widget.movieId, 
                  seasonNumber: _seasons![_selectedSeasonIndex].seasonNumber, 
                  episodeNumber: episode.episodeNumber,
                  tvShowName: _movieDetail?.title ?? 'TV Show',
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
}


class MovieDetail {
  final String title, overview, posterPath, director, releaseDate;
  final double rating;
  final List<String> actors, genres;
  final int runtime;

  MovieDetail({
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.rating,
    required this.director,
    required this.actors,
    required this.genres,
    required this.releaseDate,
    required this.runtime,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json, String mediaType) {
    List<dynamic> crewList = json['credits']?['crew'] ?? [];
    List<dynamic> castList = json['credits']?['cast'] ?? [];
    List<dynamic> genreList = json['genres'] ?? [];

    String director = "Unknown";
    if (mediaType == 'movie') {
      if (crewList.isNotEmpty) {
        var directorData = crewList.cast<Map<String, dynamic>>().firstWhere(
          (crew) => crew['job'] == 'Director',
          orElse: () => {'name': 'Unknown'},
        );
        director = directorData['name'] ?? "Unknown";
      }
    } else {
      // For TV shows, look for the creator
      director = (json['created_by'] != null && json['created_by'].isNotEmpty) 
          ? json['created_by'][0]['name'] 
          : "Unknown";
    }

    List<String> actors = castList.cast<Map<String, dynamic>>()
      .take(5)
      .map((cast) => cast['name'] as String)
      .toList();

    List<String> genres = genreList.map((g) => g['name'] as String).toList();

    return MovieDetail(
      title: mediaType == 'movie' ? json['title'] ?? 'No Title' : json['name'] ?? 'No Title',
      overview: json['overview'] ?? 'No Synopsis Available',
      posterPath: json['poster_path'] ?? '',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      director: director,
      actors: actors,
      genres: genres,
      releaseDate: mediaType == 'movie' ? json['release_date'] ?? 'Unknown' : json['first_air_date'] ?? 'Unknown',
      runtime: mediaType == 'movie'
          ? json['runtime'] ?? 0
          : (json['episode_run_time'] != null && json['episode_run_time'].isNotEmpty
              ? json['episode_run_time'][0]
              : 0),
    );
  }
}

class Season {
  final int id;
  final int seasonNumber;
  final String name;
  final String overview;
  final String posterPath;
  final int episodeCount;
  final String airDate;

  Season({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.episodeCount,
    required this.airDate,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      name: json['name'] ?? 'Season',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      episodeCount: json['episode_count'] ?? 0,
      airDate: json['air_date'] ?? '',
    );
  }
}

class Episode {
  final int id;
  final int episodeNumber;
  final String name;
  final String overview;
  final String stillPath;
  final double voteAverage;
  final String airDate;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.name,
    required this.overview,
    required this.stillPath,
    required this.voteAverage,
    required this.airDate,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      episodeNumber: json['episode_number'] ?? 0,
      name: json['name'] ?? 'Episode',
      overview: json['overview'] ?? '',
      stillPath: json['still_path'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      airDate: json['air_date'] ?? '',
    );
  }
}