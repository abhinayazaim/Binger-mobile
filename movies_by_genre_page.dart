import 'dart:convert';
import 'package:http/http.dart' as http;

class GenreService {
  final String _apiKey = 'd54c8ae5d997772ae7a6879e252e6785';
  final String _baseUrl = 'https://api.themoviedb.org/3';

  Future<Map<String, int>> fetchGenres() async {
    final url = Uri.parse('$_baseUrl/genre/movie/list?api_key=$_apiKey&language=en-US');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List genres = data['genres'];

        // Convert to Map<String, int>
        final Map<String, int> genreMap = {
          for (var genre in genres) genre['name']: genre['id']
        };

        return genreMap;
      } else {
        throw Exception('Failed to load genres. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching genres: $e');
      return {};
    }
  }
}
