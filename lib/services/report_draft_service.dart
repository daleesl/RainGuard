import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_draft.dart';

class ReportDraftService {
  const ReportDraftService._();

  static const String _draftsKey = 'pending_report_drafts';
  static const String _draftImageFolderName = 'report_draft_images';
  static final ValueNotifier<int> pendingDraftCount = ValueNotifier<int>(0);

  static Future<void> refreshPendingDraftCount() async {
    pendingDraftCount.value = await getPendingDraftCount();
  }

  static Future<List<ReportDraft>> getPendingDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedDrafts = prefs.getStringList(_draftsKey) ?? const [];

    return encodedDrafts
        .map((encodedDraft) {
          try {
            return ReportDraft.fromJson(
              jsonDecode(encodedDraft) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<ReportDraft>()
        .toList();
  }

  static Future<int> getPendingDraftCount() async {
    final drafts = await getPendingDrafts();
    return drafts.length;
  }

  static Future<void> saveDraft(ReportDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getPendingDrafts();
    final updatedDrafts = [
      draft,
      ...drafts.where((savedDraft) => savedDraft.id != draft.id),
    ];

    await prefs.setStringList(
      _draftsKey,
      updatedDrafts
          .map((savedDraft) => jsonEncode(savedDraft.toJson()))
          .toList(),
    );
    pendingDraftCount.value = updatedDrafts.length;
  }

  static Future<List<String>> copyImagesForDraft({
    required String draftId,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) return const <String>[];

    final folder = await _ensureDraftImageFolder();
    final copiedPaths = <String>[];

    for (var index = 0; index < images.length; index += 1) {
      final image = images[index];
      final extension = _safeExtension(image.name);
      final destinationPath = '${folder.path}/$draftId-$index$extension';
      final destinationFile = File(destinationPath);

      if (image.path.isNotEmpty && await File(image.path).exists()) {
        await File(image.path).copy(destinationPath);
      } else {
        await destinationFile.writeAsBytes(await image.readAsBytes());
      }

      copiedPaths.add(destinationPath);
    }

    return copiedPaths;
  }

  static Future<void> removeDraft(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getPendingDrafts();
    final removedDrafts = drafts.where((draft) => draft.id == draftId).toList();

    final remainingDrafts = drafts.where((draft) => draft.id != draftId).toList();

    await prefs.setStringList(
      _draftsKey,
      remainingDrafts.map((draft) => jsonEncode(draft.toJson())).toList(),
    );
    pendingDraftCount.value = remainingDrafts.length;

    for (final draft in removedDrafts) {
      await _deleteDraftImages(draft.imagePaths);
    }
  }

  static Future<Directory> _ensureDraftImageFolder() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final folder = Directory('${appDirectory.path}/$_draftImageFolderName');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  static String _safeExtension(String name) {
    final match = RegExp(r'\.[a-zA-Z0-9]+$').firstMatch(name);
    return match?.group(0)?.toLowerCase() ?? '.jpg';
  }

  static Future<void> _deleteDraftImages(List<String> imagePaths) async {
    for (final path in imagePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Draft cleanup should never block a successful report retry.
      }
    }
  }
}
