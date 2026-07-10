import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

class WeatherService {
  static const String _functionsRegion = 'us-central1';
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

    final url = _weatherFunctionUri(lat, lon);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final weather = _weatherFromFunctionResponse(data);

        await prefs.setDouble(_cacheKeyTemp, weather['temp'] as double);
        await prefs.setString(
          _cacheKeyDesc,
          weather['description'] as String,
        );
        await prefs.setString(_cacheKeyName, weather['location'] as String);
        await prefs.setString(_cacheKeyTime, DateTime.now().toIso8601String());

        return weather;
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

  static Uri _weatherFunctionUri(double lat, double lon) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;

    return Uri.https(
      '$_functionsRegion-$projectId.cloudfunctions.net',
      'getWeather',
      {
        'lat': lat.toStringAsFixed(6),
        'lon': lon.toStringAsFixed(6),
      },
    );
  }

  static Map<String, dynamic> _weatherFromFunctionResponse(
    Map<String, dynamic> data,
  ) {
    final temp = data['temp'];
    final description = data['description'];
    final location = data['location'];

    if (temp is! num) {
      throw const FormatException('Weather response is missing temperature.');
    }

    return {
      'temp': temp.toDouble(),
      'description': description is String ? description : 'Unknown',
      'location': location is String ? location : 'Unknown Location',
    };
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
