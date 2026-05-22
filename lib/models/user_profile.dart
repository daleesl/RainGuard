class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.verificationStatus,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.authProvider,
    this.verificationIdFrontUrl,
  });

  final String uid;
  final String? email;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? authProvider;
  final String? verificationIdFrontUrl;
  final String verificationStatus;

  String get firstNameOrDisplay {
    final trimmedFirstName = firstName?.trim();
    if (trimmedFirstName != null && trimmedFirstName.isNotEmpty) {
      return trimmedFirstName;
    }

    final firstDisplayName = displayName.trim().split(RegExp(r'\s+')).first;
    return firstDisplayName.isNotEmpty ? firstDisplayName : 'RainGuard user';
  }

  String get publicReporterName {
    final trimmedFirstName = firstName?.trim();
    final trimmedLastName = lastName?.trim();
    if (trimmedFirstName != null && trimmedFirstName.isNotEmpty) {
      if (trimmedLastName != null && trimmedLastName.isNotEmpty) {
        return '$trimmedFirstName ${trimmedLastName[0].toUpperCase()}.';
      }
      return trimmedFirstName;
    }

    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first} ${parts.last[0].toUpperCase()}.';
    }

    return displayName.trim().isNotEmpty ? displayName : 'RainGuard user';
  }

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    final email = data['email'] as String?;
    final displayName = (data['display_name'] as String?)?.trim();

    return UserProfile(
      uid: uid,
      email: email,
      firstName: data['first_name'] as String?,
      lastName: data['last_name'] as String?,
      displayName: displayName != null && displayName.isNotEmpty
          ? displayName
          : _fallbackDisplayName(email),
      photoUrl: data['photo_url'] as String?,
      authProvider: data['auth_provider'] as String?,
      verificationIdFrontUrl: data['verification_id_front_url'] as String?,
      verificationStatus:
          (data['verification_status'] as String?) ?? 'unverified',
    );
  }

  static String _fallbackDisplayName(String? email) {
    if (email == null || email.trim().isEmpty) return 'RainGuard user';
    return email.split('@').first;
  }
}
