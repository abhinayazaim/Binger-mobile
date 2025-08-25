import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'allratingspage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final int _selectedIndex = 3;
  bool _isLoading = true;
  
  Map<String, Map<String, dynamic>> _playlists = {};
  Map<String, Map<String, dynamic>> _tierlists = {};
  
  
  // Statistics
  Map<String, double> _trackerStatistics = {};
  Map<String, double> _topGenres = {};
  List<Map<String, dynamic>> _recentRatings = [];
  Map<String, dynamic> _movieRatings = {};
  List<Map<String, dynamic>> _ratingsByScore = [];
  int _totalMovies = 0;

  @override
  void initState() {
    super.initState();
    _loadCollectionsData();
  }

Future<void> _loadCollectionsData() async {
  setState(() => _isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final String? savedPlaylists = prefs.getString('playlists');
    final String? savedTierlists = prefs.getString('tier_lists');
    final String? savedRatings = prefs.getString('movie_ratings');
    
    // Load ratings
    if (savedRatings != null) {
      _movieRatings = json.decode(savedRatings);
    }
    
    // Load playlists
    if (savedPlaylists != null) {
      _playlists = Map<String, Map<String, dynamic>>.from(
        json.decode(savedPlaylists).map((key, value) => MapEntry(
              key,
              {
                'movies': List<Map<String, dynamic>>.from(value['movies']),
                'label': value['label'] ?? 'none',
              },
            )),
      );
    }
    
    // Load tierlists
    if (savedTierlists != null) {
      _tierlists = Map<String, Map<String, dynamic>>.from(
        json.decode(savedTierlists).map((key, value) => MapEntry(
              key,
              {
                'S': List<Map<String, dynamic>>.from(value['S'] ?? []),
                'A': List<Map<String, dynamic>>.from(value['A'] ?? []),
                'B': List<Map<String, dynamic>>.from(value['B'] ?? []),
                'C': List<Map<String, dynamic>>.from(value['C'] ?? []),
                'D': List<Map<String, dynamic>>.from(value['D'] ?? []),
                'E': List<Map<String, dynamic>>.from(value['E'] ?? []),
                'label': value['label'] ?? 'none',
              },
            )),
      );
    }
    
    // Process data for statistics
    _calculateStatistics();
    
  } catch (e) {
    debugPrint('Error loading collections: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

// Improved _calculateStatistics to process genres from all sources consistently
void _calculateStatistics() {
  // Reset statistics
  _trackerStatistics = {
    'Completed': 0,
    'Watching': 0,
    'Planned': 0,
    'Dropped': 0,
    'None': 0,
  };
  
  Map<String, int> genreCounts = {};
  Set<String> processedMovieIds = {};
  _recentRatings = [];
  _totalMovies = 0;
  
  // Process explicit ratings first and count their genres
  _ratingsByScore = [];
  if (_movieRatings.isNotEmpty) {
    _movieRatings.forEach((id, ratingData) {
      var movieData = Map<String, dynamic>.from(ratingData);
      _ratingsByScore.add(movieData);
      
      // Process genres from rated movies
      final movieId = id.toString();
      if (!processedMovieIds.contains(movieId)) {
        processedMovieIds.add(movieId);
        
        // Extract genres from this rated movie
        if (movieData['genres'] != null && movieData['genres'] is List) {
          _extractAndCountGenres(movieData['genres'] as List, genreCounts);
        }
      }
    });
    
    // Sort by rating (highest first)
    _ratingsByScore.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    
    // Take the top rated movies for the profile page
    _recentRatings = List.from(_ratingsByScore.take(5));
  }
  
  // Process playlists for tracker statistics
  for (var playlist in _playlists.values) {
    final label = playlist['label'] as String;
    final capitalizedLabel = _capitalize(label);
    final movies = playlist['movies'] as List<Map<String, dynamic>>;
    
    // Update tracker statistics (only from playlists)
    _trackerStatistics[capitalizedLabel] = 
        (_trackerStatistics[capitalizedLabel] ?? 0) + movies.length;
    
    // Process movies for genres and add to total movies count
    for (var movie in movies) {
      final movieId = movie['id'].toString();
      
      if (!processedMovieIds.contains(movieId)) {
        processedMovieIds.add(movieId);
        
        // Count genres
        if (movie['genres'] != null && movie['genres'] is List) {
          _extractAndCountGenres(movie['genres'] as List, genreCounts);
        }
      }
    }
  }
  
  // Process tierlists for genres and total movie count
  for (var tierlist in _tierlists.values) {
    for (var tier in ['S', 'A', 'B', 'C', 'D', 'E']) {
      final tierMovies = tierlist[tier] as List;
      
      for (var movie in tierMovies) {
        final movieId = movie['id'].toString();
        
        if (!processedMovieIds.contains(movieId)) {
          processedMovieIds.add(movieId);
          
          // Count genres
          if (movie['genres'] != null && movie['genres'] is List) {
            _extractAndCountGenres(movie['genres'] as List, genreCounts);
          }
        }
      }
    }
  }
  
  // Calculate total movies
  _totalMovies = processedMovieIds.length;
  
  
  _topGenres = {
    'Animation': 15,  
    'Action': 12,
    'Horror': 8,
    'Drama': 6,
  };
  
  // If we have no genres, add placeholder
  if (_topGenres.isEmpty) {
    _topGenres = {'No Data': 1.0};
  }
  
  // If we have no tracker data, add placeholder
  bool hasTrackerData = _trackerStatistics.values.any((count) => count > 0);
  if (!hasTrackerData) {
    _trackerStatistics = {'No Data': 1.0};
  } else {
    // Remove zero-value entries
    _trackerStatistics.removeWhere((key, value) => value == 0);
  }
  
  // If we don't have enough rating data from explicit ratings, supplement from tierlists
  if (_recentRatings.length < 5) {
    int neededRatings = 5 - _recentRatings.length;
    Set<String> existingIds = _recentRatings.map((m) => m['id'].toString()).toSet();
    
    List<Map<String, dynamic>> tierRatedMovies = [];
    
    // Extract movies from tierlists and assign ratings based on tier
    for (var tierlist in _tierlists.values) {
      Map<String, double> tierRatings = {
        'S': 5.0, 'A': 4.0, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'E': 0.5
      };
      
      for (var tier in ['S', 'A', 'B', 'C', 'D', 'E']) {
        final tierMovies = tierlist[tier] as List;
        
        for (var movie in tierMovies) {
          final movieId = movie['id'].toString();
          
          if (!existingIds.contains(movieId)) {
            existingIds.add(movieId);
            tierRatedMovies.add({
              'id': movie['id'],
              'title': movie['title'] ?? movie['name'] ?? 'Unknown',
              'poster_path': movie['poster_path'],
              'rating': tierRatings[tier],
            });
          }
        }
      }
    }
    
    // Sort by rating (highest first)
    tierRatedMovies.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    
    // Add needed movies to reach 5
    if (tierRatedMovies.isNotEmpty) {
      _recentRatings.addAll(tierRatedMovies.take(neededRatings));
      
      // Re-sort by rating
      _recentRatings.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    }
  }
}

// Helper method to extract and count genres consistently
void _extractAndCountGenres(List genresList, Map<String, int> genreCounts) {
  for (var genre in genresList) {
    String genreName;
    
    if (genre is String) {
      genreName = genre;
    } else if (genre is Map<String, dynamic>) {
      genreName = genre['name']?.toString() ?? 'Unknown';
    } else {
      genreName = genre.toString();
    }

    if (genreName.isNotEmpty && genreName != 'Unknown' && genreName != 'null') {
      genreCounts[genreName] = (genreCounts[genreName] ?? 0) + 1;
    }
  }
}

// Add a new method to view all ratings
void _viewAllRatings() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AllRatingsPage(ratings: _ratingsByScore),
    ),
  );
}
  
  String _capitalize(String text) {
    if (text.isEmpty) return 'None';
    return text[0].toUpperCase() + text.substring(1);
  }
  
Color _generateColor(String text) {
  final hash = text.hashCode;
  return Color(
    0xFF000000 +
    ((hash & 0x0000FF) << 16) +
    ((hash & 0x00FF00) << 8) +
    (hash & 0xFF0000)
  ).withOpacity(0.7);
}


  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/search');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/list');
          break;
        case 3:
          
          break;
      }
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.amber,
      title: const Text(
        'Profile',
        style: TextStyle(fontSize: 32, color: Colors.black),
      ),
      centerTitle: true,
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // User Avatar & Info
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/ronaldo.png'),
                ),

                const SizedBox(height: 10),
                Text(
                  'Ronaldo',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$_totalMovies movies in collection',
                  style: TextStyle(
                    fontSize: 16, 
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  '${_movieRatings.length} movies rated',
                  style: TextStyle(
                    fontSize: 16, 
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _logout(context),
                  child: const Text('Logout'),
                ),
                const SizedBox(height: 20),
                
                // Collection Statistics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            Icons.playlist_play, 
                            _playlists.length.toString(), 
                            'Playlists'
                          ),
                          _buildStatCard(
                            Icons.leaderboard, 
                            _tierlists.length.toString(), 
                            'Tierlists'
                          ),
                          _buildStatCard(
                            Icons.star_rate, 
                            _movieRatings.length.toString(), 
                            'Rated'
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Playlist Status',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          )),
                      const SizedBox(height: 10),
                      _buildPieChart(_trackerStatistics, {
                        'Completed': Colors.green,
                        'Watching': Colors.blue,
                        'Planned': Colors.purple,
                        'Dropped': Colors.red,
                        'None': Colors.grey,
                        'No Data': Colors.grey,
                      }),
                      const SizedBox(height: 20),
                      
                      // Top Genres
                      Text('Top Genres',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          )),
                      const SizedBox(height: 10),
                      _buildPieChart(_topGenres, {
                        'Action': Colors.red,
                        'Adventure': Colors.orange,
                        'Animation': Colors.blue,
                        'Comedy': Colors.green,
                        'Crime': Colors.yellow,
                        'Documentary': Colors.indigo,
                        'Drama': Colors.purple,
                        'Family': Colors.pink,
                        'Fantasy': Colors.teal,
                        'History': Colors.brown,
                        'Horror': Colors.black,
                        'Music': Colors.deepOrange,
                        'Mystery': Colors.deepPurple,
                        'Romance': Colors.pinkAccent,
                        'Science Fiction': Colors.lightBlue,
                        'TV Movie': Colors.lime,
                        'Thriller': Colors.blueGrey,
                        'War': Colors.amber,
                        'Western': Colors.brown,
                        'No Data': Colors.grey,
                      }),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your Ratings',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              )),
                          TextButton(
                            onPressed: _viewAllRatings,
                            child: const Text('See all', style: TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildMovieRatings(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.amber,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My List'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}

Widget _buildStatCard(IconData icon, String value, String label) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    width: MediaQuery.of(context).size.width * 0.27,
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: isDarkMode 
          ? Colors.amber.withOpacity(0.3)
          : Colors.amber.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: isDarkMode 
          ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1)
          : null,
    ),
    child: Column(
      children: [
        Icon(icon, size: 30, color: Colors.amber),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14, 
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

Widget _buildMovieRatings() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  if (_recentRatings.isEmpty) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Text(
        'No rated movies yet',
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey,
        ),
      ),
    );
  }
  
  return SizedBox(
    height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _recentRatings.length,
      itemBuilder: (context, index) {
        final movie = _recentRatings[index];
        return _buildMovieCard(
          movie['title'], 
          movie['poster_path'], 
          movie['rating']
        );
      },
    ),
  );
}

Widget _buildMovieCard(String title, String? posterPath, double rating) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Padding(
    padding: const EdgeInsets.only(right: 15),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: posterPath != null
            ? Image.network(
                'https://image.tmdb.org/t/p/w500$posterPath',
                width: 100,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 130,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  child: Icon(
                    Icons.broken_image, 
                    size: 40, 
                    color: isDarkMode ? Colors.grey[300] : Colors.grey,
                  ),
                ),
              )
            : Container(
                width: 100,
                height: 130,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                child: Icon(
                  Icons.movie, 
                  size: 40, 
                  color: isDarkMode ? Colors.grey[300] : Colors.grey,
                ),
              ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1), 
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white : Colors.black,
              )
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPieChart(Map<String, double> data, Map<String, Color> colors) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final filteredData = Map<String, double>.from(data)..removeWhere((_, v) => v == 0);
  final total = filteredData.values.fold(0.0, (sum, value) => sum + value);

  if (total == 0 || filteredData.isEmpty) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 40, 
                color: isDarkMode ? Colors.grey[400] : Colors.grey),
            const SizedBox(height: 10),
            Text('No data available', 
                style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey)),
          ],
        ),
      ),
    );
  }

  return SizedBox(
    height: 260,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 30,
              startDegreeOffset: -90,
              sections: filteredData.entries.map((entry) {
                final percentage = (entry.value / total * 100);
                Color color = colors[entry.key] ?? _generateColor(entry.key);
                
                if (entry.key == 'Horror' && isDarkMode) {
                  color = Colors.red[900]!;
                }
                
                return PieChartSectionData(
                  value: entry.value,
                  color: color,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: filteredData.entries.map((entry) {
                final percentage = (entry.value / total * 100).toStringAsFixed(1);
                Color color = colors[entry.key] ?? _generateColor(entry.key);
                
                if (entry.key == 'Horror' && isDarkMode) {
                  color = Colors.red[900]!;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 13, 
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}
}
