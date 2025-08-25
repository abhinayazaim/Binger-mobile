import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'tierlist_page.dart';
import 'see_more_page.dart'; 
import 'moviedetail.dart';

const String apiKey = 'd54c8ae5d997772ae7a6879e252e6785';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();  
  int _selectedIndex = 0;
  List<Movie> _recommendedMovies = [];
  List<Movie> _bestMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _tvShows = [];
  List<Movie> _recommendedTVShows = [];
  List<Movie> _bestTVShows = [];
  bool _isLoading = true;
  bool _isDarkMode = true; 
  

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadDarkModePreference();
  }

  // method to load dark mode preference
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? true; 
    });
  }

  

  Future<void> _fetchData() async {
    try {
      final recommendedResponse = await http.get(
        Uri.parse('https://api.themoviedb.org/3/discover/movie?api_key=$apiKey'),
      );
      final bestMoviesResponse = await http.get(
        Uri.parse('https://api.themoviedb.org/3/movie/top_rated?api_key=$apiKey'),
      );
      final trendingResponse = await http.get(
        Uri.parse('https://api.themoviedb.org/3/trending/movie/week?api_key=$apiKey'),
      );
      final tvShowResponse = await http.get(
        Uri.parse('https://api.themoviedb.org/3/trending/tv/week?api_key=$apiKey'),
      );
      final recommendedTVResponse = await http.get(
        Uri.parse('https://api.themoviedb.org/3/discover/tv?api_key=$apiKey'),
      );
      final bestTVResponse = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/top_rated?api_key=$apiKey'),
      );
      

      if (recommendedResponse.statusCode == 200 &&
          bestMoviesResponse.statusCode == 200 &&
          trendingResponse.statusCode == 200 &&
          tvShowResponse.statusCode == 200 &&
          recommendedTVResponse.statusCode == 200 &&
          bestTVResponse.statusCode == 200) {
        setState(() {
          _recommendedMovies = _parseMovies(recommendedResponse.body);
          _bestMovies = _parseMovies(bestMoviesResponse.body);
          _trendingMovies = _parseMovies(trendingResponse.body);
          _tvShows = _parseMovies(tvShowResponse.body, mediaType: 'tv');
          _recommendedTVShows = _parseMovies(recommendedTVResponse.body, mediaType: 'tv');
          _bestTVShows = _parseMovies(bestTVResponse.body, mediaType: 'tv');
          _isLoading = false;
        });
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  List<Movie> _parseMovies(String responseBody, {String mediaType = 'movie'}) {
    final Map<String, dynamic> parsed = json.decode(responseBody);
    return (parsed['results'] as List)
        .map<Movie>((json) => Movie.fromJson(json, mediaType: mediaType))
        .toList();
  }

  void _handleError() {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load movies')),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/list');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode ? Colors.black : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = _isDarkMode ? Colors.white70 : Colors.black87;
    final cardColor = _isDarkMode ? Colors.grey[900] : Colors.grey[200];
    
    return Scaffold(
      key: _scaffoldKey, 
      backgroundColor: backgroundColor,
      endDrawer: Drawer(
        child: Container(
          color: backgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.amber),
                accountName: Text('Cristiano Ronaldo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                accountEmail: Text('ronaldo7@binger.com', style: TextStyle(color: Colors.black)),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: AssetImage('assets/ronaldo.png'),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person, color: textColor),
                title: Text('Profile', style: TextStyle(color: textColor)),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              ListTile(
                leading: Icon(Icons.list, color: textColor),
                title: Text('My List', style: TextStyle(color: textColor)),
                onTap: () => Navigator.pushNamed(context, '/list'),
              ),
              ListTile(
                leading: Icon(Icons.settings, color: textColor),
                title: Text('Settings', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.pushNamed(context, '/settings'); 
                },
              ),
              //dark mode toggle
              Divider(color: secondaryTextColor),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/signin');
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.amber,
        automaticallyImplyLeading: false,
        title: const Text('Binger', style: TextStyle(fontSize: 32, color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState!.openEndDrawer(); 
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              child: Container(
                color: backgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Recommended Movies', _recommendedMovies, textColor),
                    _buildMovieGrid(_recommendedMovies, cardColor, textColor),
                    _buildSection('Best Movies', _bestMovies, textColor),
                    _buildMovieGrid(_bestMovies, cardColor, textColor),
                    _buildSection('Trending Movies', _trendingMovies, textColor),
                    _buildMovieGrid(_trendingMovies, cardColor, textColor),
                    _buildSection('Trending TV Shows', _tvShows, textColor),
                    _buildMovieGrid(_tvShows, cardColor, textColor),
                    _buildSection('Recommended TV Shows', _recommendedTVShows, textColor),
                    _buildMovieGrid(_recommendedTVShows, cardColor, textColor),
                    _buildSection('Best TV Shows', _bestTVShows, textColor),
                    _buildMovieGrid(_bestTVShows, cardColor, textColor),   
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.amber,
        unselectedItemColor: _isDarkMode ? Colors.white54 : Colors.grey,
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
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

  Widget _buildSection(String title, List<Movie> movies, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: textColor
              )
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeeMorePage(title: title, movies: movies),
                ),
              );
            },
            child: const Text('See more', style: TextStyle(fontSize: 14, color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieGrid(List<Movie> movies, Color? cardColor, Color textColor) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailPage(movieId: movies[index].id, mediaType: movies[index].mediaType),
                ),
              );
            },
            child: _buildMovieCard(movies[index], cardColor, textColor),
          );
        },
      ),
    );
  }

  Widget _buildMovieCard(Movie movie, Color? cardColor, Color textColor) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                    width: 140,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 180,
                      color: Colors.grey[700],
                      child: const Icon(Icons.broken_image, size: 40, color: Colors.white),
                    ),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  movie.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8), 
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      movie.voteAverage.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  min: 0.0,
                  max:10.0,
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
                  // Save the rating
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
  
  // Also update the movie in playlists if it exists in any
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
                  _showTierlistSelectionDialog(ctx, movie);
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

  void _showTierlistSelectionDialog(BuildContext context, Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final String? tierlistsData = prefs.getString('tier_lists');
    Map<String, dynamic> tierlists = {};
    
    if (tierlistsData != null) {
      tierlists = json.decode(tierlistsData);
    }

    List<String> tierlistNames = tierlists.keys.toList();
    TextEditingController tierlistController = TextEditingController();

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
                          'Add to Tierlist',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        
                        if (tierlistNames.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add to Existing Tierlist:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 150,
                                child: ListView.builder(
                                  itemCount: tierlistNames.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(tierlistNames[index]),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TierlistPage(
                                              selectedMovie: movie.toJson(),
                                            ),
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
                          'Create New Tierlist:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextField(
                          controller: tierlistController,
                          decoration: const InputDecoration(
                            hintText: "Enter Tierlist Name",
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ElevatedButton(
                          onPressed: () async {
                            if (tierlistController.text.isNotEmpty) {
                              
                              tierlists[tierlistController.text] = {
                                'S': [movie.toJson()],
                                'A': [],
                                'B': [],
                                'C': [],
                                'D': [],
                                'E': [],
                              };
                              
                              await prefs.setString('tier_lists', json.encode(tierlists));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Created tierlist "${tierlistController.text}" and added movie to S tier'),
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
      
      // Check if movie already exists in playlist
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
    
    // Create new playlist with movie
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
  final String mediaType;

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.voteAverage,
    required this.mediaType, 
  });

  factory Movie.fromJson(Map<String, dynamic> json, {String? mediaType}) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'No Title',
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      mediaType: mediaType ?? json['media_type'] ?? (json['title'] != null ? 'movie' : 'tv'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'vote_average': voteAverage,
      'media_type': mediaType, 
    };
  }
}