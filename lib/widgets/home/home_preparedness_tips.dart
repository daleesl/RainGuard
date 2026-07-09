import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';
import '../rainguard_card.dart';
import 'home_section_header.dart';

class HomePreparednessTips extends StatelessWidget {
  const HomePreparednessTips({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader('Preparedness Tips'),
        SizedBox(height: 12),
        _TipCard(
          icon: Icons.battery_charging_full_rounded,
          title: 'Charge your phone',
          body: 'Keep your phone and power bank ready before heavy rain.',
        ),
        SizedBox(height: 10),
        _TipCard(
          icon: Icons.folder_copy_outlined,
          title: 'Prepare documents',
          body: 'Place IDs and important papers in a waterproof pouch.',
        ),
        SizedBox(height: 10),
        _TipCard(
          icon: Icons.waves_rounded,
          title: 'Avoid floodwater',
          body: 'Do not walk or drive through moving floodwater.',
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return RainGuardCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RainGuardColors.softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: RainGuardColors.primary, size: 21),
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
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
