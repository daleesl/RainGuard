import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  const StorageService._();

  static const int _maxImageDimension = 1600;
  static const int _compressionQuality = 76;

  static Future<List<String>> uploadReportImages(List<XFile> images) async {
    final urls = <String>[];

    for (final image in images) {
      urls.add(await uploadReportImage(image));
    }

    return urls;
  }

  static Future<String> uploadReportImage(XFile image) async {
    return _uploadImage(image, 'reports');
  }

  static Future<String> uploadVerificationImage({
    required XFile image,
    required String uid,
    required String type,
  }) async {
    return _uploadImage(image, 'users/$uid/verification/$type');
  }

  static Future<String> _uploadImage(XFile image, String folderPath) async {
    try {
      final payload = await _prepareUploadPayload(image);
      final cleanName = payload.fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9\.]'),
        '_',
      );
      final path =
          '$folderPath/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
      final fileRef = FirebaseStorage.instance.ref().child(path);
      final metadata = SettableMetadata(
        contentType: payload.contentType,
      );

      final TaskSnapshot snapshot;
      if (payload.bytes != null) {
        snapshot = await fileRef.putData(payload.bytes!, metadata);
      } else {
        snapshot = await fileRef.putFile(payload.file!, metadata);
      }

      return snapshot.ref.getDownloadURL();
    } catch (error) {
      debugPrint('Firebase Storage Upload Error: $error');
      final errorMessage = error.toString();
      if (errorMessage.contains('object-not-found')) {
        throw Exception(
          'Upload silently failed. Check Firebase Storage Rules (must allow read/write).',
        );
      }
      throw Exception('Failed to upload image: $error');
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
