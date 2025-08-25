import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'playlist_page.dart' as playlist_page;
import 'tierlist_page.dart' as tierlist_page;
import 'moviedetail.dart' as movie_detail;
import 'episode_detail.dart' as episode_detail;

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  int _selectedIndex = 2;
  Map<String, Map<String, dynamic>> _playlists = {};
  Map<String, Map<String, dynamic>> _tierlists = {};
  bool _isLoading = true;
  bool _isGridView = false;
  
  // New property to track which tab is selected
  int _activeTab = 0; // 0 for playlists, 1 for tierlists

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

Future<void> _loadCollections() async {
  setState(() => _isLoading = true);

  final prefs = await SharedPreferences.getInstance();
  final String? savedPlaylists = prefs.getString('playlists');
  final String? savedTierlists = prefs.getString('tier_lists');

  setState(() {
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
                'E': List<Map<String, dynamic>>.from(value['E'] ?? []), // Added E tier
                'label': value['label'] ?? 'none',
              },
            )),
      );
    }
    
    _isLoading = false;
  });
}

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildBottomSheetItem(Icons.playlist_add, 'New Playlist', 'Create a new playlist'),
            const SizedBox(height: 10),
            _buildBottomSheetItem(Icons.list, 'New Tierlist', 'Create a new tierlist'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (title == 'New Playlist') {
          _showCreatePlaylistDialog();
        } else if (title == 'New Tierlist') {
          _showCreateTierlistDialog();
        }
      },
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController controller = TextEditingController();
    String selectedLabel = 'none';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Create New Playlist"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Playlist Name",
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
                        _buildLabelChip('none', selectedLabel, setState),
                        _buildLabelChip('watching', selectedLabel, setState),
                        _buildLabelChip('planned', selectedLabel, setState),
                        _buildLabelChip('completed', selectedLabel, setState),
                        _buildLabelChip('dropped', selectedLabel, setState),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    if (controller.text.isNotEmpty) {
                      await _createNewPlaylist(controller.text, selectedLabel);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateTierlistDialog() {
    final TextEditingController controller = TextEditingController();
    String selectedLabel = 'none';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Create New Tierlist"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Tierlist Name",
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
                        _buildLabelChip('none', selectedLabel, setState),
                        _buildLabelChip('watching', selectedLabel, setState),
                        _buildLabelChip('planned', selectedLabel, setState),
                        _buildLabelChip('completed', selectedLabel, setState),
                        _buildLabelChip('dropped', selectedLabel, setState),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    if (controller.text.isNotEmpty) {
                      await _createNewTierlist(controller.text, selectedLabel);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLabelChip(String label, String selectedLabel, Function setState) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedLabel == label,
      onSelected: (selected) {
        setState(() => selectedLabel = label);
      },
      selectedColor: _getLabelColor(label),
      labelStyle: TextStyle(
        color: selectedLabel == label ? Colors.white : Colors.black,
      ),
    );
  }

  Future<void> _createNewPlaylist(String name, String label) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _playlists[name] = {
        'movies': [],
        'label': label,
      };
    });

    await prefs.setString('playlists', json.encode(_playlists));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playlist "$name" created')),
    );
  }

  Future<void> _createNewTierlist(String name, String label) async {
  final prefs = await SharedPreferences.getInstance();
  
  setState(() {
    _tierlists[name] = {
      'S': [],
      'A': [],
      'B': [],
      'C': [],
      'D': [],
      'E': [], 
      'label': label,
    };
  });

  await prefs.setString('tier_lists', json.encode(_tierlists)); 
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Tierlist "$name" created')),
  );
}

List<Map<String, dynamic>> _combineTierMovies(Map<String, dynamic> tierlistData) {
  List<Map<String, dynamic>> allMovies = [];
  // Add movies from each tier
  for (var tier in ['S', 'A', 'B', 'C', 'D', 'E']) {
    if (tierlistData[tier] != null) {
      allMovies.addAll(List<Map<String, dynamic>>.from(tierlistData[tier]));
    }
  }
  return allMovies;
}

  void _toggleViewMode() => setState(() => _isGridView = !_isGridView);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      automaticallyImplyLeading: false,
        title: const Text(
          'Your List',
          style: TextStyle(color: Colors.black, fontSize: 32),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _showAddOptions,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Column(
              children: [
                _buildSegmentedControl(),
                _buildHeader(),
                Expanded(
                  child: _activeTab == 0
                      ? (_playlists.isEmpty
                          ? _buildEmptyState('playlist')
                          : _isGridView 
                              ? _buildGridView(_playlists, false) 
                              : _buildListView(_playlists, false))
                      : (_tierlists.isEmpty
                          ? _buildEmptyState('tierlist')
                          : _isGridView 
                              ? _buildGridView(_tierlists, true) 
                              : _buildListView(_tierlists, true)),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            switch (index) {
              case 0: Navigator.pushReplacementNamed(context, '/home'); break;
              case 1: Navigator.pushReplacementNamed(context, '/search'); break;
              case 2: break;
              case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
            }
          });
        },
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

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? Colors.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Playlists',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _activeTab == 0 ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? Colors.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tierlists',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _activeTab == 1 ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _activeTab == 0 ? 'My Playlists' : 'My Tierlists', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view, 
              color: Colors.black
            ),
            onPressed: _toggleViewMode,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'playlist' ? Icons.playlist_play : Icons.leaderboard,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No ${type}s available",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a new $type to get started",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: type == 'playlist' ? _showCreatePlaylistDialog : _showCreateTierlistDialog,
            icon: const Icon(Icons.add, color: Colors.black),
            label: Text("Create $type", style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(Map<String, Map<String, dynamic>> collections, bool isTierlist) {
    return ListView.builder(
      itemCount: collections.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final entry = collections.entries.elementAt(index);
        return _buildCollectionCard(entry.key, entry.value, isTierlist);
      },
    );
  }

  Widget _buildGridView(Map<String, Map<String, dynamic>> collections, bool isTierlist) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final entry = collections.entries.elementAt(index);
        return _buildCollectionCard(entry.key, entry.value, isTierlist);
      },
    );
  }

Widget _buildCollectionCard(String name, Map<String, dynamic> data, bool isTierlist) {
  // For tierlists, calculate total movies across all tiers
  final itemCount = isTierlist 
      ? (data['S'].length + data['A'].length + data['B'].length + 
         data['C'].length + data['D'].length + data['E'].length)
      : (data['movies'] as List).length;
  
  final label = data['label'] as String;
  
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: _isGridView ? 4 : 2,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _navigateToCollectionDetail(name, data, isTierlist),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _isGridView 
            ? _buildGridContent(name, data, itemCount, label, isTierlist)
            : _buildListContent(name, data, itemCount, label, isTierlist),
      ),
    ),
  );
}

Widget _buildGridContent(String name, Map<String, dynamic> data, int itemCount, String label, bool isTierlist) {
  final movies = isTierlist 
      ? _combineTierMovies(data)
      : (data['movies'] as List<Map<String, dynamic>>);
      
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        flex: 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildCollectionCover(movies),
        ),
      ),
      const SizedBox(height: 8),
      _buildCollectionInfo(name, itemCount, label, isTierlist),
    ],
  );
}

Widget _buildListContent(String name, Map<String, dynamic> data, int itemCount, String label, bool isTierlist) {
  final movies = isTierlist 
      ? _combineTierMovies(data)
      : (data['movies'] as List<Map<String, dynamic>>);
      
  return Row(
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildCollectionCover(movies),
      ),
      const SizedBox(width: 16),
      Expanded(child: _buildCollectionInfo(name, itemCount, label, isTierlist)),
      const Icon(Icons.chevron_right),
    ],
  );
}

  Widget _buildCollectionInfo(String name, int itemCount, String label, bool isTierlist) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      Text(
        "$itemCount ${itemCount == 1 ? 'movie' : 'movies'}",
        style: TextStyle(color: Colors.grey[600]),
      ),
      if (label != 'none') ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getLabelColor(label),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      if (isTierlist) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.leaderboard, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text("Tierlist", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    ],
  );
}

void _navigateToCollectionDetail(String name, Map<String, dynamic> data, bool isTierlist) {
  if (isTierlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => tierlist_page.TierlistPage(
          tierlistName: name,
          initialData: data,
        ),
      ),
    ).then((_) => _loadCollections());
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => playlist_page.PlaylistDetailPage(
          playlistName: name,
          movies: data['movies'] as List<Map<String, dynamic>>,
          label: data['label'] as String,
          onRemoveMovie: (movieId) async {
            final prefs = await SharedPreferences.getInstance();
            setState(() {
              _playlists[name]!['movies'] = List<Map<String, dynamic>>.from(
                (_playlists[name]!['movies'] as List<Map<String, dynamic>>)
                    .where((movie) => movie['id'] != movieId),
              );
            });
            await prefs.setString('playlists', json.encode(_playlists));
          },
          onUpdateLabel: (newLabel) async {
            final prefs = await SharedPreferences.getInstance();
            setState(() {
              _playlists[name]!['label'] = newLabel;
            });
            await prefs.setString('playlists', json.encode(_playlists));
          },
        ),
      ),
    ).then((_) => _loadCollections());
  }
}

  Widget _buildCollectionCover(List<Map<String, dynamic>> movies) {
    if (movies.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            size: 40,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (movies.length == 1) {
      return Image.network(
        _getPosterUrl(movies[0]),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: movies.take(4).map((movie) => _buildMovieThumbnail(movie)).toList(),
    );
  }

  Widget _buildMovieThumbnail(Map<String, dynamic> movie) {
    return Image.network(
      _getPosterUrl(movie),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
    );
  }

  String _getPosterUrl(Map<String, dynamic> movie) {
    String? imagePath = movie['media_type'] == 'tv_episode' ? 
        movie['still_path'] : movie['poster_path'];
        
    return imagePath != null && imagePath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$imagePath'
        : 'https://via.placeholder.com/150x225?text=No+Image';
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.grey,
        ),
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
}

class PlaylistContentPage extends StatelessWidget {
  final String playlistName;
  final List<Map<String, dynamic>> movies;
  final String label;
  final Function(int) onRemoveMovie;
  final Function(String) onUpdateLabel;

  const PlaylistContentPage({
    super.key,
    required this.playlistName,
    required this.movies,
    required this.label,
    required this.onRemoveMovie,
    required this.onUpdateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlistName),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              // Edit playlist options
            },
          ),
        ],
      ),
      body: movies.isEmpty
          ? const Center(
              child: Text('No movies in this playlist'),
            )
          : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return _buildMovieItem(context, movie);
              },
            ),
    );
  }

  Widget _buildMovieItem(BuildContext context, Map<String, dynamic> movie) {
    final String mediaType = movie['media_type'] ?? 'movie';
    final int id = movie['id'];
    final String title = movie['title'] ?? movie['name'] ?? 'No Title';
    final String posterPath = movie['poster_path'] ?? '';
    final double voteAverage = (movie['vote_average'] as num?)?.toDouble() ?? 0.0;
    
    // Check if this is a TV episode
    final bool isTvEpisode = mediaType == 'tv_episode';
    final int? seasonNumber = isTvEpisode ? movie['season_number'] : null;
    final int? episodeNumber = isTvEpisode ? movie['episode_number'] : null;
    final int? showId = isTvEpisode ? movie['show_id'] : null;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: posterPath.isNotEmpty
              ? Image.network(
                  'https://image.tmdb.org/t/p/w92$posterPath',
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 75,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 24),
                  ),
                )
              : Container(
                  width: 50,
                  height: 75,
                  color: Colors.grey[300],
                  child: const Icon(Icons.movie, size: 24),
                ),
        ),
        title: Text(title),
        subtitle: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            Text(' ${voteAverage.toStringAsFixed(1)}'),
            const SizedBox(width: 8),
            Text(isTvEpisode 
                ? 'S${seasonNumber}E$episodeNumber' 
                : (mediaType == 'tv' ? 'TV Show' : 'Movie')),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onRemoveMovie(id),
        ),
        onTap: () {
          // Navigate to the appropriate detail page
          if (isTvEpisode && showId != null) {
            // Navigate to episode detail
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => episode_detail.EpisodeDetailPage(
                  tvShowId: showId,
                  seasonNumber: seasonNumber!,
                  episodeNumber: episodeNumber!, tvShowName: '',
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => movie_detail.MovieDetailPage(
                  movieId: id,
                  mediaType: mediaType,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

// New custom tierlist content page with proper detail navigation
class TierlistContentPage extends StatelessWidget {
  final String tierlistName;
  final Map<String, dynamic> tierlistData;

  const TierlistContentPage({
    super.key,
    required this.tierlistName,
    required this.tierlistData,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> tiers = ['S', 'A', 'B', 'C', 'D', 'E'];
    final String label = tierlistData['label'] as String;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(tierlistName),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              // Edit tierlist options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Display label if not 'none'
          if (label != 'none')
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getLabelColor(label),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Tierlist content
          Expanded(
            child: ListView.builder(
              itemCount: tiers.length,
              itemBuilder: (context, index) {
                final tier = tiers[index];
                final movies = tierlistData[tier] as List<dynamic>;
                
                // Skip empty tiers
                if (movies.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTierHeader(tier),
                    _buildTierContent(context, tier, movies.cast<Map<String, dynamic>>()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTierHeader(String tier) {
    Color tierColor;
    switch (tier) {
      case 'S': tierColor = Colors.red.shade700;
        break;
      case 'A': tierColor = Colors.orange.shade700;
        break;
      case 'B': tierColor = Colors.yellow.shade700;
        break;
      case 'C': tierColor = Colors.green.shade500;
        break;
      case 'D': tierColor = Colors.blue.shade500;
        break;
      case 'E': tierColor = Colors.purple.shade500;
        break;
      default: tierColor = Colors.grey;
    }
    
    return Container(
      color: tierColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            tier,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            getTierDescription(tier),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  String getTierDescription(String tier) {
    switch (tier) {
      case 'S': return 'Masterpiece';
      case 'A': return 'Excellent';
      case 'B': return 'Good';
      case 'C': return 'Average';
      case 'D': return 'Below Average';
      case 'E': return 'Poor';
      default: return '';
    }
  }
  
  Widget _buildTierContent(BuildContext context, String tier, List<Map<String, dynamic>> movies) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: movies.length,
          itemBuilder: (context, index) {
            return _buildMovieCard(context, movies[index]);
          },
        ),
      ),
    );
  }
  
  Widget _buildMovieCard(BuildContext context, Map<String, dynamic> movie) {
    final String mediaType = movie['media_type'] ?? 'movie';
    final int id = movie['id'];
    final String title = movie['title'] ?? movie['name'] ?? 'No Title';
    final String posterPath = movie['poster_path'] ?? '';
    
    // Check if this is a TV episode
    final bool isTvEpisode = mediaType == 'tv_episode';
    final int? seasonNumber = isTvEpisode ? movie['season_number'] : null;
    final int? episodeNumber = isTvEpisode ? movie['episode_number'] : null;
    final int? showId = isTvEpisode ? movie['show_id'] : null;
    
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigate to the appropriate detail page
                if (isTvEpisode && showId != null) {
                  // Navigate to episode detail
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => episode_detail.EpisodeDetailPage(
                        tvShowId: showId,
                        seasonNumber: seasonNumber!,
                        episodeNumber: episodeNumber!, tvShowName: '',
                      ),
                    ),
                  );
                } else {
                  // Navigate to movie or TV show detail page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => movie_detail.MovieDetailPage(
                        movieId: id,
                        mediaType: mediaType,
                      ),
                    ),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: posterPath.isNotEmpty
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w185$posterPath',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
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
}
