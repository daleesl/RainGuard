import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  const StorageService._();

  static const int _maxImageDimension = 1600;
  static const int _compressionQuality = 76;
  static const int _maxParallelReportUploads = 2;
  static const int _uploadRetryCount = 1;
  static const Duration _uploadTimeout = Duration(seconds: 45);

  static Future<List<String>> uploadReportImages(
    List<XFile> images, {
    required String reportId,
  }) async {
    if (images.isEmpty) return const <String>[];

    final urls = <String>[];
    var index = 0;
    while (index < images.length) {
      final batch = images
          .skip(index)
          .take(_maxParallelReportUploads)
          .toList();
      final batchUrls = await Future.wait(
        List.generate(
          batch.length,
          (batchIndex) => uploadReportImage(
            batch[batchIndex],
            reportId: reportId,
            imageIndex: index + batchIndex,
          ),
        ),
      );
      urls.addAll(batchUrls);
      index += _maxParallelReportUploads;
    }

    return urls;
  }

  static Future<String> uploadReportImage(
    XFile image, {
    required String reportId,
    required int imageIndex,
  }) async {
    final path = reportImagePath(reportId, imageIndex);
    final existingUrl = await _existingDownloadUrl(path);
    if (existingUrl != null) return existingUrl;

    return _uploadImageWithRetry(
      image,
      'reports/${_safePathSegment(reportId)}',
      objectName: 'image-$imageIndex',
    );
  }

  static Future<String> uploadVerificationImage({
    required XFile image,
    required String uid,
    required String type,
  }) async {
    return _uploadImageWithRetry(image, 'users/$uid/verification/$type');
  }

  static Future<String> _uploadImageWithRetry(
    XFile image,
    String folderPath, {
    String? objectName,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt <= _uploadRetryCount; attempt += 1) {
      try {
        return await _uploadImage(
          image,
          folderPath,
          objectName: objectName,
        ).timeout(_uploadTimeout);
      } catch (error) {
        lastError = error;
        if (!_shouldRetryUpload(error) || attempt == _uploadRetryCount) {
          break;
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    throw Exception(_friendlyUploadError(lastError));
  }

  static Future<String> _uploadImage(
    XFile image,
    String folderPath, {
    String? objectName,
  }) async {
    final payload = await _prepareUploadPayload(image);
    final cleanName = objectName == null
        ? '${DateTime.now().millisecondsSinceEpoch}_${_safePathSegment(payload.fileName)}'
        : _safePathSegment(objectName);
    final path = '$folderPath/$cleanName';
    final fileRef = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(contentType: payload.contentType);

    final TaskSnapshot snapshot;
    if (payload.bytes != null) {
      snapshot = await fileRef.putData(payload.bytes!, metadata);
    } else {
      snapshot = await fileRef.putFile(payload.file!, metadata);
    }

    return snapshot.ref.getDownloadURL();
  }

  @visibleForTesting
  static String reportImagePath(String reportId, int imageIndex) {
    return 'reports/${_safePathSegment(reportId)}/image-$imageIndex';
  }

  static Future<String?> _existingDownloadUrl(String path) async {
    try {
      return await FirebaseStorage.instance.ref().child(path).getDownloadURL();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return null;
      rethrow;
    }
  }

  static Future<_UploadPayload> _prepareUploadPayload(XFile image) async {
    if (!kIsWeb && image.path.isNotEmpty) {
      final compressed = await _compressReportImage(image.path);

      if (compressed != null && compressed.isNotEmpty) {
        return _UploadPayload.bytes(
          bytes: compressed,
          fileName: _jpegFileName(image.name),
          contentType: 'image/jpeg',
        );
      }

      return _UploadPayload.file(
        file: File(image.path),
        fileName: image.name,
        contentType: image.mimeType ?? 'image/jpeg',
      );
    }

    return _UploadPayload.bytes(
      bytes: await image.readAsBytes(),
      fileName: image.name,
      contentType: image.mimeType ?? 'image/jpeg',
    );
  }

  static Future<Uint8List?> _compressReportImage(String path) async {
    try {
      return FlutterImageCompress.compressWithFile(
        path,
        minWidth: _maxImageDimension,
        minHeight: _maxImageDimension,
        quality: _compressionQuality,
        format: CompressFormat.jpeg,
      );
    } catch (error) {
      debugPrint('Image compression skipped: $error');
      return null;
    }
  }

  static String _jpegFileName(String name) {
    final baseName = name.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return '$baseName.jpg';
  }

  static String _safePathSegment(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return cleanValue.isEmpty ? 'upload' : cleanValue;
  }

  static bool _shouldRetryUpload(Object error) {
    if (error is TimeoutException) return true;
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'retry-limit-exceeded' ||
          error.code == 'unknown';
    }

    final message = error.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('network') ||
        message.contains('unavailable');
  }

  static String _friendlyUploadError(Object? error) {
    debugPrint('Firebase Storage Upload Error: $error');
    if (error == null) {
      return 'Failed to upload image. Please try again.';
    }

    if (error is TimeoutException) {
      return 'Image upload timed out. Check your connection and try again.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'unauthorized':
        case 'permission-denied':
          return 'Image upload was blocked by Firebase Storage rules.';
        case 'canceled':
          return 'Image upload was cancelled. Please try again.';
        case 'object-not-found':
          return 'Upload failed. Check Firebase Storage configuration.';
        case 'quota-exceeded':
          return 'Firebase Storage quota was reached. Try again later.';
        case 'unavailable':
        case 'retry-limit-exceeded':
          return 'Image upload failed because the connection is unstable.';
      }
    }

    return 'Failed to upload image: $error';
  }
}

class _UploadPayload {
  const _UploadPayload._({
    required this.fileName,
    required this.contentType,
    this.bytes,
    this.file,
  });

  factory _UploadPayload.bytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) {
    return _UploadPayload._(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  factory _UploadPayload.file({
    required File file,
    required String fileName,
    required String contentType,
  }) {
    return _UploadPayload._(
      file: file,
      fileName: fileName,
      contentType: contentType,
    );
  }

  final Uint8List? bytes;
  final File? file;
  final String fileName;
  final String contentType;
}
