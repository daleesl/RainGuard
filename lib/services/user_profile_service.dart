import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService._();

  static final _firestore = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  static Stream<UserProfile?> currentUserProfileStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);

    return userRef(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return fallbackProfile(user);
      return UserProfile.fromMap(data, snapshot.id);
    });
  }

  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await userRef(user.uid).get();
    final data = snapshot.data();
    if (data == null) return fallbackProfile(user);
    return UserProfile.fromMap(data, snapshot.id);
  }

  static UserProfile fallbackProfile(User user) {
    final displayName = user.displayName?.trim();
    final emailName = user.email?.split('@').first;

    return UserProfile(
      uid: user.uid,
      email: user.email,
      displayName: displayName != null && displayName.isNotEmpty
          ? displayName
          : emailName ?? 'RainGuard user',
      photoUrl: user.photoURL,
      verificationStatus: 'unverified',
    );
  }

  static Future<void> upsertUserProfile({
    required User user,
    required String provider,
    String? firstName,
    String? lastName,
    String? displayName,
  }) async {
    final ref = userRef(user.uid);
    final doc = await ref.get();
    final now = FieldValue.serverTimestamp();
    final cleanFirstName = _clean(firstName);
    final cleanLastName = _clean(lastName);
    final cleanDisplayName = _clean(displayName) ??
        _clean(user.displayName) ??
        _fallbackDisplayName(user.email);

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'photo_url': user.photoURL,
      'auth_provider': provider,
      'updated_at': now,
      'last_login_at': now,
    };

    if (cleanFirstName != null) data['first_name'] = cleanFirstName;
    if (cleanLastName != null) data['last_name'] = cleanLastName;
    if (cleanDisplayName != null) data['display_name'] = cleanDisplayName;

    if (!doc.exists) {
      data['created_at'] = now;
      data['verification_status'] = 'unverified';
    }

    await ref.set(data, SetOptions(merge: true));
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _fallbackDisplayName(String? email) {
    final trimmed = email?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.split('@').first;
  }
}
