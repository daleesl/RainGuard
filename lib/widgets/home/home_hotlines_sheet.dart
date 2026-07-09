import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';

class HomeHotlinesSheet extends StatelessWidget {
  const HomeHotlinesSheet({super.key});

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
            'Emergency Hotlines',
            style: TextStyle(
              color: RainGuardColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const _HotlineRow(label: 'National Emergency', number: '911'),
          const _HotlineRow(
            label: 'Barangay / Local DRRMO',
            number: 'Add local number',
          ),
          const _HotlineRow(
            label: 'Rescue / Medical Help',
            number: 'Add local number',
          ),
        ],
      ),
    );
  }
}

class _HotlineRow extends StatelessWidget {
  const _HotlineRow({required this.label, required this.number});

  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RainGuardColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.local_phone_outlined, color: RainGuardColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: RainGuardColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    number,
                    style: const TextStyle(
                      color: RainGuardColors.secondaryText,
                      fontSize: 8,
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
