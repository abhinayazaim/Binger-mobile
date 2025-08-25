import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_model.dart';
import 'firebase_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';
  final FirebaseService _firebaseService = FirebaseService();
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  Future<bool> checkLoginStatus() async {
    try {
      final isLoggedIn = await _firebaseService.isUserLoggedIn();
      if (isLoggedIn) {
        final profileResult = await _firebaseService.getUserProfile();
        if (profileResult['success']) {
          _user = User.fromJson(
            _firebaseService.getCurrentUserId()!, 
            profileResult['profile']
          );
          notifyListeners();
        }
      }
      return isLoggedIn;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> signIn(String email, String password) async {
    try {
      setLoading(true);
      clearError();
      
      final result = await _firebaseService.signInUser(email, password);
      
      if (result['success']) {
        final userId = result['user_id'];
        final profile = await _firebaseService.getUserProfile();
        
        if (profile['success']) {
          _user = User.fromJson(userId, profile['profile']);
          setLoading(false);
          return true;
        } else {
          setError('Failed to load user profile');
          setLoading(false);
          return false;
        }
      } else {
        setError(result['message']);
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('An unexpected error occurred: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }
  
  Future<bool> signUp(String email, String password, String username) async {
    try {
      setLoading(true);
      clearError();
      
      final result = await _firebaseService.registerUser(email, password, username);
      
      if (result['success']) {
        final userId = result['user_id'];
        
        // Create a new user object
        _user = User(
          id: userId,
          email: email,
          username: username,
          createdAt: DateTime.now().toIso8601String(),
          watchlist: [],
          tierLists: {},
        );
        
        setLoading(false);
        return true;
      } else {
        setError(result['message']);
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('An unexpected error occurred: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }
  
  Future<bool> resetPassword(String email) async {
    try {
      setLoading(true);
      clearError();
      
      // Since Firebase Realtime Database doesn't have built-in password reset,
      // we'll simulate the functionality by checking if email exists
      final response = await http.get(
        Uri.parse('https://binger-32229-default-rtdb.asia-southeast1.firebasedatabase.app/'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        bool emailExists = false;
        
        if (data != null) {
          data.forEach((key, value) {
            if (value['email'] == email) {
              emailExists = true;
            }
          });
        }
        
        if (emailExists) {
          // In a real app, you would send an actual reset email here
          // For now, we'll just return success
          setLoading(false);
          return true;
        } else {
          setError('No account found with this email address');
          setLoading(false);
          return false;
        }
      } else {
        setError('Failed to verify email address');
        setLoading(false);
        return false;
      }
    } catch (e) {
      setError('An unexpected error occurred: ${e.toString()}');
      setLoading(false);
      return false;
    }
  }
  
  Future<void> signOut() async {
    await _firebaseService.signOutUser();
    _user = null;
    notifyListeners();
  }
  
  Future<void> updateWatchlist(String movieId, bool add) async {
    if (_user == null) return;
    
    try {
      // Get current watchlist
      List<String> updatedWatchlist = List.from(_user!.watchlist);
      
      if (add && !updatedWatchlist.contains(movieId)) {
        updatedWatchlist.add(movieId);
      } else if (!add && updatedWatchlist.contains(movieId)) {
        updatedWatchlist.remove(movieId);
      } else {
        return; // No change needed
      }
      
      // Update locally
      _user = User(
        id: _user!.id,
        email: _user!.email,
        username: _user!.username,
        createdAt: _user!.createdAt,
        watchlist: updatedWatchlist,
        tierLists: _user!.tierLists,
      );
      
      // Update in Firebase
      await _firebaseService.updateUserProfile({
        'watchlist': updatedWatchlist,
      });
      
      notifyListeners();
    } catch (e) {
      setError('Failed to update watchlist: ${e.toString()}');
    }
  }
  
  Future<void> updateTierList(String listId, Map<String, dynamic> tierData) async {
    if (_user == null) return;
    
    try {
      Map<String, dynamic> updatedTierLists = Map.from(_user!.tierLists);
      updatedTierLists[listId] = tierData;
      
      // Update locally
      _user = User(
        id: _user!.id,
        email: _user!.email,
        username: _user!.username,
        createdAt: _user!.createdAt,
        watchlist: _user!.watchlist,
        tierLists: updatedTierLists,
      );
      
      // Update in Firebase
      await _firebaseService.updateUserProfile({
        'tierLists': updatedTierLists,
      });
      
      notifyListeners();
    } catch (e) {
      setError('Failed to update tier list: ${e.toString()}');
    }
  }
  
  // Add method to create a new tier list
  Future<bool> createNewTierList(String name, Map<String, dynamic> initialMovie) async {
    if (_user == null) return false;
    
    try {
      final result = await _firebaseService.createTierlist(name, initialMovie);
      
      if (result['success']) {
        // Update local state
        await checkLoginStatus(); // Refresh user data
        notifyListeners();
        return true;
      } else {
        setError(result['message']);
        return false;
      }
    } catch (e) {
      setError('Failed to create tier list: ${e.toString()}');
      return false;
    }
  }
  
  // Add method to create a new playlist
  Future<bool> createNewPlaylist(String name, String label, Map<String, dynamic> initialMovie) async {
    if (_user == null) return false;
    
    try {
      final result = await _firebaseService.createPlaylist(name, label, initialMovie);
      
      if (result['success']) {
        // Update local state
        await checkLoginStatus(); // Refresh user data
        notifyListeners();
        return true;
      } else {
        setError(result['message']);
        return false;
      }
    } catch (e) {
      setError('Failed to create playlist: ${e.toString()}');
      return false;
    }
  }
  
  // Add method to get all playlists
  Future<Map<String, dynamic>> getPlaylists() async {
    if (_user == null) return {'success': false, 'message': 'User not logged in'};
    
    try {
      return await _firebaseService.getPlaylists();
    } catch (e) {
      setError('Failed to get playlists: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Add method to get all tier lists
  Future<Map<String, dynamic>> getTierLists() async {
    if (_user == null) return {'success': false, 'message': 'User not logged in'};
    
    try {
      return await _firebaseService.getTierlists();
    } catch (e) {
      setError('Failed to get tier lists: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Add method to save movie rating
  Future<bool> saveMovieRating(Map<String, dynamic> movie, double rating) async {
    if (_user == null) return false;
    
    try {
      final result = await _firebaseService.saveMovieRating(movie, rating);
      return result['success'];
    } catch (e) {
      setError('Failed to save rating: ${e.toString()}');
      return false;
    }
  }
  
  // Add method to get movie ratings
  Future<Map<String, dynamic>> getMovieRatings() async {
    if (_user == null) return {'success': false, 'message': 'User not logged in'};
    
    try {
      return await _firebaseService.getMovieRatings();
    } catch (e) {
      setError('Failed to get movie ratings: ${e.toString()}');
      return {'success': false, 'message': e.toString()};
    }
  }
}