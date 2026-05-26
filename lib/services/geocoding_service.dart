import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeocodingService {
  static const String _cacheKeyEntries = 'cached_geocode_entries';
  static const String _cacheKeyName = 'cached_geocode_name';
  static const String _cacheKeyTime = 'cached_geocode_time';
  static const Duration _cacheTtl = Duration(hours: 1);

  static Future<String> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _coordinateCacheKey(lat, lon);
    final cachedAddress = _readCachedAddress(prefs, cacheKey);

    if (cachedAddress != null) {
      return cachedAddress;
    }

    final url = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'en',
      },
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RainGuardApp/1.0 (student-capstone)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final localName =
            (address['suburb'] ??
                    address['village'] ??
                    address['neighbourhood'] ??
                    address['hamlet'] ??
                    address['town'] ??
                    address['city'] ??
                    address['county'] ??
                    'Unknown Location')
                .toString();

        final cityOrProvince =
            (address['city'] ?? address['state'] ?? '').toString();

        var finalAddress = localName;
        if (cityOrProvince.isNotEmpty && localName != cityOrProvince) {
          finalAddress = '$localName, $cityOrProvince';
        }

        await _writeCachedAddress(prefs, cacheKey, finalAddress);

        return finalAddress;
      }
    } catch (e) {
      return _readCachedAddress(prefs, cacheKey, ignoreExpiry: true) ??
          _readLegacyCachedAddress(prefs, ignoreExpiry: true) ??
          'Location Error';
    }

    return 'Location Error';
  }

  static String _coordinateCacheKey(double lat, double lon) {
    return '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
  }

  static String? _readCachedAddress(
    SharedPreferences prefs,
    String cacheKey, {
    bool ignoreExpiry = false,
  }) {
    final rawEntries = prefs.getString(_cacheKeyEntries);
    if (rawEntries == null) {
      return null;
    }

    try {
      final entries = json.decode(rawEntries) as Map<String, dynamic>;
      final entry = entries[cacheKey] as Map<String, dynamic>?;
      if (entry == null) return null;

      final name = entry['name'] as String?;
      final cachedAt = DateTime.tryParse(entry['cached_at'] as String? ?? '');
      if (name == null || cachedAt == null) return null;

      if (!ignoreExpiry && DateTime.now().difference(cachedAt) > _cacheTtl) {
        return null;
      }

      return name;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCachedAddress(
    SharedPreferences prefs,
    String cacheKey,
    String address,
  ) async {
    final rawEntries = prefs.getString(_cacheKeyEntries);
    final entries = <String, dynamic>{};

    if (rawEntries != null) {
      try {
        entries.addAll(json.decode(rawEntries) as Map<String, dynamic>);
      } catch (_) {
        entries.clear();
      }
    }

    entries[cacheKey] = {
      'name': address,
      'cached_at': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_cacheKeyEntries, json.encode(entries));
    await prefs.setString(_cacheKeyName, address);
    await prefs.setString(_cacheKeyTime, DateTime.now().toIso8601String());
  }

  static String? _readLegacyCachedAddress(
    SharedPreferences prefs, {
    bool ignoreExpiry = false,
  }) {
    final cachedName = prefs.getString(_cacheKeyName);
    final cachedTimeStr = prefs.getString(_cacheKeyTime);

    if (cachedName == null || cachedTimeStr == null) return null;

    final cachedTime = DateTime.tryParse(cachedTimeStr);
    if (cachedTime == null) return null;

    if (!ignoreExpiry && DateTime.now().difference(cachedTime) > _cacheTtl) {
      return null;
    }

    return cachedName;
  }
}
