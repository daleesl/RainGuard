import 'package:latlong2/latlong.dart';

import 'report_model.dart';

class ReportDraft {
  const ReportDraft({
    required this.id,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.locationSource,
    required this.imagePaths,
    required this.createdAt,
    this.floodLevel,
    this.rainIntensity,
  });

  final String id;
  final ReportType type;
  final String description;
  final double latitude;
  final double longitude;
  final String locationSource;
  final List<String> imagePaths;
  final DateTime createdAt;
  final String? floodLevel;
  final String? rainIntensity;

  LatLng get point => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_source': locationSource,
      'image_paths': imagePaths,
      'created_at': createdAt.toIso8601String(),
      'flood_level': floodLevel,
      'rain_intensity': rainIntensity,
    };
  }

  factory ReportDraft.fromJson(Map<String, dynamic> json) {
    return ReportDraft(
      id: json['id']?.toString() ?? '',
      type: _parseReportType(json['type']?.toString()),
      description: json['description']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      locationSource: json['location_source']?.toString() ?? 'gps',
      imagePaths: (json['image_paths'] as List<dynamic>? ?? const [])
          .map((path) => path.toString())
          .where((path) => path.isNotEmpty)
          .toList(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      floodLevel: json['flood_level']?.toString(),
      rainIntensity: json['rain_intensity']?.toString(),
    );
  }

  static ReportType _parseReportType(String? value) {
    return ReportType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ReportType.rain,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
