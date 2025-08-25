import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bingerr/moviedetail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tierlist_page.dart';

const String apiKey = 'd54c8ae5d997772ae7a6879e252e6785';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _movies = [];
  List<Movie> _filteredMovies = [];
  bool _isLoading = false;
  bool _isMovie = true; // Toggle between movie and TV show

  final List<Map<String, String>> categories = [
    {'title': 'Horror', 'image': 'assets/horror.jpg'},
    {'title': 'Action', 'image': 'assets/action.webp'},
    {'title': 'Drama', 'image': 'assets/drama.webp'},
    {'title': 'Comedy', 'image': 'assets/comedy.jpg'},
    {'title': 'Romance', 'image': 'assets/romance.jpg'},
    {'title': 'Documentary', 'image': 'assets/documentary.jpg'},
    {'title': 'Animation', 'image': 'assets/animation.png'},
    {'title': 'Mystery', 'image': 'assets/mystery.jpg'},
    {'title': 'Fantasy', 'image': 'assets/fantasy.jpg'},
    {'title': 'History', 'image': 'assets/history.jpg'},
    {'title': 'Thriller', 'image': 'assets/thriller.jpg'},
    {'title': 'Sci-Fi', 'image': 'assets/scifi.webp'},
  ];
  
  final Map<String, int> genreMap = {
    'Action': 28,
    'Comedy': 35,
    'Drama': 18,
    'Horror': 27,
    'Romance': 10749,
    'Documentary': 99,
    'Animation': 16,
    'Mystery': 9648,
    'Fantasy': 14,
    'History': 36,
    'Thriller': 53,
    'Sci-Fi': 878,
  };

  // TV show genre mapping 
  final Map<String, int> tvGenreMap = {
    'Action': 10759,
    'Comedy': 35,
    'Drama': 18,
    'Horror': 27,
    'Romance': 10749,
    'Documentary': 99,
    'Animation': 16,
    'Mystery': 9648,
    'Fantasy': 10765, // Sci-Fi & Fantasy
    'History': 36,
    'Thriller': 53,
    'Sci-Fi': 10765, // Sci-Fi & Fantasy
  };

  final Set<int> _selectedGenreIds = {};

  @override
  void initState() {
    super.initState();
    _fetchPopularMovies(); 
  }

  Future<void> _fetchPopularMovies() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/movie/popular?api_key=$apiKey'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _movies = (data['results'] as List).map((json) => Movie.fromJson(json, 'movie')).toList();
          _filteredMovies = List.from(_movies);
          _isLoading = false;
        });
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  Future<void> _fetchPopularTVShows() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/popular?api_key=$apiKey'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _movies = (data['results'] as List).map((json) => Movie.fromJson(json, 'tv')).toList();
          _filteredMovies = List.from(_movies);
          _isLoading = false;
        });
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  Future<void> _searchMovies(String query) async {
    setState(() => _isLoading = true);

    try {
      http.Response response;

      if (_isMovie) {
        if (query.isNotEmpty && _selectedGenreIds.isEmpty) {
          response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query'));
        } else if (query.isEmpty && _selectedGenreIds.isNotEmpty) {
          response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=${_selectedGenreIds.join(",")}'));
        } else if (query.isNotEmpty && _selectedGenreIds.isNotEmpty) {
          response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=${_selectedGenreIds.join(",")}&query=$query'));
        } else {
          // Default to popular movies if no query or genres
          response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/movie/popular?api_key=$apiKey'));
        }
      } else {
        // TV Show searches
        if (query.isNotEmpty && _selectedGenreIds.isEmpty) {
          response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/search/tv?api_key=$apiKey&query=$query'));
        } else if (query.isEmpty && _selectedGenreIds.isNotEmpty) {
          response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/discover/tv?api_key=$apiKey&with_genres=${_selectedGenreIds.join(",")}'));
        } else if (query.isNotEmpty && _selectedGenreIds.isNotEmpty) {
          response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/discover/tv?api_key=$apiKey&with_genres=${_selectedGenreIds.join(",")}&query=$query'));
        } else {
          // Default to popular TV shows if no query or genres
          response = await http.get(Uri.parse(
            'https://api.themoviedb.org/3/tv/popular?api_key=$apiKey'));
        }
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _filteredMovies = (data['results'] as List)
              .map((json) => Movie.fromJson(json, _isMovie ? 'movie' : 'tv'))
              .toList();
          _isLoading = false;
        });
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  void _handleError() {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load data')),
    );
  }

  void _toggleMediaType(bool isMovie) {
    setState(() {
      _isMovie = isMovie;
      _selectedGenreIds.clear(); 
      _searchController.clear(); 
      if (_isMovie) {
        _fetchPopularMovies();
      } else {
        _fetchPopularTVShows();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 1:
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/list');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/profile');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.amber,
        title: const Text('Search', style: TextStyle(fontSize: 32, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildMediaToggle(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildCategoryList(),
            const SizedBox(height: 16),
            Expanded(child: _buildMovieGrid()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My List'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMediaToggle() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: GestureDetector(
          onTap: () => _toggleMediaType(true),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _isMovie ? Colors.amber : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Movies',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isMovie 
                    ? Colors.black 
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => _toggleMediaType(false),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: !_isMovie ? Colors.amber : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'TV Shows',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: !_isMovie 
                    ? Colors.black 
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildSearchBar() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return TextField(
    controller: _searchController,
    onChanged: _searchMovies,
    decoration: InputDecoration(
      hintText: _isMovie ? 'Search for a movie...' : 'Search for a TV show...',
      hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black54),
      prefixIcon: Icon(Icons.search, 
                      color: isDarkMode ? Colors.grey[400] : Colors.black54),
      filled: true,
      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
  );
}

Widget _buildCategoryList() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return SizedBox(
    height: 120,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: categories.map((category) {
        final genreId = _isMovie
            ? genreMap[category['title']]
            : tvGenreMap[category['title']];

        return GestureDetector(
          onTap: () {
            if (genreId != null) {
              setState(() {
                if (_selectedGenreIds.contains(genreId)) {
                  _selectedGenreIds.remove(genreId);
                } else {
                  _selectedGenreIds.add(genreId);
                }
              });
              _searchMovies(_searchController.text);
            }
          },
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedGenreIds.contains(
                        _isMovie
                            ? genreMap[category['title']] ?? -1
                            : tvGenreMap[category['title']] ?? -1)
                    ? Colors.amber
                    : Colors.transparent,
                width: 3,
              ),
              image: DecorationImage(
                image: AssetImage(category['image']!),
                fit: BoxFit.cover,
                colorFilter: isDarkMode 
                    ? ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken)
                    : null,
              ),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                // Darker overlay for better contrast in dark mode
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.8) 
                    : Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Text(
                category['title']!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

  Widget _buildMovieGrid() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.amber));

  return _filteredMovies.isEmpty
      ? Center(
          child: Text(
            _isMovie ? "No movies found" : "No TV shows found",
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
          )
        )
      : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            mainAxisSpacing: 16, 
            crossAxisSpacing: 16, 
          ),
          padding: const EdgeInsets.all(16),
          itemCount: _filteredMovies.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailPage(
                      movieId: _filteredMovies[index].id,
                      mediaType: _filteredMovies[index].mediaType,
                    ),
                  ),
                );
              },
              child: _buildMovieCard(_filteredMovies[index]),
            );
          },
        );
}

Widget _buildMovieCard(Movie movie) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    width: 140,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                width: 140,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 140,
                  height: 180,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                  child: Icon(Icons.broken_image, size: 40, 
                    color: isDarkMode ? Colors.white70 : Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => _showAddToListBottomSheet(ctx, movie), 
                  child: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 14,
                    child: Icon(Icons.add, color: Colors.black, size: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => _showRatingDialog(ctx, movie), 
                  child: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    radius: 14,
                    child: Icon(Icons.star, color: Colors.black, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  movie.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 12, 
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Smaller font size
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  //method to allow users to rate movies
  void _showRatingDialog(BuildContext context, Movie movie) async {
    double currentRating = 5.0; // Default rating
    final prefs = await SharedPreferences.getInstance();
    
    // Check if this movie has been rated before
    final String? ratingsData = prefs.getString('movie_ratings');
    Map<String, dynamic> ratings = {};
    
    if (ratingsData != null) {
      ratings = json.decode(ratingsData);
      if (ratings.containsKey(movie.id.toString())) {
        currentRating = ratings[movie.id.toString()]['rating'];
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rate "${movie.title}"'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 28),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: currentRating,
                    min: 0.5,
                    max: 10.0,
                    divisions: 100,
                    activeColor: Colors.amber,
                    label: currentRating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        currentRating = value;
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
                  onPressed: () async {
                    await _saveMovieRating(movie, currentRating);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Rating saved for ${movie.title}')),
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

  // Method to save the movie rating
  Future<void> _saveMovieRating(Movie movie, double rating) async {
    final prefs = await SharedPreferences.getInstance();
    final String? ratingsData = prefs.getString('movie_ratings');
    Map<String, dynamic> ratings = {};
    
    if (ratingsData != null) {
      ratings = json.decode(ratingsData);
    }
    
    // Add or update the rating
    ratings[movie.id.toString()] = {
      'id': movie.id,
      'title': movie.title,
      'poster_path': movie.posterPath,
      'rating': rating,
      'media_type': movie.mediaType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString('movie_ratings', json.encode(ratings));
    
    // update the movie in playlists if it exists in any
    final String? playlistsData = prefs.getString('playlists');
    if (playlistsData != null) {
      Map<String, Map<String, dynamic>> playlists = {};
      final decoded = json.decode(playlistsData);
      decoded.forEach((key, value) {
        playlists[key] = Map<String, dynamic>.from(value);
      });
      
      bool playlistsUpdated = false;
      
      for (var playlistName in playlists.keys) {
        List<Map<String, dynamic>> movies = List<Map<String, dynamic>>.from(playlists[playlistName]!['movies']);
        for (int i = 0; i < movies.length; i++) {
          if (movies[i]['id'] == movie.id) {
            movies[i]['rating'] = rating;
            playlistsUpdated = true;
          }
        }
        playlists[playlistName]!['movies'] = movies;
      }
      
      if (playlistsUpdated) {
        await prefs.setString('playlists', json.encode(playlists));
      }
    }
    
    // Also update the movie in tierlists if it exists in any
    final String? tierlistsData = prefs.getString('tier_lists');
    if (tierlistsData != null) {
      Map<String, dynamic> tierlists = json.decode(tierlistsData);
      bool tierlistsUpdated = false;
      
      for (var tierlistName in tierlists.keys) {
        for (var tier in ['S', 'A', 'B', 'C', 'D', 'E']) {
          List tierMovies = tierlists[tierlistName][tier] ?? [];
          for (int i = 0; i < tierMovies.length; i++) {
            if (tierMovies[i]['id'] == movie.id) {
              tierMovies[i]['rating'] = rating;
              tierlistsUpdated = true;
            }
          }
        }
      }
      
      if (tierlistsUpdated) {
        await prefs.setString('tier_lists', json.encode(tierlists));
      }
    }
  }

  void _showAddToListBottomSheet(BuildContext ctx, Movie movie) { 
    showModalBottomSheet(
      context: ctx,  
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Save to...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(
                title: const Text("Add to Tierlist"),
                leading: const Icon(Icons.list),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    ctx,  
                    MaterialPageRoute(
                      builder: (context) => TierlistPage(selectedMovie: movie.toJson()),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text("Add to Playlist"),
                leading: const Icon(Icons.playlist_add),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaylistSelectionDialog(ctx, movie);
                },
              ),
              const Divider(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('Done', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistSelectionDialog(BuildContext context, Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsData = prefs.getString('playlists');
    Map<String, Map<String, dynamic>> playlists = {};
    
    if (playlistsData != null) {
      final decoded = json.decode(playlistsData);
      decoded.forEach((key, value) {
        playlists[key] = Map<String, dynamic>.from(value);
      });
    }

    List<String> playlistNames = playlists.keys.toList();
    TextEditingController playlistController = TextEditingController();
    String selectedLabel = 'none';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView( 
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7, 
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Add to Playlist',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        
                        if (playlistNames.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add to Existing Playlist:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 150, 
                                child: ListView.builder(
                                  itemCount: playlistNames.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(playlistNames[index]),
                                      onTap: () async {
                                        await _addMovieToPlaylist(playlistNames[index], movie);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          SnackBar(
                                            content: Text('Added to ${playlistNames[index]}'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const Text(
                          'Create New Playlist:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextField(
                          controller: playlistController,
                          decoration: const InputDecoration(
                            hintText: "Enter Playlist Name",
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text("Select Label:"),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildLabelChip('none', selectedLabel, (label) {
                              setState(() => selectedLabel = label);
                            }),
                            _buildLabelChip('watching', selectedLabel, (label) {
                              setState(() => selectedLabel = label);
                            }),
                            _buildLabelChip('planned', selectedLabel, (label) {
                              setState(() => selectedLabel = label);
                            }),
                            _buildLabelChip('completed', selectedLabel, (label) {
                              setState(() => selectedLabel = label);
                            }),
                            _buildLabelChip('dropped', selectedLabel, (label) {
                              setState(() => selectedLabel = label);
                            }),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            if (playlistController.text.isNotEmpty) {
                              await _createNewPlaylistWithMovie(playlistController.text, selectedLabel, movie);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('Created playlist "${playlistController.text}" and added movie'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                          child: const Text('Create and Add', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildLabelChip(String label, String selectedLabel, Function(String) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedLabel == label,
      onSelected: (selected) {
        if (selected) {
          onSelected(label);
        }
      },
      selectedColor: _getLabelColor(label),
      labelStyle: TextStyle(
        color: selectedLabel == label ? Colors.white : Colors.black,
      ),
    );
  }

  Color _getLabelColor(String label) {
    switch (label) {
      case 'watching': return Colors.blue;
      case 'planned': return Colors.purple;
      case 'completed': return Colors.green;
      case 'dropped': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _addMovieToPlaylist(String playlistName, Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsData = prefs.getString('playlists');
    
    Map<String, Map<String, dynamic>> playlists = {};
    
    if (playlistsData != null) {
      final decoded = json.decode(playlistsData);
      decoded.forEach((key, value) {
        playlists[key] = Map<String, dynamic>.from(value);
      });
    }
    
    if (playlists.containsKey(playlistName)) {
      List<Map<String, dynamic>> movies = List<Map<String, dynamic>>.from(playlists[playlistName]!['movies']);
      
      
      if (!movies.any((m) => m['id'] == movie.id)) {
        movies.add(movie.toJson());
        playlists[playlistName]!['movies'] = movies;
        
        await prefs.setString('playlists', json.encode(playlists));
      }
    }
  }

  Future<void> _createNewPlaylistWithMovie(String playlistName, String label, Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsData = prefs.getString('playlists');
    
    Map<String, Map<String, dynamic>> playlists = {};
    
    if (playlistsData != null) {
      final decoded = json.decode(playlistsData);
      decoded.forEach((key, value) {
        playlists[key] = Map<String, dynamic>.from(value);
      });
    }
    
  
    playlists[playlistName] = {
      'movies': [movie.toJson()],
      'label': label,
    };
    
    await prefs.setString('playlists', json.encode(playlists));
  }
}

class Movie {
  final int id;
  final String title;
  final String posterPath;
  final String overview;
  final double voteAverage;
  final List<int> genreIds;
  final String mediaType; 
  final int? numberOfSeasons;
  final int? numberOfEpisodes;

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.voteAverage,
    required this.genreIds,
    required this.mediaType,
    this.numberOfSeasons,
    this.numberOfEpisodes,
  });

  factory Movie.fromJson(Map<String, dynamic> json, [String mediaType = 'movie']) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'No Title',
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      mediaType: json['media_type'] ?? mediaType,
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'vote_average': voteAverage,
      'genre_ids': genreIds,
      'media_type': mediaType,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
    };
  }
}