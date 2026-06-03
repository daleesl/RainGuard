import 'package:latlong2/latlong.dart';

import 'geocoding_service.dart';
import 'location_service.dart';

class ReportSubmissionLocation {
  const ReportSubmissionLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final String source;
}

class ReportLocationResolver {
  const ReportLocationResolver._();

  static Future<ReportSubmissionLocation> resolveSubmissionLocation(
    LatLng? manualLocation,
  ) async {
    if (manualLocation != null) {
      return ReportSubmissionLocation(
        latitude: manualLocation.latitude,
        longitude: manualLocation.longitude,
        source: 'manual',
      );
    }

    final position = await LocationService.getCurrentPosition();
    return ReportSubmissionLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      source: 'gps',
    );
  }

  static Future<String?> resolveLocationName(
    double latitude,
    double longitude,
  ) async {
    try {
      final locationName = await GeocodingService.getAddressFromCoordinates(
        latitude,
        longitude,
      );
      return cleanLocationName(locationName);
    } catch (_) {
      return null;
    }
  }

  static String? cleanLocationName(String? locationName) {
    final cleanName = locationName?.trim();
    if (cleanName == null ||
        cleanName.isEmpty ||
        cleanName == 'Unknown Location' ||
        cleanName == 'Location Error') {
      return null;
    }

    return cleanName;
  }
}
