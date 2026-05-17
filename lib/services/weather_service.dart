import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static const Duration _cacheDuration = Duration(minutes: 15);
  static const String _cacheKeyTemp = 'cached_temp';
  static const String _cacheKeyDesc = 'cached_desc';
  static const String _cacheKeyTime = 'cached_time';
  static const String _cacheKeyName = 'cached_name';

  /// Fetches weather for a given position. Uses 15-minute caching mechanism.
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();

    final cachedTimeStr = prefs.getString(_cacheKeyTime);
    final cachedTime = cachedTimeStr == null
        ? null
        : DateTime.tryParse(cachedTimeStr);

    if (cachedTime != null &&
        DateTime.now().difference(cachedTime) < _cacheDuration) {
      return _cachedWeatherFromPrefs(prefs);
    }

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final double temp = (data['main']['temp'] as num).toDouble();
        final String description = data['weather'][0]['main'].toString();
        final String locationName = data['name'].toString();

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
      if (cachedTime != null) {
        return _cachedWeatherFromPrefs(prefs);
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _cachedWeatherFromPrefs(
    SharedPreferences prefs,
  ) {
    return {
      'temp': prefs.getDouble(_cacheKeyTemp) ?? 0.0,
      'description': prefs.getString(_cacheKeyDesc) ?? 'Unknown',
      'location': prefs.getString(_cacheKeyName) ?? 'Unknown Location',
    };
  }
}
