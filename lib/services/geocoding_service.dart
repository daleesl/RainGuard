import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeocodingService {
  static const String _cacheKeyName = 'cached_geocode_name';
  static const String _cacheKeyTime = 'cached_geocode_time';

  /// Reverse geocoding: get exact barangay/suburb from lat/lon using Nominatim (Free, No Card)
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Check cached timestamp to prevent rate-limiting
    final cachedTimeStr = prefs.getString(_cacheKeyTime);
    if (cachedTimeStr != null) {
      final cachedTime = DateTime.parse(cachedTimeStr);
      final difference = DateTime.now().difference(cachedTime);

      // If within 1 hour, return cached address to save requests
      if (difference.inMinutes < 60) {
        return prefs.getString(_cacheKeyName) ?? 'Unknown Location';
      }
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=jsonv2&addressdetails=1&accept-language=en',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'RainGuardApp/1.0 (student-capstone)', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};

        // Priority picking for granular location (e.g. Barangay)
        final localName =
            address['suburb'] ??
            address['village'] ??
            address['neighbourhood'] ??
            address['hamlet'] ??
            address['town'] ??
            address['city'] ??
            address['county'] ??
            'Unknown Location';

        final cityOrProvince = address['city'] ?? address['state'] ?? '';

        String finalAddress = localName;
        // Don't repeat if localName is the same as city
        if (cityOrProvince.isNotEmpty && localName != cityOrProvince) {
          finalAddress = '$localName, $cityOrProvince';
        }

        // Cache the successful address
        await prefs.setString(_cacheKeyName, finalAddress);
        await prefs.setString(_cacheKeyTime, DateTime.now().toIso8601String());

        return finalAddress;
      }
    } catch (e) {
      // On error, if cache exists fallback to cache regardless of age
      if (cachedTimeStr != null) {
        return prefs.getString(_cacheKeyName) ?? 'Unknown Location';
      }
    }
    return 'Location Error';
  }
}
