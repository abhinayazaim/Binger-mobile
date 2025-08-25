import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import

// Firebase base URL - replace with your own Firebase project URL
const String firebaseUrl = 'https://binger-32229-default-rtdb.asia-southeast1.firebasedatabase.app/';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user ID - will be set after authentication
  String? _currentUserId;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  String? getCurrentUserId() {
    return _currentUserId;
  }

  // Helper method for network requests with timeout and auth
  Future<http.Response> _makeRequest(String method, String url, {String? body}) async {
    // Get current user's ID token if available
    String? idToken;
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        idToken = await currentUser.getIdToken();
      } catch (e) {
        print('Error getting ID token: $e');
      }
    }

    // Add auth token to URL if available
    final Uri uri;
    if (idToken != null && url.contains('.json')) {
      final separator = url.contains('?') ? '&' : '?';
      uri = Uri.parse('$url${separator}auth=$idToken');
    } else {
      uri = Uri.parse(url);
    }

    const timeout = Duration(seconds: 30);
    final headers = {'Content-Type': 'application/json'};

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(uri, headers: headers).timeout(timeout);
        case 'POST':
          return await http.post(uri, headers: headers, body: body).timeout(timeout);
        case 'PUT':
          return await http.put(uri, headers: headers, body: body).timeout(timeout);
        case 'PATCH':
          return await http.patch(uri, headers: headers, body: body).timeout(timeout);
        case 'DELETE':
          return await http.delete(uri, headers: headers).timeout(timeout);
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      throw Exception('Network request failed: ${e.toString()}');
    }
  }
  // Add this method to your FirebaseService class
bool _isFirebaseInitialized() {
  try {
    Firebase.app();
    return true;
  } catch (e) {
    print('Firebase not initialized: $e');
    return false;
  }
}

// Update your isUserLoggedIn method
Future<bool> isUserLoggedIn() async {
  try {
    print('FirebaseService: Checking if user is logged in...');
    
    // Check if Firebase is initialized first
    if (!_isFirebaseInitialized()) {
      print('FirebaseService: Firebase not initialized, checking SharedPreferences only');
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null && userId.isNotEmpty) {
        print('FirebaseService: User found in SharedPreferences: $userId');
        _currentUserId = userId;
        return true;
      }
      return false;
    }
    
    // Check Firebase Auth if initialized
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      print('FirebaseService: User found in Firebase Auth: ${currentUser.uid}');
      _currentUserId = currentUser.uid;
      return true;
    }

    print('FirebaseService: No user in Firebase Auth, checking SharedPreferences...');
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null && userId.isNotEmpty) {
      print('FirebaseService: User found in SharedPreferences: $userId');
      _currentUserId = userId;
      return true;
    }

    print('FirebaseService: No user found anywhere');
    return false;
  } catch (e) {
    print('FirebaseService: Error checking login status: $e');
    return false;
  }
}

  // ------ User Management ------ //

  // Register new user with Firebase Auth
  Future<Map<String, dynamic>> registerUser(String email, String password, String username) async {
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        return {
          'success': false,
          'message': 'All fields are required',
        };
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {
          'success': false,
          'message': 'Invalid email format',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      // Create user with Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(username);

        // Get ID token
        final idToken = await user.getIdToken();

        // Save additional user data to Realtime Database
        final userData = {
          'email': email,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
          'last_login': DateTime.now().toIso8601String(),
        };

        final response = await http.put(
          Uri.parse('$firebaseUrl/users/${user.uid}.json?auth=$idToken'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(userData),
        );

        if (response.statusCode == 200) {
          // Save user ID
          _currentUserId = user.uid;

          // Save user data to shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', user.uid);
          await prefs.setString('username', username);
          await prefs.setString('email', email);

          return {
            'success': true,
            'user_id': user.uid,
            'message': 'Registration successful',
          };
        } else {
          // If database save fails, delete the Firebase Auth user
          await user.delete();
          return {
            'success': false,
            'message': 'Failed to save user data: ${response.statusCode}',
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to create user account',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration error: ${e.toString()}',
      };
    }
  }

  // Sign in user with Firebase Auth
  Future<Map<String, dynamic>> signInUser(String email, String password) async {
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required',
        };
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update last login in database
        final idToken = await user.getIdToken();
        await http.patch(
          Uri.parse('$firebaseUrl/users/${user.uid}.json?auth=$idToken'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'last_login': DateTime.now().toIso8601String(),
          }),
        );

        // Get user data from database
        final response = await http.get(
          Uri.parse('$firebaseUrl/users/${user.uid}.json?auth=$idToken'),
        );

        String username = user.displayName ?? 'User';
        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          if (userData != null && userData['username'] != null) {
            username = userData['username'];
          }
        }

        // Save user ID
        _currentUserId = user.uid;

        // Save user data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.uid);
        await prefs.setString('username', username);
        await prefs.setString('email', email);

        return {
          'success': true,
          'user_id': user.uid,
          'username': username,
          'message': 'Login successful',
        };
      }

      return {
        'success': false,
        'message': 'Login failed',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login error: ${e.toString()}',
      };
    }
  }

  // Sign out user
  Future<void> signOutUser() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('email');
      _currentUserId = null;
    } catch (e) {
      // Log error but don't throw
      print('Sign out error: ${e.toString()}');
    }
  }

  // Replace your isUserLoggedIn method in FirebaseService with this:
Future<bool> isUserLoggedIn1() async {
  try {
    print('FirebaseService: Checking if user is logged in...');
    
    // Add timeout to prevent hanging
    final currentUser = await Future.any([
      Future.value(_auth.currentUser),
      Future.delayed(const Duration(seconds: 5), () => null), // 5 second timeout
    ]);
    
    if (currentUser != null) {
      print('FirebaseService: User found in Firebase Auth: ${currentUser.uid}');
      _currentUserId = currentUser.uid;
      return true;
    }

    print('FirebaseService: No user in Firebase Auth, checking SharedPreferences...');
    
    // Also check shared preferences as backup with timeout
    final prefs = await Future.any([
      SharedPreferences.getInstance(),
      Future.delayed(const Duration(seconds: 3), () => throw TimeoutException('SharedPreferences timeout')),
    ]);
    
    final userId = prefs.getString('user_id');
    if (userId != null && userId.isNotEmpty) {
      print('FirebaseService: User found in SharedPreferences: $userId');
      _currentUserId = userId;
      return true;
    }

    print('FirebaseService: No user found anywhere');
    return false;
  } catch (e) {
    print('FirebaseService: Error checking login status: $e');
    return false;
  }
}

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      final idToken = await currentUser.getIdToken();
      final response = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}.json?auth=$idToken'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null) {
          return {
            'success': true,
            'profile': data,
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to get user profile: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Profile fetch error: ${e.toString()}',
      };
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      // Prevent updating sensitive fields
      profileData.remove('password');
      profileData.remove('created_at');
      profileData['updated_at'] = DateTime.now().toIso8601String();

      final idToken = await currentUser.getIdToken();
      final response = await http.patch(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}.json?auth=$idToken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Profile updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Profile update error: ${e.toString()}',
      };
    }
  }

  // ------ Movie Ratings Management ------ //

  // Save movie rating
  Future<Map<String, dynamic>> saveMovieRating(Map<String, dynamic> movieData, double rating) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    // Validate rating
    if (rating < 0 || rating > 10) {
      return {
        'success': false,
        'message': 'Rating must be between 0 and 10',
      };
    }

    try {
      final movieId = movieData['id'].toString();
      final idToken = await currentUser.getIdToken();

      // Check if movie rating already exists
      final checkResponse = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/ratings/$movieId.json?auth=$idToken'),
      );

      final Map<String, dynamic> ratingData = {
        'id': movieData['id'],
        'title': movieData['title'],
        'poster_path': movieData['poster_path'],
        'rating': rating,
        'media_type': movieData['media_type'] ?? 'movie',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (checkResponse.statusCode == 200 && checkResponse.body != 'null') {
        // Update existing rating
        final updateResponse = await http.patch(
          Uri.parse('$firebaseUrl/users/${currentUser.uid}/ratings/$movieId.json?auth=$idToken'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(ratingData),
        );

        if (updateResponse.statusCode == 200) {
          return {
            'success': true,
            'message': 'Rating updated successfully',
          };
        }
      } else {
        // Create new rating
        ratingData['created_at'] = DateTime.now().toIso8601String();
        final createResponse = await http.put(
          Uri.parse('$firebaseUrl/users/${currentUser.uid}/ratings/$movieId.json?auth=$idToken'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(ratingData),
        );

        if (createResponse.statusCode == 200) {
          return {
            'success': true,
            'message': 'Rating saved successfully',
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to save rating',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Rating save error: ${e.toString()}',
      };
    }
  }

  // Get user's movie ratings
  Future<Map<String, dynamic>> getMovieRatings() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
        'ratings': {},
      };
    }

    try {
      final idToken = await currentUser.getIdToken();
      final response = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/ratings.json?auth=$idToken'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) ?? {};
        return {
          'success': true,
          'ratings': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get ratings: ${response.statusCode}',
          'ratings': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ratings fetch error: ${e.toString()}',
        'ratings': {},
      };
    }
  }

  // Delete movie rating
  Future<Map<String, dynamic>> deleteMovieRating(int movieId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      final idToken = await currentUser.getIdToken();
      final response = await http.delete(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/ratings/$movieId.json?auth=$idToken'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Rating deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete rating: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Rating delete error: ${e.toString()}',
      };
    }
  }

  // ------ Playlist Management ------ //

  // Get user's playlists
  Future<Map<String, dynamic>> getPlaylists() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
        'playlists': {},
      };
    }

    try {
      final idToken = await currentUser.getIdToken();
      final response = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/playlists.json?auth=$idToken'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) ?? {};
        return {
          'success': true,
          'playlists': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get playlists: ${response.statusCode}',
          'playlists': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Playlists fetch error: ${e.toString()}',
        'playlists': {},
      };
    }
  }

  // Create new playlist
  Future<Map<String, dynamic>> createPlaylist(String playlistName, String label, Map<String, dynamic> movie) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    // Validate input
    if (playlistName.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Playlist name cannot be empty',
      };
    }

    try {
      final idToken = await currentUser.getIdToken();

      // First, check if playlist already exists
      final checkResponse = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/playlists.json?auth=$idToken'),
      );

      if (checkResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(checkResponse.body) ?? {};

        if (data.containsKey(playlistName)) {
          return {
            'success': false,
            'message': 'Playlist already exists',
          };
        }
      }

      // Create the new playlist
      final playlistData = {
        'movies': [movie],
        'label': label,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await http.put(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/playlists/$playlistName.json?auth=$idToken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(playlistData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Playlist created successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create playlist: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Playlist creation error: ${e.toString()}',
      };
    }
  }

  // Add movie to playlist
  Future<Map<String, dynamic>> addMovieToPlaylist(String playlistName, Map<String, dynamic> movie) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      final idToken = await currentUser.getIdToken();

      // Get the current playlist
      final playlistResponse = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/playlists/$playlistName.json?auth=$idToken'),
      );

      if (playlistResponse.statusCode == 200 && playlistResponse.body != 'null') {
        final Map<String, dynamic> playlistData = json.decode(playlistResponse.body);
        List<dynamic> movies = List.from(playlistData['movies'] ?? []);

        // Check if movie already exists in playlist
        bool movieExists = movies.any((existingMovie) => existingMovie['id'] == movie['id']);

        if (!movieExists) {
          movies.add(movie);

          // Update the playlist
          final updateResponse = await http.patch(
            Uri.parse('$firebaseUrl/users/${currentUser.uid}/playlists/$playlistName.json?auth=$idToken'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'movies': movies,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );

          if (updateResponse.statusCode == 200) {
            return {
              'success': true,
              'message': 'Movie added to playlist successfully',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Movie already in playlist',
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to add movie to playlist',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Add to playlist error: ${e.toString()}',
      };
    }
  }

  // Remove movie from playlist
  Future<Map<String, dynamic>> removeMovieFromPlaylist(String playlistName, int movieId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      final idToken = await currentUser.getIdToken();

      // Get the current playlist
      final playlistResponse = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/playlists/$playlistName.json?auth=$idToken'),
      );

      if (playlistResponse.statusCode == 200 && playlistResponse.body != 'null') {
        final Map<String, dynamic> playlistData = json.decode(playlistResponse.body);
        List<dynamic> movies = List.from(playlistData['movies'] ?? []);

        // Remove the movie
        final initialLength = movies.length;
        movies.removeWhere((movie) => movie['id'] == movieId);

        if (movies.length < initialLength) {
          // Update the playlist
          final updateResponse = await http.patch(
            Uri.parse('$firebaseUrl/users/${currentUser.uid}/playlists/$playlistName.json?auth=$idToken'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'movies': movies,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );

          if (updateResponse.statusCode == 200) {
            return {
              'success': true,
              'message': 'Movie removed from playlist successfully',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Movie not found in playlist',
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to remove movie from playlist',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Remove from playlist error: ${e.toString()}',
      };
    }
  }

  // Delete playlist
  Future<Map<String, dynamic>> deletePlaylist(String playlistName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      final idToken = await currentUser.getIdToken();
      final response = await http.delete(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/playlists/$playlistName.json?auth=$idToken'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Playlist deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete playlist: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Playlist deletion error: ${e.toString()}',
      };
    }
  }

  // ------ Tierlist Management ------ //

  // Get user's tierlists
  Future<Map<String, dynamic>> getTierlists() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
        'tierlists': {},
      };
    }

    try {
      final idToken = await currentUser.getIdToken();
      final response = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/tierlists.json?auth=$idToken'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) ?? {};
        return {
          'success': true,
          'tierlists': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get tierlists: ${response.statusCode}',
          'tierlists': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Tierlists fetch error: ${e.toString()}',
        'tierlists': {},
      };
    }
  }

  // Create new tierlist
  Future<Map<String, dynamic>> createTierlist(String tierlistName, Map<String, dynamic> movie) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    // Validate input
    if (tierlistName.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Tierlist name cannot be empty',
      };
    }

    try {
      final idToken = await currentUser.getIdToken();

      // First, check if tierlist already exists
      final checkResponse = await http.get(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/tierlists.json?auth=$idToken'),
      );

      if (checkResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(checkResponse.body) ?? {};

        if (data.containsKey(tierlistName)) {
          return {
            'success': false,
            'message': 'Tierlist already exists',
          };
        }
      }

      // Create the new tierlist
      final tierlistData = {
        'S': [movie],
        'A': [],
        'B': [],
        'C': [],
        'D': [],
        'E': [],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await http.put(
        Uri.parse('$firebaseUrl/users/${currentUser.uid}/tierlists/$tierlistName.json?auth=$idToken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(tierlistData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Tierlist created successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create tierlist: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Tierlist creation error: ${e.toString()}',
      };
    }
  }

  // Update tierlist
  Future<Map<String, dynamic>> updateTierlist(String tierlistName, Map<String, List<dynamic>> tierData) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      // Add timestamp
      final updateData = Map<String, dynamic>.from(tierData);
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _makeRequest('PATCH', '$firebaseUrl/users/${currentUser.uid}/tierlists/$tierlistName.json',
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Tierlist updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update tierlist: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Tierlist update error: ${e.toString()}',
      };
    }
  }

  // Delete tierlist
  Future<Map<String, dynamic>> deleteTierlist(String tierlistName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      final response = await _makeRequest('DELETE', '$firebaseUrl/users/${currentUser.uid}/tierlists/$tierlistName.json');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Tierlist deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete tierlist: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Tierlist deletion error: ${e.toString()}',
      };
    }
  }

  // ------ User Settings Management ------ //

  // Save user settings
  Future<Map<String, dynamic>> saveUserSettings(Map<String, dynamic> settings) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
      };
    }

    try {
      // Add timestamp
      settings['updated_at'] = DateTime.now().toIso8601String();

      final response = await _makeRequest('PATCH', '$firebaseUrl/users/${currentUser.uid}/settings.json',
        body: json.encode(settings),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Settings saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to save settings: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Settings save error: ${e.toString()}',
      };
    }
  }

  // Get user settings
  Future<Map<String, dynamic>> getUserSettings() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'User not logged in',
        'settings': {},
      };
    }

    try {
      final response = await _makeRequest('GET', '$firebaseUrl/users/${currentUser.uid}/settings.json');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) ?? {};
        return {
          'success': true,
          'settings': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get settings: ${response.statusCode}',
          'settings': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Settings fetch error: ${e.toString()}',
        'settings': {},
      };
    }
  }
}