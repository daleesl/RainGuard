import 'package:flutter/material.dart';

import '../theme/rainguard_theme.dart';
import '../widgets/rainguard_app_bar.dart';
import '../widgets/rainguard_card.dart';

class EmergencyInfoScreen extends StatelessWidget {
  const EmergencyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RainGuardColors.background,
      appBar: const RainGuardAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: const [
          Text(
            'Emergency Info',
            style: TextStyle(
              color: RainGuardColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Keep these safety reminders ready during heavy rainfall and flooding.',
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              height: 1.35,
            ),
          ),
          SizedBox(height: 18),
          _EmergencyCard(
            icon: Icons.local_phone_outlined,
            title: 'Emergency hotlines',
            body:
                'Call local emergency responders, barangay officials, or city rescue services when there is immediate danger.',
          ),
          _EmergencyCard(
            icon: Icons.water_damage_outlined,
            title: 'During flood risk',
            body:
                'Move to higher ground, avoid crossing floodwater, unplug appliances, and prepare important documents.',
          ),
          _EmergencyCard(
            icon: Icons.backpack_outlined,
            title: 'Go-bag checklist',
            body:
                'Bring water, flashlight, medicine, power bank, ID, clothes, food, and emergency contact information.',
          ),
          _EmergencyCard(
            icon: Icons.warning_amber_rounded,
            title: 'Report responsibly',
            body:
                'Only submit reports when it is safe. Add clear photos and descriptions that help responders understand the situation.',
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({
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
