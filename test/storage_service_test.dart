import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/services/storage_service.dart';

void main() {
  test('builds stable report image paths from the draft identifier', () {
    expect(
      StorageService.reportImagePath('draft-123', 0),
      'reports/draft-123/image-0',
    );
    expect(
      StorageService.reportImagePath('draft unsafe/id', 2),
      'reports/draft_unsafe_id/image-2',
    );
  });
}
