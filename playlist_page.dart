import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'moviedetail.dart';
import 'episode_detail.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  Map<String, List<Map<String, dynamic>>> playlists = {};
  Map<String, String> playlistLabels = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('playlists');

    setState(() {
      isLoading = false;
      if (savedData != null) {
        final Map<String, dynamic> decodedData = json.decode(savedData);
        
        playlists = {};
        playlistLabels = {};
        
        decodedData.forEach((key, value) {
          if (value is List) {
            playlists[key] = List<Map<String, dynamic>>.from(value);
            playlistLabels[key] = 'none';
          } else if (value is Map) {
            playlists[key] = List<Map<String, dynamic>>.from(value['movies'] ?? []);
            playlistLabels[key] = value['label'] ?? 'none';
          }
        });
      }
    });
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, dynamic> saveData = {};
    playlists.forEach((key, value) {
      saveData[key] = {
        'movies': value,
        'label': playlistLabels[key] ?? 'none'
      };
    });
    
    await prefs.setString('playlists', json.encode(saveData));
  }

  void _updatePlaylistOrder(String playlist) {
    if (playlists.containsKey(playlist)) {
      final playlistData = playlists.remove(playlist);
      final label = playlistLabels.remove(playlist);
      
      final Map<String, List<Map<String, dynamic>>> newPlaylists = {playlist: playlistData!, ...playlists};
      final Map<String, String> newLabels = {playlist: label!, ...playlistLabels};
      
      playlists = newPlaylists;
      playlistLabels = newLabels;
    }
  }

void addMovieToPlaylist(String playlist, Map<String, dynamic> movie, {String label = 'none'}) {
  // Normalisasi format genre
  if (!movie.containsKey('genres')) {
    movie['genres'] = [];
  } else if (movie['genres'] is List<String>) {
    // Konversi List<String> ke List<Map>
    movie['genres'] = (movie['genres'] as List<String>)
        .map((name) => {'name': name})
        .toList();
  } else if (movie['genres'] is List<dynamic>) {
    // Pastikan format List<Map> dengan key 'name'
    movie['genres'] = (movie['genres'] as List)
        .map((g) => g is Map ? g : {'name': g.toString()})
        .toList();
  }

  setState(() {
    playlists.putIfAbsent(playlist, () => []);
    playlistLabels.putIfAbsent(playlist, () => label);
    
    if (!playlists[playlist]!.any((m) => m['id'] == movie['id'])) {
      playlists[playlist]!.add(movie);
      _updatePlaylistOrder(playlist);
    }
  });
  _savePlaylists();
}

  void removeMovieFromPlaylist(String playlist, int movieId) {
    setState(() {
      playlists[playlist]!.removeWhere((movie) => movie['id'] == movieId);
      if (playlists[playlist]!.isEmpty) {
        playlists.remove(playlist);
        playlistLabels.remove(playlist);
      } else {
        _updatePlaylistOrder(playlist);
      }
    });
    _savePlaylists();
  }

  void updatePlaylistLabel(String playlist, String newLabel) {
    setState(() {
      if (playlists.containsKey(playlist)) {
        playlistLabels[playlist] = newLabel;
      }
    });
    _savePlaylists();
  }

  void createPlaylist(BuildContext context) {
    TextEditingController playlistController = TextEditingController();
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
                      controller: playlistController,
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
                  onPressed: () {
                    if (playlistController.text.isNotEmpty) {
                      playlists[playlistController.text] = [];
                      playlistLabels[playlistController.text] = selectedLabel;
                      _savePlaylists();
                      Navigator.pop(context);
                      setState(() {}); 
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
        setState(() {
          selectedLabel = label;
        });
      },
      selectedColor: _getLabelColor(label),
      labelStyle: TextStyle(
        color: selectedLabel == label ? Colors.white : Colors.black,
      ),
    );
  }

  Color _getLabelColor(String label) {
    switch (label) {
      case 'watching':
        return Colors.blue;
      case 'planned':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'dropped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _viewPlaylistDetails(String playlistName, List<Map<String, dynamic>> movies) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailPage(
          playlistName: playlistName,
          movies: movies,
          label: playlistLabels[playlistName] ?? 'none',
          onRemoveMovie: (movieId) => removeMovieFromPlaylist(playlistName, movieId),
          onUpdateLabel: (newLabel) => updatePlaylistLabel(playlistName, newLabel),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('My Playlists', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () => createPlaylist(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : playlists.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final entry = playlists.entries.elementAt(index);
                    return _buildPlaylistCard(entry.key, entry.value);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.playlist_play,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            "No playlists available",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create a new playlist to get started",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => createPlaylist(context),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text("Create Playlist", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(String playlist, List<Map<String, dynamic>> movies) {
    final label = playlistLabels[playlist] ?? 'none';
    
    return InkWell(
      onTap: () => _viewPlaylistDetails(playlist, movies),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: _buildPlaylistCover(movies),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          playlist,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${movies.length} ${movies.length == 1 ? 'item' : 'items'}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (label != 'none')
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLabelColor(label),
                    borderRadius: BorderRadius.circular(12),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCover(List<Map<String, dynamic>> movies) {
    if (movies.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (movies.length == 1) {
      String posterUrl = _getPosterUrl(movies[0]);
      return Image.network(
        posterUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: movies.take(4).map((movie) {
        String posterUrl = _getPosterUrl(movie);
        return Image.network(
          posterUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      }).toList(),
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
}

class PlaylistDetailPage extends StatelessWidget {
  final String playlistName;
  final List<Map<String, dynamic>> movies;
  final String label;
  final Function(int) onRemoveMovie;
  final Function(String) onUpdateLabel;

  const PlaylistDetailPage({
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
        backgroundColor: Colors.amber,
        title: Text(playlistName, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<String>(
            onSelected: (newLabel) {
              onUpdateLabel(newLabel);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'none',
                child: Text("No Label"),
              ),
              const PopupMenuItem(
                value: 'watching',
                child: Text("Watching"),
              ),
              const PopupMenuItem(
                value: 'planned',
                child: Text("Planned"),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text("Completed"),
              ),
              const PopupMenuItem(
                value: 'dropped',
                child: Text("Dropped"),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPlaylistHeader(context),
          Expanded(
            child: movies.isEmpty
                ? const Center(child: Text("This playlist is empty"))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      return _buildMovieCard(context, movies[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(
            Icons.playlist_play,
            size: 36,
            color: _getLabelColor(label),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlistName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${movies.length} ${movies.length == 1 ? 'item' : 'items'} • ${label != 'none' ? label.toUpperCase() : 'No Label'}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: label != 'none' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLabelColor(String label) {
    switch (label) {
      case 'watching':
        return Colors.blue;
      case 'planned':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'dropped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMovieCard(BuildContext context, Map<String, dynamic> item) {
    //  TV episode or a movie
    final bool isEpisode = item['media_type'] == 'tv_episode';
    
    String? imagePath = isEpisode ? item['still_path'] : item['poster_path'];
    String posterUrl = imagePath != null && imagePath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$imagePath'
        : 'https://via.placeholder.com/150x225?text=No+Image';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (isEpisode) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EpisodeDetailPage(
                  tvShowId: item['parent_show_id'] ?? item['id'],
                  seasonNumber: item['season_number'] ?? 1,
                  episodeNumber: item['episode_number'] ?? 1,
                  tvShowName: item['title']?.split(' - ')?.first ?? 'TV Show',
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailPage(
                  movieId: item['id'],
                  mediaType: item['media_type'] ?? 'movie',
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  posterUrl,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'Unknown Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "${item['vote_average']?.toStringAsFixed(1) ?? 'N/A'}/10",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (item['release_date'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Released: ${item['release_date']}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                    if (item['media_type'] == 'tv_episode') ...[
                      const SizedBox(height: 4),
                      Text(
                        "S${item['season_number']}E${item['episode_number']}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Remove Item"),
                      content: Text("Remove '${item['title']}' from this playlist?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            onRemoveMovie(item['id']);
                            Navigator.pop(context);
                          },
                          child: const Text("Remove", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

