import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_draft.dart';

class ReportDraftService {
  const ReportDraftService._();

  static const String _draftsKey = 'pending_report_drafts';

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
  }

  static Future<void> removeDraft(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getPendingDrafts();
    await prefs.setStringList(
      _draftsKey,
      drafts
          .where((draft) => draft.id != draftId)
          .map((draft) => jsonEncode(draft.toJson()))
          .toList(),
    );
  }
}
