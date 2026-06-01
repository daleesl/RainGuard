import 'package:flutter_test/flutter_test.dart';
import 'package:rainguard_app/models/user_profile.dart';

void main() {
  group('UserProfile.fromMap', () {
    test('parses profile and reporter display names', () {
      final profile = UserProfile.fromMap({
        'email': 'juan@example.com',
        'display_name': 'Juan Dela Cruz',
        'first_name': 'Juan',
        'last_name': 'Dela Cruz',
        'photo_url': 'https://example.com/avatar.jpg',
        'auth_provider': 'google',
        'verification_id_front_url': 'https://example.com/id.jpg',
        'verification_status': 'verified',
      }, 'uid-1');

      expect(profile.uid, 'uid-1');
      expect(profile.displayName, 'Juan Dela Cruz');
      expect(profile.firstNameOrDisplay, 'Juan');
      expect(profile.publicReporterName, 'Juan D.');
      expect(profile.verificationStatus, 'verified');
      expect(profile.verificationIdFrontUrl, 'https://example.com/id.jpg');
    });

    test('falls back to email name and unverified status', () {
      final profile = UserProfile.fromMap({
        'email': 'resident@example.com',
        'display_name': '   ',
      }, 'uid-2');

      expect(profile.displayName, 'resident');
      expect(profile.firstNameOrDisplay, 'resident');
      expect(profile.publicReporterName, 'resident');
      expect(profile.verificationStatus, 'unverified');
    });
  });
}
