import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/models/report_draft.dart';
import 'package:rainguard_app/models/report_model.dart';

void main() {
  group('ReportDraft', () {
    test('round-trips pending report data for offline retry', () {
      final createdAt = DateTime(2026, 6, 5, 12, 30);
      final draft = ReportDraft(
        id: 'draft-123',
        type: ReportType.flood,
        description: 'Street is flooded',
        latitude: 14.2042,
        longitude: 121.1571,
        locationSource: 'manual',
        imagePaths: const ['front.jpg', 'side.jpg'],
        createdAt: createdAt,
        floodLevel: 'knee_deep',
      );

      final restored = ReportDraft.fromJson(draft.toJson());

      expect(restored.id, draft.id);
      expect(restored.type, ReportType.flood);
      expect(restored.description, draft.description);
      expect(restored.latitude, draft.latitude);
      expect(restored.longitude, draft.longitude);
      expect(restored.locationSource, 'manual');
      expect(restored.imagePaths, ['front.jpg', 'side.jpg']);
      expect(restored.createdAt, createdAt);
      expect(restored.floodLevel, 'knee_deep');
    });

    test('uses safe fallbacks for malformed saved draft data', () {
      final draft = ReportDraft.fromJson({
        'id': 123,
        'type': 'unknown',
        'latitude': 'not-a-number',
        'longitude': '121.1571',
        'image_paths': ['', 'local-image.jpg'],
      });

      expect(draft.id, '123');
      expect(draft.type, ReportType.rain);
      expect(draft.description, '');
      expect(draft.latitude, 0);
      expect(draft.longitude, 121.1571);
      expect(draft.locationSource, 'gps');
      expect(draft.imagePaths, ['local-image.jpg']);
    });
  });
}
