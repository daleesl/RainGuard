import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_preference_service.dart';
import '../services/notification_token_service.dart';
import '../services/user_profile_service.dart';
import '../theme/rainguard_theme.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/settings/notification_preference_sheet.dart';
import '../widgets/settings/settings_content.dart';
import '../widgets/settings/settings_info_sheets.dart';
import '../widgets/settings/verification_sheet.dart';
import 'auth/login_screen.dart';
import 'emergency_info_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = false;
  bool useCurrentLocation = true;
  bool _isLoggingOut = false;
  bool _isUpdatingPushNotifications = false;
  bool _isUpdatingNotificationPreference = false;
  NotificationPreference _notificationPreference =
      NotificationPreference.allReports;
  double _nearbyRadiusKm =
      NotificationPreferenceService.defaultNearbyRadiusKm;
  String _pushNotificationSubtitle =
      'Tap to allow community report alerts outside the app';

  @override
  void initState() {
    super.initState();
    _loadNotificationPermissionState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final preference =
        await NotificationPreferenceService.getCurrentPreference();
    final nearbyRadiusKm =
        await NotificationPreferenceService.getCurrentNearbyRadiusKm();
    if (!mounted) return;
    setState(() {
      _notificationPreference = preference;
      _nearbyRadiusKm = nearbyRadiusKm;
    });
  }

  Future<void> _loadNotificationPermissionState() async {
    final hasPermission =
        await NotificationTokenService.hasNotificationPermission();
    final isRegistered =
        await NotificationTokenService.isCurrentDeviceRegistered();
    final isEnabled = hasPermission && isRegistered;
    if (!mounted) return;

    setState(() {
      pushNotifications = isEnabled;
      _pushNotificationSubtitle = isEnabled
          ? 'Enabled for community report alerts'
          : hasPermission
              ? 'Tap to reconnect this device for community report alerts'
              : 'Tap to allow community report alerts outside the app';
    });
  }

  void _showVerificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VerificationSheet(),
    );
  }

  Future<void> _sendPasswordResetEmail(String? email) async {
    final cleanEmail = email?.trim();
    if (cleanEmail == null || cleanEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email address is linked to this account.'),
        ),
      );
      return;
    }

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Send password reset email?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'We will send a password reset link to $cleanEmail.',
          style: const TextStyle(fontSize: 11, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );

    if (shouldSend != true) return;

    try {
      await AuthService.sendPasswordResetEmail(cleanEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $cleanEmail.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send reset email: $error')),
      );
    }
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeInfoSheet(),
    );
  }

  void _showBarangayLocationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const BarangayLocationSheet(),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Log out of your account?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Log out', maxLines: 1),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $error')));
      setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _setPushNotifications(bool value) async {
    setState(() => _isUpdatingPushNotifications = true);

    try {
      if (value) {
        final result = await NotificationTokenService.registerCurrentDevice();
        if (!mounted) return;

        switch (result) {
          case NotificationTokenResult.enabled:
            setState(() {
              pushNotifications = true;
              _pushNotificationSubtitle =
                  'Enabled for community report alerts';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Push notifications enabled.')),
            );
            break;
          case NotificationTokenResult.denied:
            setState(() {
              pushNotifications = false;
              _pushNotificationSubtitle =
                  'Permission denied. Enable notifications in phone settings.';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notifications are blocked. Enable them in your phone settings.',
                ),
              ),
            );
            break;
          case NotificationTokenResult.notSignedIn:
            setState(() {
              pushNotifications = false;
              _pushNotificationSubtitle =
                  'Log in first to enable push notifications';
            });
            break;
          case NotificationTokenResult.tokenUnavailable:
          case NotificationTokenResult.failed:
            setState(() {
              pushNotifications = false;
              _pushNotificationSubtitle =
                  'Could not save this device. Check connection or rules.';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not enable push notifications. Check connection or Firestore rules.',
                ),
              ),
            );
            break;
        }
      } else {
        await NotificationTokenService.deleteCurrentToken();
        if (!mounted) return;
        setState(() {
          pushNotifications = false;
          _pushNotificationSubtitle =
              'Tap to allow community report alerts outside the app';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Push notifications disabled.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPushNotifications = false);
      }
    }
  }

  Future<void> _showNotificationPreferenceSheet() async {
    final selection =
        await showModalBottomSheet<NotificationPreferenceSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPreferenceSheet(
        selectedPreference: _notificationPreference,
        selectedRadiusKm: _nearbyRadiusKm,
      ),
    );

    if (!mounted || selection == null) return;

    setState(() => _isUpdatingNotificationPreference = true);
    try {
      await NotificationPreferenceService.saveCurrentPreference(
        selection.preference,
        nearbyRadiusKm: selection.nearbyRadiusKm,
      );
      if (!mounted) return;
      setState(() {
        _notificationPreference = selection.preference;
        _nearbyRadiusKm = selection.nearbyRadiusKm;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification preference set to ${selection.preference.label}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update preference: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingNotificationPreference = false);
      }
    }
  }

  void _openHelp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
    );
  }

  void _openEmergencyInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EmergencyInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: StreamBuilder<UserProfile?>(
        stream: UserProfileService.currentUserProfileStream(),
        builder: (context, snapshot) {
          return SettingsContent(
            profile: snapshot.data,
            pushNotifications: pushNotifications,
            useCurrentLocation: useCurrentLocation,
            isLoggingOut: _isLoggingOut,
            isUpdatingPushNotifications: _isUpdatingPushNotifications,
            isUpdatingNotificationPreference:
                _isUpdatingNotificationPreference,
            notificationPreference: _notificationPreference,
            nearbyRadiusKm: _nearbyRadiusKm,
            pushNotificationSubtitle: _pushNotificationSubtitle,
            onVerifyTap: _showVerificationSheet,
            onChangePasswordTap: () =>
                _sendPasswordResetEmail(snapshot.data?.email),
            onPushNotificationsChanged: _setPushNotifications,
            onNotificationPreferenceTap: _showNotificationPreferenceSheet,
            onBarangayLocationTap: _showBarangayLocationSheet,
            onCurrentLocationChanged: (value) {
              setState(() => useCurrentLocation = value);
            },
            onThemeTap: _showThemeSheet,
            onHelpTap: _openHelp,
            onEmergencyInfoTap: _openEmergencyInfo,
            onLogoutTap: _isLoggingOut ? null : _logout,
          );
        },
      ),
    );
  }
}
