import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';
import 'notification_filter_bar.dart';

class EmptyNotifications extends StatelessWidget {
  const EmptyNotifications({super.key, required this.filter});

  final NotificationFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      NotificationFilter.flood => 'No flood reports match this filter yet.',
      NotificationFilter.rain => 'No rain reports match this filter yet.',
      NotificationFilter.all =>
        'RainGuard will show community reports and weather alerts here.',
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RainGuardColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 44,
            color: RainGuardColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No notifications yet',
            style: TextStyle(
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
