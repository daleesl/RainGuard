import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
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
  bool pushNotifications = true;
  bool weatherAlerts = true;
  bool reportReminders = true;
  bool useCurrentLocation = true;
  bool _isLoggingOut = false;

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
                title: 'Push Notifications',
                value: pushNotifications,
                onChanged: (value) => setState(() => pushNotifications = value),
              ),
              SettingsSwitchTile(
                icon: Icons.thunderstorm_outlined,
                title: 'Weather Alerts',
                value: weatherAlerts,
                onChanged: (value) => setState(() => weatherAlerts = value),
              ),
              SettingsSwitchTile(
                icon: Icons.assignment_outlined,
                title: 'Report Reminders',
                value: reportReminders,
                onChanged: (value) => setState(() => reportReminders = value),
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
