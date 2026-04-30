import 'package:cloud_firestore/cloud_firestore.dart';

enum RiskLevel { safe, risk, flood }

enum ReportType { rain, wind, brownout, flood }

class Report {
  final String id;
  final double latitude;
  final double longitude;
  final ReportType type;
  final RiskLevel risk;
  final String description;
  final String? imageUrl;
  final String? floodLevel;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.risk,
    required this.description,
    this.imageUrl,
    this.floodLevel,
    required this.createdAt,
  });

  factory Report.fromFirestore(Map<String, dynamic> data, String id) {
    return Report(
      id: id,
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      type: _parseReportType(data['report_type']),
      risk: _parseRiskLevel(data['risk_level']),
      description: data['description'] ?? '',
      imageUrl: data['image_url'],
      floodLevel: data['flood_level'],
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  static ReportType _parseReportType(String? typeStr) {
    switch (typeStr?.toLowerCase()) {
      case 'rain':
        return ReportType.rain;
      case 'wind':
        return ReportType.wind;
      case 'brownout':
        return ReportType.brownout;
      case 'flood':
      default:
        return ReportType.flood;
    }
  }

  static RiskLevel _parseRiskLevel(String? riskStr) {
    switch (riskStr?.toLowerCase()) {
      case 'safe':
        return RiskLevel.safe;
      case 'risk':
        return RiskLevel.risk;
      case 'flood':
      default:
        return RiskLevel.flood;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'report_type': type.name,
      'risk_level': risk.name,
      'description': description,
      'image_url': imageUrl,
      'flood_level': floodLevel,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
