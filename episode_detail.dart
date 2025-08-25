import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String apiKey = 'd54c8ae5d997772ae7a6879e252e6785';

class EpisodeDetailPage extends StatefulWidget {
  final int tvShowId;
  final int seasonNumber;
  final int episodeNumber;
  final String tvShowName;
  
  const EpisodeDetailPage({
    super.key, 
    required this.tvShowId, 
    required this.seasonNumber, 
    required this.episodeNumber,
    required this.tvShowName,
  });

  @override
  _EpisodeDetailPageState createState() => _EpisodeDetailPageState();
}

class _EpisodeDetailPageState extends State<EpisodeDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic> _episodeDetails = {};
  Map<String, Map<String, dynamic>> _playlists = {};
  
  @override
  void initState() {
    super.initState();
    _fetchEpisodeDetails();
    _loadPlaylists();
  }
  
  Future<void> _fetchEpisodeDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/tv/${widget.tvShowId}/season/${widget.seasonNumber}/episode/${widget.episodeNumber}?api_key=$apiKey'
        ),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _episodeDetails = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }
  
  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('playlists');

    if (savedData != null) {
      setState(() {
        _playlists = Map<String, Map<String, dynamic>>.from(
          json.decode(savedData).map((key, value) => MapEntry(
                key,
                {
                  'movies': List<Map<String, dynamic>>.from(value['movies']),
                  'label': value['label'] ?? 'none',
                },
              )),
        );
      });
    }
  }
  
  void _handleError() {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load episode details')),
    );
  }
  
  Future<void> _addToPlaylist(String playlistName) async {
    final prefs = await SharedPreferences.getInstance();
    
   final episodeData = {
  'id': '${widget.tvShowId}_${widget.seasonNumber}_${widget.episodeNumber}',
  'title': '${widget.tvShowName} - S${widget.seasonNumber}E${widget.episodeNumber}',
  'name': _episodeDetails['name'] ?? 'Episode ${widget.episodeNumber}',
  'still_path': _episodeDetails['still_path'],
  'vote_average': _episodeDetails['vote_average'],
  'air_date': _episodeDetails['air_date'],
  'overview': _episodeDetails['overview'],
  'season_number': widget.seasonNumber,
  'episode_number': widget.episodeNumber,
  'parent_show_id': widget.tvShowId,
  'show_name': widget.tvShowName,
  'media_type': 'tv_episode',
};

    setState(() {
      _playlists.putIfAbsent(playlistName, () => {'movies': [], 'label': 'none'});
      if (!_playlists[playlistName]!['movies'].any((m) => m['id'] == episodeData['id'])) {
        _playlists[playlistName]!['movies'].add(episodeData);
      }
    });

    await prefs.setString('playlists', json.encode(_playlists));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to $playlistName playlist')),
    );
    Navigator.pop(context); 
  }

  void _showAddToWatchlistBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add to Playlist',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_playlists.isEmpty)
                const Text('No playlists available. Create one first.')
              else
                ..._playlists.keys.map((playlistName) => ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: Text(playlistName),
                  subtitle: Text(
                    '${_playlists[playlistName]!['movies'].length} items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () => _addToPlaylist(playlistName),
                )),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog();
                },
                child: const Text('Create New Playlist', 
                  style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      },
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
                      _showAddToWatchlistBottomSheet(context);
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

  Color _getLabelColor(String label) {
    switch (label) {
      case 'watching': return Colors.blue;
      case 'planned': return Colors.purple;
      case 'completed': return Colors.green;
      case 'dropped': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  Widget _buildGuestStarsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          "Guest Stars",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_episodeDetails['guest_stars'] != null && 
            (_episodeDetails['guest_stars'] as List).isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _episodeDetails['guest_stars'].length,
              itemBuilder: (context, index) {
                final guest = _episodeDetails['guest_stars'][index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: guest['profile_path'] != null
                            ? NetworkImage(
                                'https://image.tmdb.org/t/p/w200${guest['profile_path']}')
                            : null,
                        child: guest['profile_path'] == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guest['name'] ?? 'Unknown',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          const Text("No guest stars information available."),
      ],
    );
  }
  
  Widget _buildCrewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          "Crew",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_episodeDetails['crew'] != null && 
            (_episodeDetails['crew'] as List).isNotEmpty)
          Column(
            children: (_episodeDetails['crew'] as List).map<Widget>((crew) {
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundImage: crew['profile_path'] != null
                      ? NetworkImage(
                          'https://image.tmdb.org/t/p/w200${crew['profile_path']}')
                      : null,
                  child: crew['profile_path'] == null
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                title: Text(crew['name'] ?? 'Unknown'),
                subtitle: Text(crew['job'] ?? 'Unknown role'),
              );
            }).toList(),
          )
        else
          const Text("No crew information available."),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(
          widget.tvShowName,
          style: const TextStyle(color: Colors.black)
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode Image
                  _episodeDetails['still_path'] != null
                      ? SizedBox(
                          width: double.infinity,
                          height: 230,
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w500${_episodeDetails['still_path']}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.error, size: 50),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 230,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.movie, size: 50),
                          ),
                        ),
                  // Episode Info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "S${widget.seasonNumber} E${widget.episodeNumber}: ${_episodeDetails['name'] ?? 'Episode'}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  (_episodeDetails['vote_average'] as num?)?.toStringAsFixed(1) ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Air Date: ${_episodeDetails['air_date'] ?? 'Unknown'}",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Overview",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _episodeDetails['overview'] ?? 'No overview available.',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddToWatchlistBottomSheet(context);
                          },
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text('Add to Playlist', style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                    
                        if (_episodeDetails['guest_stars'] != null && 
                            (_episodeDetails['guest_stars'] as List).isNotEmpty)
                          _buildGuestStarsSection(),
                        
                        if (_episodeDetails['crew'] != null && 
                            (_episodeDetails['crew'] as List).isNotEmpty)
                          _buildCrewSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
