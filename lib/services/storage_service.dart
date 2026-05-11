import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  const StorageService._();

  static Future<String> uploadReportImage(XFile image) async {
    final cleanName = image.name.replaceAll(RegExp(r'[^a-zA-Z0-9\.]'), '_');
    final path = 'reports/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    final fileRef = FirebaseStorage.instance.ref().child(path);

    try {
      final metadata = SettableMetadata(
        contentType: image.mimeType ?? 'image/jpeg',
      );

      final TaskSnapshot snapshot;
      if (!kIsWeb && image.path.isNotEmpty) {
        snapshot = await fileRef.putFile(File(image.path), metadata);
      } else {
        final bytes = await image.readAsBytes();
        snapshot = await fileRef.putData(bytes, metadata);
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
}
