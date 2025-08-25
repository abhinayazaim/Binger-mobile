class User {
  final String id;
  final String email;
  final String username;
  final String createdAt;
  final List<String> watchlist;
  final Map<String, dynamic> tierLists;
  
  User({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
    required this.watchlist,
    required this.tierLists,
  });
  
  factory User.fromJson(String userId, Map<String, dynamic> json) {
    return User(
      id: userId,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      watchlist: json['watchlist'] != null 
          ? List<String>.from(json['watchlist']) 
          : [],
      tierLists: json['tierLists'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'created_at': createdAt,
      'watchlist': watchlist,
      'tierLists': tierLists,
    };
  }
  
  bool isMovieInWatchlist(String movieId) {
    return watchlist.contains(movieId);
  }
}