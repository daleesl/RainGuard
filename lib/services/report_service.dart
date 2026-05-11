import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report_model.dart';
import 'location_service.dart';
import 'storage_service.dart';
import 'user_profile_service.dart';

class ReportService {
  const ReportService._();

  static Future<void> submitCommunityReport({
    required ReportType type,
    required String description,
    String? floodLevel,
    XFile? image,
  }) async {
    final position = await LocationService.getCurrentPosition();
    final imageUrl = image != null
        ? await StorageService.uploadReportImage(image)
        : null;

    final currentUser = FirebaseAuth.instance.currentUser;
    final userProfile = await UserProfileService.getCurrentUserProfile();
    final userId = currentUser?.uid ?? 'anonymous';
    final reporterName =
        userProfile?.publicReporterName ??
        currentUser?.displayName ??
        'Anonymous';
    final reporterDisplayName =
        userProfile?.displayName ?? currentUser?.displayName ?? 'Anonymous';

    final reportData = {
      'user_id': userId,
      'reporter_name': reporterName,
      'reporter_display_name': reporterDisplayName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'report_type': type.name,
      'flood_level': type == ReportType.flood ? floodLevel : null,
      'risk_level': RiskLevel.risk.name,
      'description': description.trim(),
      'image_url': imageUrl,
      'created_at': Timestamp.fromDate(DateTime.now()),
    };

    await FirebaseFirestore.instance.collection('reports').add(reportData);
  }
}
