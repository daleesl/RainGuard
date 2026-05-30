import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/utils/firebase_error_messages.dart';

void main() {
  group('friendlyFirebaseError', () {
    test('explains permission errors in user-safe language', () {
      final message = friendlyFirebaseError(
        Exception('permission-denied: Missing or insufficient permissions.'),
      );

      expect(message, contains('permission'));
      expect(message, isNot(contains('Exception')));
    });

    test('keeps the provided fallback for unknown errors', () {
      final message = friendlyFirebaseError(
        Exception('unknown'),
        fallback: 'Could not load alerts.',
      );

      expect(message, 'Could not load alerts.');
    });
  });
}
