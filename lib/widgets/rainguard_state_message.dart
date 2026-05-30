import 'package:flutter/material.dart';

import '../theme/rainguard_theme.dart';

class RainGuardStateMessage extends StatelessWidget {
  const RainGuardStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = RainGuardColors.primary,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RainGuardColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: iconColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: RainGuardColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
