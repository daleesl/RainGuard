import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyAlert {
  const SafetyAlert({
    required this.area,
    required this.id,
    required this.message,
    required this.publishedAt,
    required this.riskLevel,
    required this.status,
    required this.title,
  });

  final String area;
  final String id;
  final String message;
  final DateTime publishedAt;
  final String riskLevel;
  final String status;
  final String title;

  factory SafetyAlert.fromFirestore(Map<String, dynamic> data, String id) {
    return SafetyAlert(
      area: data['area'] as String? ?? 'All residents',
      id: id,
      message: data['message'] as String? ?? '',
      publishedAt: _readDate(
        data['published_at'],
        fallback: data['created_at'],
      ),
      riskLevel: data['risk_level'] as String? ?? 'info',
      status: normalizeStatus(data['status']),
      title: data['title'] as String? ?? 'RainGuard advisory',
    );
  }

  bool get isPublished => status == 'published';

  static DateTime _readDate(Object? value, {Object? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (fallback is Timestamp) return fallback.toDate();
    if (fallback is DateTime) return fallback;
    return DateTime.now();
  }

  static String normalizeStatus(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim().toLowerCase();
    }
    return 'draft';
  }
}
