import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/report_draft.dart';
import '../models/report_model.dart';
import 'report_draft_service.dart';
import 'location_service.dart';
import 'storage_service.dart';
import 'user_profile_service.dart';

class ReportSavedAsDraftException implements Exception {
  const ReportSavedAsDraftException(this.originalError);

  final Object originalError;

  @override
  String toString() => 'Report saved as draft: $originalError';
}

class ReportService {
  const ReportService._();

  static Timer? _draftRetryTimer;

  static void startPendingDraftRetry() {
    if (_draftRetryTimer != null) return;

    unawaited(submitPendingDrafts());
    _draftRetryTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(submitPendingDrafts());
    });
  }

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

    final draft = ReportDraft(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      floodLevel: floodLevel,
      description: description.trim(),
      latitude: latitude,
      longitude: longitude,
      locationSource: locationSource,
      imagePaths: selectedImages
          .map((image) => image.path)
          .where((path) => path.isNotEmpty)
          .toList(),
      createdAt: DateTime.now(),
    );

    try {
      await _submitPreparedReport(
        type: type,
        description: description,
        floodLevel: floodLevel,
        selectedImages: selectedImages,
        latitude: latitude,
        longitude: longitude,
        locationSource: locationSource,
        createdAt: DateTime.now(),
      );
    } catch (error) {
      await ReportDraftService.saveDraft(draft);
      throw ReportSavedAsDraftException(error);
    }
  }

  static Future<int> submitPendingDrafts() async {
    final drafts = await ReportDraftService.getPendingDrafts();
    var submittedCount = 0;

    for (final draft in drafts) {
      try {
        final images = draft.imagePaths.map((path) => XFile(path)).toList();
        await _submitPreparedReport(
          type: draft.type,
          description: draft.description,
          floodLevel: draft.floodLevel,
          selectedImages: images,
          latitude: draft.latitude,
          longitude: draft.longitude,
          locationSource: draft.locationSource,
          createdAt: draft.createdAt,
        );
        await ReportDraftService.removeDraft(draft.id);
        submittedCount += 1;
      } catch (_) {
        break;
      }
    }

    return submittedCount;
  }

  static Future<void> _submitPreparedReport({
    required ReportType type,
    required String description,
    required List<XFile> selectedImages,
    required double latitude,
    required double longitude,
    required String locationSource,
    required DateTime createdAt,
    String? floodLevel,
  }) async {
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
      'created_at': Timestamp.fromDate(createdAt),
    };

    await FirebaseFirestore.instance.collection('reports').add(reportData);
  }
}
