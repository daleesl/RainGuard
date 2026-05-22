import 'package:flutter/material.dart';

import '../theme/rainguard_theme.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/rainguard_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: const [
          Text(
            'Help',
            style: TextStyle(
              color: RainGuardColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Quick guide for using RainGuard safely and correctly.',
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              height: 1.35,
            ),
          ),
          SizedBox(height: 18),
          _HelpCard(
            icon: Icons.map_outlined,
            title: 'View community reports',
            body:
                'Open the map to see rain, flood, and risk reports submitted around Barangay Lingga and nearby Calamba areas.',
          ),
          _HelpCard(
            icon: Icons.add_location_alt_outlined,
            title: 'Submit a report',
            body:
                'Verified users can submit reports using their current GPS location, description, and optional photos.',
          ),
          _HelpCard(
            icon: Icons.verified_user_outlined,
            title: 'Why verification is needed',
            body:
                'Verification helps make community reports accountable and reduces fake or duplicate reports.',
          ),
          _HelpCard(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            body:
                'Enable notifications to receive community report alerts even when RainGuard is not open.',
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.body,
    required this.icon,
    required this.title,
  });

  final String body;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RainGuardCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: RainGuardColors.softBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: RainGuardColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: RainGuardColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: const TextStyle(
                      color: RainGuardColors.secondaryText,
                      fontSize: 8,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
