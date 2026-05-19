import 'package:cloud_firestore/cloud_firestore.dart';

enum RiskLevel { safe, risk, flood }

enum ReportType { rain, flood }

enum ReportFreshness { active, recent, archived }

class Report {
  final String id;
  final double latitude;
  final double longitude;
  final ReportType type;
  final RiskLevel risk;
  final String description;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? floodLevel;
  final String? userId;
  final String? reporterName;
  final String? reporterDisplayName;
  final String locationSource;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.risk,
    required this.description,
    this.imageUrl,
    this.imageUrls = const [],
    this.floodLevel,
    this.userId,
    this.reporterName,
    this.reporterDisplayName,
    this.locationSource = 'gps',
    required this.createdAt,
  });

  factory Report.fromFirestore(Map<String, dynamic> data, String id) {
    final imageUrls = _parseImageUrls(data);

    return Report(
      id: id,
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      type: _parseReportType(data['report_type']),
      risk: _parseRiskLevel(data['risk_level']),
      description: data['description'] ?? '',
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : data['image_url'],
      imageUrls: imageUrls,
      floodLevel: data['flood_level'],
      userId: data['user_id'],
      reporterName: data['reporter_name'],
      reporterDisplayName: data['reporter_display_name'],
      locationSource: _parseLocationSource(data['location_source']),
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  static List<String> _parseImageUrls(Map<String, dynamic> data) {
    final urls = <String>[];
    final rawUrls = data['image_urls'];

    if (rawUrls is Iterable) {
      for (final url in rawUrls) {
        if (url is String && url.trim().isNotEmpty) {
          urls.add(url.trim());
        }
      }
    }

    final legacyUrl = data['image_url'];
    if (legacyUrl is String &&
        legacyUrl.trim().isNotEmpty &&
        !urls.contains(legacyUrl.trim())) {
      urls.insert(0, legacyUrl.trim());
    }

    return urls;
  }

  static ReportType _parseReportType(String? typeStr) {
    switch (typeStr?.toLowerCase()) {
      case 'rain':
        return ReportType.rain;
      case 'flood':
      default:
        return ReportType.flood;
    }
  }

  static RiskLevel _parseRiskLevel(String? riskStr) {
    switch (riskStr?.toLowerCase()) {
      case 'safe':
        return RiskLevel.safe;
      case 'flood':
        return RiskLevel.flood;
      case 'risk':
      default:
        // Default to "risk" if missing or invalid, per requirements
        return RiskLevel.risk;
    }
  }

  static String _parseLocationSource(dynamic source) {
    if (source is String && source.trim().toLowerCase() == 'manual') {
      return 'manual';
    }
    return 'gps';
  }

  bool get isManualLocation => locationSource == 'manual';

  String get locationSourceLabel {
    return isManualLocation ? 'Manually selected' : 'Device GPS';
  }

  List<String> get allImageUrls {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return [imageUrl!.trim()];
    }
    return const [];
  }

  Duration get age {
    final difference = DateTime.now().difference(createdAt);
    return difference.isNegative ? Duration.zero : difference;
  }

  ReportFreshness get freshness {
    final reportAge = age;
    if (reportAge < const Duration(hours: 6)) {
      return ReportFreshness.active;
    }
    if (reportAge < const Duration(hours: 24)) {
      return ReportFreshness.recent;
    }
    return ReportFreshness.archived;
  }

  bool get isArchived => freshness == ReportFreshness.archived;

  Map<String, dynamic> toFirestore() {
    final urls = allImageUrls;

    return {
      'latitude': latitude,
      'longitude': longitude,
      'report_type': type.name,
      'risk_level': risk.name,
      'description': description,
      'image_url': urls.isNotEmpty ? urls.first : null,
      'image_urls': urls,
      'flood_level': floodLevel,
      'user_id': userId,
      'reporter_name': reporterName,
      'reporter_display_name': reporterDisplayName,
      'location_source': locationSource,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
