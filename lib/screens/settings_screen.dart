import 'package:flutter/material.dart';

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

  void _showVerificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _VerificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent.shade400,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined),
            SizedBox(width: 8),
            Text(
              'RainGuard',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102033),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage account, alerts, location, and report verification.',
            style: TextStyle(color: Color(0xFF697B8C), height: 1.35),
          ),
          const SizedBox(height: 22),
          _ProfileCard(onVerifyTap: _showVerificationSheet),
          const SizedBox(height: 22),
          const _SectionLabel('Account'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile Information',
            subtitle: 'Name, email, and barangay details',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Update your login security',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.verified_user_outlined,
            title: 'Identity Verification',
            subtitle: 'Take a photo of a valid ID',
            status: 'Required to report',
            onTap: _showVerificationSheet,
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Notifications'),
          _SwitchTile(
            icon: Icons.notifications_none_rounded,
            title: 'Push Notifications',
            value: pushNotifications,
            onChanged: (value) => setState(() => pushNotifications = value),
          ),
          _SwitchTile(
            icon: Icons.thunderstorm_outlined,
            title: 'Weather Alerts',
            value: weatherAlerts,
            onChanged: (value) => setState(() => weatherAlerts = value),
          ),
          _SwitchTile(
            icon: Icons.assignment_outlined,
            title: 'Report Reminders',
            value: reportReminders,
            onChanged: (value) => setState(() => reportReminders = value),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Location'),
          _SettingsTile(
            icon: Icons.place_outlined,
            title: 'Default Barangay Location',
            subtitle: 'Barangay Lingga, Calamba',
            onTap: () {},
          ),
          _SwitchTile(
            icon: Icons.my_location_rounded,
            title: 'Use Current Location',
            value: useCurrentLocation,
            onChanged: (value) => setState(() => useCurrentLocation = value),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('App'),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'System default',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help and Emergency Info',
            subtitle: 'Hotlines and flood safety reminders',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.onVerifyTap});

  final VoidCallback onVerifyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.blueAccent.shade400,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'John Jester',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF102033),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Barangay Lingga, Calamba',
                  style: TextStyle(color: Color(0xFF697B8C), fontSize: 12),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onVerifyTap,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5DC),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Unverified resident',
                      style: TextStyle(
                        color: Color(0xFFB26B00),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF697B8C)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF526B82),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E7EF)),
            ),
            child: Row(
              children: [
                _TileIcon(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF102033),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF697B8C),
                          fontSize: 12,
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          status!,
                          style: const TextStyle(
                            color: Color(0xFFB26B00),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF697B8C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E7EF)),
        ),
        child: Row(
          children: [
            _TileIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102033),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Switch(
              value: value,
              activeColor: Colors.white,
              activeTrackColor: Colors.blueAccent.shade400,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.blueAccent.shade400, size: 21),
    );
  }
}

class _VerificationSheet extends StatefulWidget {
  const _VerificationSheet();

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
  bool _hasCapturedId = false;

  void _openCameraPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IdCameraPreview(
        onUsePhoto: () {
          Navigator.pop(context);
          setState(() {
            _hasCapturedId = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4FAFD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                'Verify your identity',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF102033),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Optional during sign up, required before filing community reports.',
                style: TextStyle(color: Color(0xFF697B8C), height: 1.4),
              ),
              const SizedBox(height: 18),
              _IdUploadCard(
                hasCapturedId: _hasCapturedId,
                onTap: _openCameraPreview,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: Color(0xFF1778D4)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your ID is used only to confirm that reports come from accountable community members.',
                        style: TextStyle(
                          color: Color(0xFF0B3A5B),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _hasCapturedId ? () => Navigator.pop(context) : null,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text(
                    'Submit for review',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IdUploadCard extends StatelessWidget {
  const _IdUploadCard({
    required this.hasCapturedId,
    required this.onTap,
  });

  final bool hasCapturedId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD9E7EF)),
          ),
          child: hasCapturedId
              ? Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F4FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E7EF)),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.badge_outlined,
                              size: 58,
                              color: Colors.blueAccent.shade400,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Captured',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Valid ID photo ready',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to retake the photo before submitting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF697B8C),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE7F4FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.blueAccent.shade400,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Upload valid ID',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102033),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Barangay ID, school ID, national ID, or any ID with your name',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF697B8C),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _IdCameraPreview extends StatelessWidget {
  const _IdCameraPreview({required this.onUsePhoto});

  final VoidCallback onUsePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: Color(0xFF071B2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.32),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Capture valid ID',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: const Color(0xFF102033),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.72),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                color: Colors.white.withOpacity(0.78),
                                size: 54,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Place ID inside the frame',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.84),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Text(
                          'Make sure your name and ID photo are clear.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.76),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: onUsePhoto,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text(
                    'Take photo',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
