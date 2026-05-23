import 'dart:async';
import 'dart:math' as math;

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

class DuplicateReportException implements Exception {
  const DuplicateReportException(this.duplicate);

  final Report duplicate;
}

class ReportVerificationRequiredException implements Exception {
  const ReportVerificationRequiredException(this.status);

  final String status;

  @override
  String toString() => 'Identity verification required: $status';
}

class ReportService {
  const ReportService._();

  static const Duration _duplicateWindow = Duration(minutes: 15);
  static const Duration _duplicateCheckTimeout = Duration(seconds: 5);
  static const Duration _submitTimeout = Duration(seconds: 12);
  static const double _duplicateRadiusMeters = 250;

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
    bool skipDuplicateCheck = false,
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

    final draftId = DateTime.now().microsecondsSinceEpoch.toString();
    final createdAt = DateTime.now();

    if (!skipDuplicateCheck) {
      final duplicate =
          await _findRecentDuplicateReport(
            type: type,
            latitude: latitude,
            longitude: longitude,
          ).timeout(
            _duplicateCheckTimeout,
            onTimeout: () => null,
          );
      if (duplicate != null) {
        throw DuplicateReportException(duplicate);
      }
    }

    try {
      await _submitPreparedReport(
        type: type,
        description: description,
        floodLevel: floodLevel,
        selectedImages: selectedImages,
        latitude: latitude,
        longitude: longitude,
        locationSource: locationSource,
        createdAt: createdAt,
      ).timeout(_submitTimeout);
    } catch (error) {
      if (error is ReportVerificationRequiredException) {
        rethrow;
      }

      final draftImagePaths = await ReportDraftService.copyImagesForDraft(
        draftId: draftId,
        images: selectedImages,
      );
      final draft = ReportDraft(
        id: draftId,
        type: type,
        floodLevel: floodLevel,
        description: description.trim(),
        latitude: latitude,
        longitude: longitude,
        locationSource: locationSource,
        imagePaths: draftImagePaths,
        createdAt: createdAt,
      );

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
        ).timeout(_submitTimeout);
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final userProfile = await UserProfileService.getCurrentUserProfile();

    if (currentUser == null || userProfile?.verificationStatus != 'verified') {
      throw ReportVerificationRequiredException(
        userProfile?.verificationStatus ?? 'unverified',
      );
    }

    final imageUrls = selectedImages.isNotEmpty
        ? await StorageService.uploadReportImages(selectedImages)
        : const <String>[];
    final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    final userId = currentUser.uid;
    final reporterName =
        userProfile?.publicReporterName ??
        currentUser.displayName ??
        'Anonymous';
    final reporterDisplayName =
        userProfile?.displayName ?? currentUser.displayName ?? 'Anonymous';

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

  static Future<Report?> _findRecentDuplicateReport({
    required ReportType type,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final cutoff = Timestamp.fromDate(DateTime.now().subtract(_duplicateWindow));
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('created_at', isGreaterThan: cutoff)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      for (final doc in snapshot.docs) {
        final report = Report.fromFirestore(doc.data(), doc.id);
        if (report.type != type) continue;

        final distance = _distanceMeters(
          latitude,
          longitude,
          report.latitude,
          report.longitude,
        );
        if (distance <= _duplicateRadiusMeters) {
          return report;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
