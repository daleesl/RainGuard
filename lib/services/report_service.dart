import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

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
    List<XFile> images = const [],
    LatLng? manualLocation,
  }) async {
    final position = manualLocation == null
        ? await LocationService.getCurrentPosition()
        : null;
    final latitude = manualLocation?.latitude ?? position!.latitude;
    final longitude = manualLocation?.longitude ?? position!.longitude;
    final locationSource = manualLocation == null ? 'gps' : 'manual';
    final List<XFile> selectedImages;
    if (images.isNotEmpty) {
      selectedImages = images;
    } else if (image != null) {
      selectedImages = [image];
    } else {
      selectedImages = const <XFile>[];
    }

    final imageUrls = selectedImages.isNotEmpty
        ? await StorageService.uploadReportImages(selectedImages)
        : const <String>[];
    final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

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
      'latitude': latitude,
      'longitude': longitude,
      'location_source': locationSource,
      'report_type': type.name,
      'flood_level': type == ReportType.flood ? floodLevel : null,
      'risk_level': RiskLevel.risk.name,
      'description': description.trim(),
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'created_at': Timestamp.fromDate(DateTime.now()),
    };

    await FirebaseFirestore.instance.collection('reports').add(reportData);
  }
}
