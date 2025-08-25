import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'moviedetail.dart';

class TierlistPage extends StatefulWidget {
  final String? tierlistName; 
  final Map<String, dynamic>? initialData;  
  final Map<String, dynamic>? selectedMovie; 

  const TierlistPage({
    super.key,
    this.tierlistName,
    this.initialData,
    this.selectedMovie,
  });

  @override
  _TierlistPageState createState() => _TierlistPageState();
}

class _TierlistPageState extends State<TierlistPage> {
  Map<String, Map<String, List<Map<String, dynamic>>>> tierLists = {};
  bool isLoading = true;
  final List<String> tierOrder = ['S', 'A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _loadTierLists();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedMovie != null) {
        _showTierSelectionDialog(widget.selectedMovie!);
      }
    });
  }

 Future<void> _loadTierLists() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('tier_lists');
    
    setState(() {
      isLoading = false;
      if (savedData != null) {
        try {
          tierLists = Map<String, Map<String, List<Map<String, dynamic>>>>.from(
            json.decode(savedData).map((key, value) => MapEntry(
              key,
              Map<String, List<Map<String, dynamic>>>.from(
                value.map((tier, movies) => MapEntry(
                  tier,
                  List<Map<String, dynamic>>.from(movies),
                )),
              ),
            )),
          );
        } catch (e) {
          tierLists = {};
        }
      }
    });
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load tierlists')),
    );
  }
}

  Future<void> _saveTierLists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tier_lists', json.encode(tierLists));
  }

  void _showTierSelectionDialog(Map<String, dynamic> movie) {
    TextEditingController tierlistController = TextEditingController();
    String? selectedTierlist;
    String? selectedTier;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16, 
                right: 16
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add to Tierlist',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    if (tierLists.isNotEmpty) ...[
                      const Text(
                        'Choose Existing Tierlist:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedTierlist,
                        hint: const Text("Select a Tierlist"),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            selectedTierlist = value;
                            selectedTier = null;
                          });
                        },
                        items: tierLists.keys.map((tierlist) {
                          return DropdownMenuItem<String>(
                            value: tierlist,
                            child: Text(tierlist),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      if (selectedTierlist != null) ...[
                        const Text(
                          'Choose Tier:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedTier,
                          hint: const Text("Select a Tier"),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              selectedTier = value;
                            });
                          },
                          items: tierOrder.map((tier) {
                            return DropdownMenuItem<String>(
                              value: tier,
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _getTierColor(tier),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      tier,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(tier),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                    const Divider(),
                    const Text(
                      'Create New Tierlist:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (selectedTierlist != null && selectedTier != null)
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setState(() {
                                  // Check if movie already exists in this tier
                                  if (!tierLists[selectedTierlist]![selectedTier]!.any((m) => m['id'] == movie['id'])) {
                                    // Remove the movie from other tiers if it exists
                                    for (var tier in tierOrder) {
                                      tierLists[selectedTierlist]![tier]!.removeWhere((m) => m['id'] == movie['id']);
                                    }
                                    
                                    // Add to selected tier
                                    tierLists[selectedTierlist]![selectedTier]!.add(movie);
                                    _saveTierLists();
                                  }
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added to $selectedTierlist ($selectedTier tier)'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text(
                                'Add to Existing Tierlist',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        
                        const SizedBox(width: 8),
                        
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tierlistController.text.isEmpty 
                                  ? Colors.grey 
                                  : Colors.amber,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: tierlistController.text.isEmpty 
                                ? null 
                                : () {
                                    setState(() {
                                      // Create new tierlist with empty tiers
                                      tierLists[tierlistController.text] = {
                                        'S': [], 'A': [], 'B': [], 'C': [], 'D': [], 'E': []
                                      };
                                      
                                      // ignore: unnecessary_null_comparison
                                      if (movie != null) {
                                        tierLists[tierlistController.text]!['S']!.add(movie);
                                      }
                                    });
                                    _saveTierLists();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Created tierlist "${tierlistController.text}" and added movie to S tier'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Create New Tierlist',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTierlistDialog(String tierlistName) {
    TextEditingController nameController = TextEditingController(text: tierlistName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Tierlist"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Tierlist Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Rename tierlist
              if (nameController.text != tierlistName && nameController.text.isNotEmpty) {
                setState(() {
                  Map<String, List<Map<String, dynamic>>> currentTiers = tierLists[tierlistName]!;
                  tierLists.remove(tierlistName);
                  tierLists[nameController.text] = currentTiers;
                });
                _saveTierLists();
              }
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmDialog(tierlistName);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String tierlistName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Tierlist"),
        content: Text("Are you sure you want to delete '$tierlistName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tierLists.remove(tierlistName);
              });
              _saveTierLists();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tierlist deleted')),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _createNewTierlist() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Tierlist"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Tierlist Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  tierLists[nameController.text] = {
                    'S': [], 'A': [], 'B': [], 'C': [], 'D': [], 'E': []
                  };
                });
                _saveTierLists();
                Navigator.pop(context);
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _removeMovieFromTier(String tierlistName, String tier, int movieId) {
    setState(() {
      tierLists[tierlistName]![tier]!.removeWhere((movie) => movie['id'] == movieId);
    });
    _saveTierLists();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Movie removed from tier')),
    );
  }

  void _viewTierlistDetail(String tierlistName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TierlistDetailPage(
          tierlistName: tierlistName,
          tiers: tierLists[tierlistName]!,
          onRemoveMovie: (tier, movieId) => _removeMovieFromTier(tierlistName, tier, movieId),
          onSave: _saveTierLists,
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'S': return Colors.red.shade400;
      case 'A': return Colors.orange.shade400;
      case 'B': return Colors.amber.shade400;
      case 'C': return Colors.green.shade400;
      case 'D': return Colors.blue.shade400;
      case 'E': return Colors.purple.shade400;
      default: return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text("My Tierlists", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _createNewTierlist,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : tierLists.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tierLists.length,
                  itemBuilder: (context, index) {
                    final entry = tierLists.entries.elementAt(index);
                    return _buildTierlistCard(entry.key, entry.value);
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
            Icons.grid_view,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            "No tierlists available",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Create a new tierlist to get started",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _createNewTierlist,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text("Create Tierlist", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

Widget _buildTierlistCard(String tierlistName, Map<String, List<Map<String, dynamic>>> tiers) {
  // Count total movies
  int totalMovies = 0;
  tiers.forEach((tier, movies) {
    totalMovies += movies.length;
  });

  List<Map<String, dynamic>> previewMovies = [];
  for (var tier in tierOrder) {
    if (tiers.containsKey(tier) && tiers[tier] != null && tiers[tier]!.isNotEmpty) {
      previewMovies.addAll(tiers[tier]!);
      if (previewMovies.length >= 4) break;
    }
  }
    
    while (previewMovies.length < 4) {
      previewMovies.add({'poster_path': '', 'id': -1});
    }
    previewMovies = previewMovies.take(4).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: () => _viewTierlistDetail(tierlistName),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview grid at the top
            SizedBox(
              height: 120,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                  children: previewMovies.map((movie) {
                    if (movie['id'] == -1) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.grid_view, color: Colors.grey, size: 32),
                        ),
                      );
                    }
                    
                    String posterUrl = movie['poster_path'] != null && movie['poster_path'].isNotEmpty
                        ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
                        : 'https://via.placeholder.com/180x180?text=No+Image';
                        
                    return Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Info section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tierlistName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$totalMovies ${totalMovies == 1 ? 'movie' : 'movies'}",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.amber),
                    onPressed: () => _showEditTierlistDialog(tierlistName),
                  ),
                ],
              ),
            ),
            
            // Tier preview
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: tierOrder.map((tier) {
                  return Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _getTierColor(tier),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tier,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TierlistDetailPage extends StatefulWidget {
  final String tierlistName;
  final Map<String, List<Map<String, dynamic>>> tiers;
  final Function(String, int) onRemoveMovie;
  final Function() onSave;

  const TierlistDetailPage({
    super.key,
    required this.tierlistName,
    required this.tiers,
    required this.onRemoveMovie,
    required this.onSave,
  });

  @override
  _TierlistDetailPageState createState() => _TierlistDetailPageState();
}

class _TierlistDetailPageState extends State<TierlistDetailPage> {
  final List<String> tierOrder = ['S', 'A', 'B', 'C', 'D', 'E'];
  
  // For drag and drop functionality
  String? draggedTier;
  Map<String, dynamic>? draggedMovie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.tierlistName, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info text
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Drag and drop movies between tiers to rearrange",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
            
            // List of tiers
            Column(
              children: tierOrder.map((tier) {
                // Ensure the tier exists in the tiers map
                final movies = widget.tiers.containsKey(tier) ? widget.tiers[tier]! : <Map<String, dynamic>>[];
                return _buildTierRow(tier, movies);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(String tier, List<Map<String, dynamic>> movies) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: DragTarget<Map<String, dynamic>>(
        onAcceptWithDetails: (data) {
          if (draggedTier != null && draggedMovie != null) {
            setState(() {
              widget.tiers[draggedTier]!.remove(draggedMovie);
            
              if (!widget.tiers[tier]!.any((m) => m['id'] == draggedMovie!['id'])) {
                widget.tiers[tier]!.add(draggedMovie!);
              }
              
              draggedTier = null;
              draggedMovie = null;
            });
            widget.onSave();
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Column(
            children: [
              // Tier header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _getTierColor(tier),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Text(
                      "$tier Tier",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "(${movies.length} ${movies.length == 1 ? 'movie' : 'movies'})",
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(12),
                child: movies.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          "No movies in $tier tier",
                          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: movies.map((movie) {
                          return _buildDraggableMovieItem(tier, movie);
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDraggableMovieItem(String tier, Map<String, dynamic> movie) {
    String posterUrl = movie['poster_path'] != null && movie['poster_path'].isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
        : 'https://via.placeholder.com/100x150?text=No+Image';

    return Draggable<Map<String, dynamic>>(
      data: movie,
      feedback: SizedBox(
        width: 80,
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 40, color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildMovieThumbnail(movie, posterUrl),
      ),
      onDragStarted: () {
        setState(() {
          draggedTier = tier;
          draggedMovie = movie;
        });
      },
      child: _buildMovieThumbnail(movie, posterUrl),
    );
  }

  Widget _buildMovieThumbnail(Map<String, dynamic> movie, String posterUrl) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showMovieDetail(movie),
          child: SizedBox(
            width: 80,
            height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 40, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showRemoveConfirmDialog(movie),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        if (movie['vote_average'] != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    movie['vote_average'].toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showMovieDetail(Map<String, dynamic> movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(
          movieId: movie['id'],
          mediaType: movie['media_type'] ?? 'movie',
        ),
      ),
    );
  }

  void _showRemoveConfirmDialog(Map<String, dynamic> movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Movie"),
        content: Text("Are you sure you want to remove '${movie['title'] ?? movie['name']}' from this tier?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              String? foundTier;
              for (var tier in tierOrder) {
                if (widget.tiers[tier]!.any((m) => m['id'] == movie['id'])) {
                  foundTier = tier;
                  break;
                }
              }
              
              if (foundTier != null) {
                widget.onRemoveMovie(foundTier, movie['id']);
              }
              Navigator.pop(context);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'S': return Colors.red.shade400;
      case 'A': return Colors.orange.shade400;
      case 'B': return Colors.amber.shade400;
      case 'C': return Colors.green.shade400;
      case 'D': return Colors.blue.shade400;
      case 'E': return Colors.purple.shade400;
      default: return Colors.grey.shade400;
    }
  }
}