import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'user_profile_service.dart';

class AuthService {
  AuthService._();

  static bool _googleInitialized = false;
  static final _auth = FirebaseAuth.instance;

  static Future<UserCredential> signInWithGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      final nameParts = _splitDisplayName(user.displayName);
      await UserProfileService.upsertUserProfile(
        user: user,
        provider: 'google',
        firstName: nameParts.firstName,
        lastName: nameParts.lastName,
        displayName: user.displayName,
      );
    }
    return userCredential;
  }

  static Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final displayName = '${firstName.trim()} ${lastName.trim()}'.trim();
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await UserProfileService.upsertUserProfile(
        user: user,
        provider: 'password',
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
      );
    }
    return userCredential;
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await UserProfileService.upsertUserProfile(
        user: user,
        provider: 'password',
      );
    }
    return userCredential;
  }

  static ({String? firstName, String? lastName}) _splitDisplayName(
    String? displayName,
  ) {
    final parts = displayName
        ?.trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts == null || parts.isEmpty) {
      return (firstName: null, lastName: null);
    }

    return (
      firstName: parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
    );
  }
}
