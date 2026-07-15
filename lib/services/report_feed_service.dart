import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/report_model.dart';

class ReportFeedService {
  const ReportFeedService._();

  static const int defaultMapReportLimit = 150;
  static const int defaultNotificationReportLimit = 75;

  static Stream<List<Report>> latestReportsStream({
    int limitCount = defaultMapReportLimit,
  }) {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('created_at', descending: true)
        .limit(limitCount)
        .snapshots()
        .map((snapshot) => parseReports(snapshot.docs));
  }

  static Stream<List<Report>> userReportsStream({
    required String userId,
    int limitCount = defaultNotificationReportLimit,
  }) {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) return Stream.value(const <Report>[]);

    return FirebaseFirestore.instance
        .collection('reports')
        .where('user_id', isEqualTo: cleanUserId)
        .limit(limitCount)
        .snapshots()
        .map((snapshot) {
          final reports = parseReports(snapshot.docs);
          reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reports;
        });
  }

  static Stream<List<Report>> activeMapReportsStream({
    int limitCount = defaultMapReportLimit,
  }) {
    return latestReportsStream(limitCount: limitCount).map(
      (reports) => reports.where((report) => report.isActiveOnMap).toList(),
    );
  }

  static List<Report> parseReports(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final reports = <Report>[];

    for (final doc in docs) {
      try {
        reports.add(Report.fromFirestore(doc.data(), doc.id));
      } catch (error) {
        debugPrint('Error parsing report ${doc.id}: $error');
      }
    }

    return reports;
  }
}
