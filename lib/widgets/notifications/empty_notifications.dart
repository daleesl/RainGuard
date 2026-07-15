import 'package:flutter/material.dart';

import '../rainguard_state_message.dart';

class EmptyNotifications extends StatelessWidget {
  const EmptyNotifications({
    super.key,
    required this.message,
    this.title = 'No notifications yet',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return RainGuardStateMessage(
      icon: Icons.notifications_none_rounded,
      title: title,
      message: message,
    );
  }
}
