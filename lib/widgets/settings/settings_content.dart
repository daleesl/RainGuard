import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/notification_preference_service.dart';
import '../../theme/rainguard_theme.dart';
import 'settings_profile_card.dart';
import 'settings_tiles.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({
    super.key,
    required this.profile,
    required this.pushNotifications,
    required this.useCurrentLocation,
    required this.isLoggingOut,
    required this.isUpdatingPushNotifications,
    required this.isUpdatingNotificationPreference,
    required this.notificationPreference,
    required this.nearbyRadiusKm,
    required this.pushNotificationSubtitle,
    required this.onVerifyTap,
    required this.onChangePasswordTap,
    required this.onPushNotificationsChanged,
    required this.onNotificationPreferenceTap,
    required this.onBarangayLocationTap,
    required this.onCurrentLocationChanged,
    required this.onThemeTap,
    required this.onHelpTap,
    required this.onEmergencyInfoTap,
    required this.onLogoutTap,
  });

  final UserProfile? profile;
  final bool pushNotifications;
  final bool useCurrentLocation;
  final bool isLoggingOut;
  final bool isUpdatingPushNotifications;
  final bool isUpdatingNotificationPreference;
  final NotificationPreference notificationPreference;
  final double nearbyRadiusKm;
  final String pushNotificationSubtitle;
  final VoidCallback onVerifyTap;
  final VoidCallback onChangePasswordTap;
  final ValueChanged<bool> onPushNotificationsChanged;
  final VoidCallback onNotificationPreferenceTap;
  final VoidCallback onBarangayLocationTap;
  final ValueChanged<bool> onCurrentLocationChanged;
  final VoidCallback onThemeTap;
  final VoidCallback onHelpTap;
  final VoidCallback onEmergencyInfoTap;
  final VoidCallback? onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.displayName ?? 'RainGuard user';
    final email = profile?.email ?? 'No email available';
    final verificationStatus = profile?.verificationStatus ?? 'unverified';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: RainGuardColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage account, alerts, location, and report verification.',
          style: TextStyle(
            color: RainGuardColors.secondaryText,
            fontSize: 8,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 22),
        SettingsProfileCard(
          displayName: displayName,
          email: email,
          verificationStatus: verificationStatus,
          onVerifyTap: onVerifyTap,
        ),
        const SizedBox(height: 22),
        _AccountSettingsSection(
          verificationStatus: verificationStatus,
          onChangePasswordTap: onChangePasswordTap,
          onVerifyTap: onVerifyTap,
        ),
        const SizedBox(height: 18),
        _NotificationSettingsSection(
          pushNotifications: pushNotifications,
          isUpdatingPushNotifications: isUpdatingPushNotifications,
          isUpdatingNotificationPreference: isUpdatingNotificationPreference,
          notificationPreference: notificationPreference,
          notificationPreferenceSubtitle: _notificationPreferenceSubtitle,
          pushNotificationSubtitle: pushNotificationSubtitle,
          onPushNotificationsChanged: onPushNotificationsChanged,
          onNotificationPreferenceTap: onNotificationPreferenceTap,
        ),
        const SizedBox(height: 18),
        _LocationSettingsSection(
          useCurrentLocation: useCurrentLocation,
          onBarangayLocationTap: onBarangayLocationTap,
          onCurrentLocationChanged: onCurrentLocationChanged,
        ),
        const SizedBox(height: 18),
        _AppSettingsSection(
          onThemeTap: onThemeTap,
          onHelpTap: onHelpTap,
          onEmergencyInfoTap: onEmergencyInfoTap,
        ),
        const SizedBox(height: 10),
        SettingsLogoutTile(
          isLoading: isLoggingOut,
          onTap: onLogoutTap,
        ),
      ],
    );
  }

  String get _notificationPreferenceSubtitle {
    if (notificationPreference == NotificationPreference.nearbyOnly) {
      return 'Only alert me for reports within ${nearbyRadiusKm.toStringAsFixed(0)} km.';
    }

    return notificationPreference.description;
  }
}

class _AccountSettingsSection extends StatelessWidget {
  const _AccountSettingsSection({
    required this.verificationStatus,
    required this.onChangePasswordTap,
    required this.onVerifyTap,
  });

  final String verificationStatus;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onVerifyTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('Account'),
        SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Send a password reset link to your email',
          onTap: onChangePasswordTap,
        ),
        SettingsTile(
          icon: Icons.verified_user_outlined,
          title: 'Identity Verification',
          subtitle: 'Take or upload a valid ID photo',
          status: _verificationStatusLabel(verificationStatus),
          onTap: onVerifyTap,
        ),
      ],
    );
  }

  String _verificationStatusLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified resident';
      case 'pending':
        return 'Verification pending';
      case 'rejected':
        return 'Verification needs review';
      case 'unverified':
      default:
        return 'Required to report';
    }
  }
}

class _NotificationSettingsSection extends StatelessWidget {
  const _NotificationSettingsSection({
    required this.pushNotifications,
    required this.isUpdatingPushNotifications,
    required this.isUpdatingNotificationPreference,
    required this.notificationPreference,
    required this.notificationPreferenceSubtitle,
    required this.pushNotificationSubtitle,
    required this.onPushNotificationsChanged,
    required this.onNotificationPreferenceTap,
  });

  final bool pushNotifications;
  final bool isUpdatingPushNotifications;
  final bool isUpdatingNotificationPreference;
  final NotificationPreference notificationPreference;
  final String notificationPreferenceSubtitle;
  final String pushNotificationSubtitle;
  final ValueChanged<bool> onPushNotificationsChanged;
  final VoidCallback onNotificationPreferenceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('Notifications'),
        SettingsSwitchTile(
          icon: Icons.notifications_none_rounded,
          title: 'Allow Notifications',
          subtitle: pushNotificationSubtitle,
          value: pushNotifications,
          isLoading: isUpdatingPushNotifications,
          onChanged: onPushNotificationsChanged,
        ),
        SettingsTile(
          icon: Icons.tune_rounded,
          title: 'Notification Type',
          subtitle: notificationPreferenceSubtitle,
          status: isUpdatingNotificationPreference
              ? 'Updating...'
              : notificationPreference.label,
          onTap: isUpdatingNotificationPreference
              ? () {}
              : onNotificationPreferenceTap,
        ),
      ],
    );
  }
}

class _LocationSettingsSection extends StatelessWidget {
  const _LocationSettingsSection({
    required this.useCurrentLocation,
    required this.onBarangayLocationTap,
    required this.onCurrentLocationChanged,
  });

  final bool useCurrentLocation;
  final VoidCallback onBarangayLocationTap;
  final ValueChanged<bool> onCurrentLocationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('Location'),
        SettingsTile(
          icon: Icons.place_outlined,
          title: 'Default Barangay Location',
          subtitle: 'Barangay Lingga, Calamba',
          onTap: onBarangayLocationTap,
        ),
        SettingsSwitchTile(
          icon: Icons.my_location_rounded,
          title: 'Use Current Location',
          value: useCurrentLocation,
          onChanged: onCurrentLocationChanged,
        ),
      ],
    );
  }
}

class _AppSettingsSection extends StatelessWidget {
  const _AppSettingsSection({
    required this.onThemeTap,
    required this.onHelpTap,
    required this.onEmergencyInfoTap,
  });

  final VoidCallback onThemeTap;
  final VoidCallback onHelpTap;
  final VoidCallback onEmergencyInfoTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('App'),
        SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Theme',
          subtitle: 'Light theme active',
          onTap: onThemeTap,
        ),
        SettingsTile(
          icon: Icons.help_outline_rounded,
          title: 'Help',
          subtitle: 'How RainGuard reports and verification work',
          onTap: onHelpTap,
        ),
        SettingsTile(
          icon: Icons.local_phone_outlined,
          title: 'Emergency Info',
          subtitle: 'Hotlines and flood safety reminders',
          onTap: onEmergencyInfoTap,
        ),
      ],
    );
  }
}
