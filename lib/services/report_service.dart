import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/report_draft.dart';
import '../models/report_model.dart';
import 'geocoding_service.dart';
import 'location_service.dart';
import 'report_draft_service.dart';
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
  static const Duration _submitTimeoutPerImage = Duration(seconds: 8);
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
    final request = await _prepareReportRequest(
      type: type,
      description: description,
      floodLevel: floodLevel,
      image: image,
      images: images,
      manualLocation: manualLocation,
    );

    if (!skipDuplicateCheck) {
      await _ensureNoRecentDuplicate(request);
    }

    try {
      await _submitPreparedReport(request).timeout(
        _submitTimeoutFor(request.selectedImages.length),
      );
    } catch (error) {
      if (error is ReportVerificationRequiredException) {
        rethrow;
      }

      await _saveReportDraft(request);
      throw ReportSavedAsDraftException(error);
    }
  }

  static Future<int> submitPendingDrafts() async {
    final drafts = await ReportDraftService.getPendingDrafts();
    var submittedCount = 0;

    for (final draft in drafts) {
      try {
        final request = _ReportRequest.fromDraft(draft);
        await _submitPreparedReport(request).timeout(
          _submitTimeoutFor(request.selectedImages.length),
        );
        await ReportDraftService.removeDraft(draft.id);
        submittedCount += 1;
      } catch (_) {
        break;
      }
    }

    return submittedCount;
  }

  static Future<_ReportRequest> _prepareReportRequest({
    required ReportType type,
    required String description,
    required String? floodLevel,
    required XFile? image,
    required List<XFile> images,
    required LatLng? manualLocation,
  }) async {
    final location = await _resolveSubmissionLocation(manualLocation);

    return _ReportRequest(
      draftId: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      floodLevel: floodLevel,
      description: description.trim(),
      location: location,
      selectedImages: _selectedImages(image: image, images: images),
      createdAt: DateTime.now(),
    );
  }

  static Future<_ReportLocation> _resolveSubmissionLocation(
    LatLng? manualLocation,
  ) async {
    if (manualLocation != null) {
      return _ReportLocation(
        latitude: manualLocation.latitude,
        longitude: manualLocation.longitude,
        source: 'manual',
      );
    }

    final position = await LocationService.getCurrentPosition();
    return _ReportLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      source: 'gps',
    );
  }

  static List<XFile> _selectedImages({
    required XFile? image,
    required List<XFile> images,
  }) {
    if (images.isNotEmpty) return images;
    if (image != null) return [image];
    return const <XFile>[];
  }

  static Future<void> _ensureNoRecentDuplicate(
    _ReportRequest request,
  ) async {
    final duplicate =
        await _findRecentDuplicateReport(
          type: request.type,
          latitude: request.location.latitude,
          longitude: request.location.longitude,
        ).timeout(
          _duplicateCheckTimeout,
          onTimeout: () => null,
        );

    if (duplicate != null) {
      throw DuplicateReportException(duplicate);
    }
  }

  static Future<void> _submitPreparedReport(_ReportRequest request) async {
    final reporter = await _verifiedReporter();
    final imageUrls = await _uploadReportImages(request.selectedImages);
    final locationName = await _resolveLocationName(
      request.location.latitude,
      request.location.longitude,
    );

    final reportData = _buildReportData(
      request: request,
      reporter: reporter,
      imageUrls: imageUrls,
      locationName: locationName,
    );

    await FirebaseFirestore.instance.collection('reports').add(reportData);
  }

  static Future<_VerifiedReporter> _verifiedReporter() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userProfile = await UserProfileService.getCurrentUserProfile();

    if (currentUser == null || userProfile?.verificationStatus != 'verified') {
      throw ReportVerificationRequiredException(
        userProfile?.verificationStatus ?? 'unverified',
      );
    }

    return _VerifiedReporter(
      userId: currentUser.uid,
      reporterName:
          userProfile?.publicReporterName ??
          currentUser.displayName ??
          'Anonymous',
      reporterDisplayName:
          userProfile?.displayName ?? currentUser.displayName ?? 'Anonymous',
    );
  }

  static Future<List<String>> _uploadReportImages(
    List<XFile> selectedImages,
  ) async {
    if (selectedImages.isEmpty) return const <String>[];
    return StorageService.uploadReportImages(selectedImages);
  }

  static Map<String, Object?> _buildReportData({
    required _ReportRequest request,
    required _VerifiedReporter reporter,
    required List<String> imageUrls,
    required String? locationName,
  }) {
    final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    return {
      'user_id': reporter.userId,
      'reporter_name': reporter.reporterName,
      'reporter_display_name': reporter.reporterDisplayName,
      'latitude': request.location.latitude,
      'longitude': request.location.longitude,
      'location_name': ?locationName,
      'location_source': request.location.source,
      'report_type': request.type.name,
      'flood_level': request.type == ReportType.flood
          ? request.floodLevel
          : null,
      'risk_level': RiskLevel.risk.name,
      'description': request.description,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'created_at': Timestamp.fromDate(request.createdAt),
    };
  }

  static Future<void> _saveReportDraft(_ReportRequest request) async {
    final draftImagePaths = await ReportDraftService.copyImagesForDraft(
      draftId: request.draftId,
      images: request.selectedImages,
    );
    final draft = ReportDraft(
      id: request.draftId,
      type: request.type,
      floodLevel: request.floodLevel,
      description: request.description,
      latitude: request.location.latitude,
      longitude: request.location.longitude,
      locationSource: request.location.source,
      imagePaths: draftImagePaths,
      createdAt: request.createdAt,
    );

    await ReportDraftService.saveDraft(draft);
  }

  static Future<Report?> _findRecentDuplicateReport({
    required ReportType type,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(_duplicateWindow),
      );
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

  static Future<String?> _resolveLocationName(
    double latitude,
    double longitude,
  ) async {
    try {
      final locationName = await GeocodingService.getAddressFromCoordinates(
        latitude,
        longitude,
      );
      final cleanName = locationName.trim();
      if (cleanName.isEmpty ||
          cleanName == 'Unknown Location' ||
          cleanName == 'Location Error') {
        return null;
      }

      return cleanName;
    } catch (_) {
      return null;
    }
  }

  static Duration _submitTimeoutFor(int imageCount) {
    final timeoutSeconds =
        _submitTimeout.inSeconds +
        (imageCount * _submitTimeoutPerImage.inSeconds);

    return Duration(seconds: timeoutSeconds);
  }
}

class _ReportRequest {
  const _ReportRequest({
    required this.draftId,
    required this.type,
    required this.floodLevel,
    required this.description,
    required this.location,
    required this.selectedImages,
    required this.createdAt,
  });

  factory _ReportRequest.fromDraft(ReportDraft draft) {
    return _ReportRequest(
      draftId: draft.id,
      type: draft.type,
      floodLevel: draft.floodLevel,
      description: draft.description,
      location: _ReportLocation(
        latitude: draft.latitude,
        longitude: draft.longitude,
        source: draft.locationSource,
      ),
      selectedImages: draft.imagePaths.map((path) => XFile(path)).toList(),
      createdAt: draft.createdAt,
    );
  }

  final String draftId;
  final ReportType type;
  final String? floodLevel;
  final String description;
  final _ReportLocation location;
  final List<XFile> selectedImages;
  final DateTime createdAt;
}

class _ReportLocation {
  const _ReportLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final String source;
}

class _VerifiedReporter {
  const _VerifiedReporter({
    required this.userId,
    required this.reporterName,
    required this.reporterDisplayName,
  });

  final String userId;
  final String reporterName;
  final String reporterDisplayName;
}
