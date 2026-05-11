import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static const String _cacheKeyTemp = 'cached_temp';
  static const String _cacheKeyDesc = 'cached_desc';
  static const String _cacheKeyTime = 'cached_time';
  static const String _cacheKeyName = 'cached_name';

  /// Fetches weather for a given position. Uses 15-minute caching mechanism.
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();

    // Check cached timestamp
    final cachedTimeStr = prefs.getString(_cacheKeyTime);
    if (cachedTimeStr != null) {
      final cachedTime = DateTime.parse(cachedTimeStr);
      final difference = DateTime.now().difference(cachedTime);

      // If within 15 minutes, return cached data
      if (difference.inMinutes < 15) {
        return {
          'temp': prefs.getDouble(_cacheKeyTemp) ?? 0.0,
          'description': prefs.getString(_cacheKeyDesc) ?? 'Unknown',
          'location': prefs.getString(_cacheKeyName) ?? 'Unknown Location',
        };
      }
    }

    // Cache expired or empty, fetch new data from OpenWeather API
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final double temp = (data['main']['temp'] as num).toDouble();
        final String description = data['weather'][0]['main']
            .toString(); // e.g. Clouds, Rain
        final String locationName = data['name']
            .toString(); // City name from OpenWeather

        // Save to cache
        await prefs.setDouble(_cacheKeyTemp, temp);
        await prefs.setString(_cacheKeyDesc, description);
        await prefs.setString(_cacheKeyName, locationName);
        await prefs.setString(_cacheKeyTime, DateTime.now().toIso8601String());

        return {
          'temp': temp,
          'description': description,
          'location': locationName,
        };
      } else {
        throw Exception('Failed to load weather data: ${response.body}');
      }
    } catch (e) {
      // On error, if cache exists fallback to cache regardless of age
      if (cachedTimeStr != null) {
        return {
          'temp': prefs.getDouble(_cacheKeyTemp) ?? 0.0,
          'description': prefs.getString(_cacheKeyDesc) ?? 'Unknown',
          'location': prefs.getString(_cacheKeyName) ?? 'Unknown Location',
        };
      }
      rethrow;
    }
  }
}
