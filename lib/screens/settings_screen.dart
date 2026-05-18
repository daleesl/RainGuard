import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_preference_service.dart';
import '../services/notification_token_service.dart';
import '../services/user_profile_service.dart';
import '../theme/rainguard_theme.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/settings/settings_profile_card.dart';
import '../widgets/settings/settings_tiles.dart';
import '../widgets/settings/verification_sheet.dart';
import 'auth/login_screen.dart';

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
    final selection = await showModalBottomSheet<_NotificationPreferenceSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationPreferenceSheet(
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

  String get _notificationPreferenceSubtitle {
    if (_notificationPreference == NotificationPreference.nearbyOnly) {
      return 'Only alert me for reports within ${_nearbyRadiusKm.toStringAsFixed(0)} km.';
    }

    return _notificationPreference.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: StreamBuilder<UserProfile?>(
        stream: UserProfileService.currentUserProfileStream(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final displayName = profile?.displayName ?? 'RainGuard user';
          final email = profile?.email ?? 'No email available';
          final verificationStatus =
              profile?.verificationStatus ?? 'unverified';

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
                onVerifyTap: _showVerificationSheet,
              ),
              const SizedBox(height: 22),
              const SettingsSectionLabel('Account'),
              SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile Information',
                subtitle: '$displayName - $email',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your login security',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.verified_user_outlined,
                title: 'Identity Verification',
                subtitle: 'Take a photo of a valid ID',
                status: _verificationStatusLabel(verificationStatus),
                onTap: _showVerificationSheet,
              ),
              const SizedBox(height: 18),
              const SettingsSectionLabel('Notifications'),
              SettingsSwitchTile(
                icon: Icons.notifications_none_rounded,
                title: 'Allow Notifications',
                subtitle: _pushNotificationSubtitle,
                value: pushNotifications,
                isLoading: _isUpdatingPushNotifications,
                onChanged: _setPushNotifications,
              ),
              SettingsTile(
                icon: Icons.tune_rounded,
                title: 'Notification Type',
                subtitle: _notificationPreferenceSubtitle,
                status: _isUpdatingNotificationPreference
                    ? 'Updating...'
                    : _notificationPreference.label,
                onTap: _isUpdatingNotificationPreference
                    ? () {}
                    : _showNotificationPreferenceSheet,
              ),
              const SizedBox(height: 18),
              const SettingsSectionLabel('Location'),
              SettingsTile(
                icon: Icons.place_outlined,
                title: 'Default Barangay Location',
                subtitle: 'Barangay Lingga, Calamba',
                onTap: () {},
              ),
              SettingsSwitchTile(
                icon: Icons.my_location_rounded,
                title: 'Use Current Location',
                value: useCurrentLocation,
                onChanged: (value) =>
                    setState(() => useCurrentLocation = value),
              ),
              const SizedBox(height: 18),
              const SettingsSectionLabel('App'),
              SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: 'System default',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help and Emergency Info',
                subtitle: 'Hotlines and flood safety reminders',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              SettingsLogoutTile(
                isLoading: _isLoggingOut,
                onTap: _isLoggingOut ? null : _logout,
              ),
            ],
          );
        },
      ),
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

class _NotificationPreferenceSelection {
  const _NotificationPreferenceSelection({
    required this.preference,
    required this.nearbyRadiusKm,
  });

  final NotificationPreference preference;
  final double nearbyRadiusKm;
}

class _NotificationPreferenceSheet extends StatefulWidget {
  const _NotificationPreferenceSheet({
    required this.selectedPreference,
    required this.selectedRadiusKm,
  });

  final NotificationPreference selectedPreference;
  final double selectedRadiusKm;

  @override
  State<_NotificationPreferenceSheet> createState() =>
      _NotificationPreferenceSheetState();
}

class _NotificationPreferenceSheetState
    extends State<_NotificationPreferenceSheet> {
  late NotificationPreference _selectedPreference;
  late double _selectedRadiusKm;

  @override
  void initState() {
    super.initState();
    _selectedPreference = widget.selectedPreference;
    _selectedRadiusKm = widget.selectedRadiusKm;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: RainGuardColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Notification Type',
            style: TextStyle(
              color: RainGuardColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose which community reports should alert this device.',
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ...NotificationPreference.values.map(
            (preference) => _NotificationPreferenceOption(
              preference: preference,
              selectedRadiusKm: _selectedRadiusKm,
              isSelected: _selectedPreference == preference,
              onRadiusChanged: (radiusKm) {
                setState(() {
                  _selectedPreference = NotificationPreference.nearbyOnly;
                  _selectedRadiusKm = radiusKm;
                });
              },
              onTap: () {
                setState(() => _selectedPreference = preference);
              },
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _NotificationPreferenceSelection(
                    preference: _selectedPreference,
                    nearbyRadiusKm: _selectedRadiusKm,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: RainGuardColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Save Preference',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPreferenceOption extends StatelessWidget {
  const _NotificationPreferenceOption({
    required this.preference,
    required this.isSelected,
    required this.selectedRadiusKm,
    required this.onRadiusChanged,
    required this.onTap,
  });

  final NotificationPreference preference;
  final bool isSelected;
  final double selectedRadiusKm;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? RainGuardColors.softBlue : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? RainGuardColors.primary
                    : RainGuardColors.border,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: RainGuardColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _preferenceIcon(preference),
                        color: RainGuardColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preference.label,
                            style: const TextStyle(
                              color: RainGuardColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            preference.description,
                            style: const TextStyle(
                              color: RainGuardColors.secondaryText,
                              fontSize: 8,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: RainGuardColors.primary,
                      ),
                  ],
                ),
                if (preference == NotificationPreference.nearbyOnly &&
                    isSelected) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final radiusKm
                          in NotificationPreferenceService.nearbyRadiusOptionsKm)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: radiusKm == 5 ? 0 : 8,
                            ),
                            child: _RadiusChoiceChip(
                              radiusKm: radiusKm,
                              isSelected: selectedRadiusKm == radiusKm,
                              onTap: () => onRadiusChanged(radiusKm),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _preferenceIcon(NotificationPreference preference) {
    switch (preference) {
      case NotificationPreference.allReports:
        return Icons.notifications_active_outlined;
      case NotificationPreference.floodOnly:
        return Icons.water_drop_outlined;
      case NotificationPreference.nearbyOnly:
        return Icons.near_me_outlined;
      case NotificationPreference.highRiskOnly:
        return Icons.priority_high_rounded;
    }
  }
}

class _RadiusChoiceChip extends StatelessWidget {
  const _RadiusChoiceChip({
    required this.radiusKm,
    required this.isSelected,
    required this.onTap,
  });

  final double radiusKm;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isSelected ? Colors.white : RainGuardColors.primary,
        backgroundColor:
            isSelected ? RainGuardColors.primary : Colors.white,
        side: BorderSide(
          color: isSelected ? RainGuardColors.primary : RainGuardColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${radiusKm.toStringAsFixed(0)} km',
          maxLines: 1,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
