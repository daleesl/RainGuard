import 'package:flutter/material.dart';

import '../rainguard_state_message.dart';
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

    return RainGuardStateMessage(
      icon: Icons.notifications_none_rounded,
      title: 'No notifications yet',
      message: message,
    );
  }
}
