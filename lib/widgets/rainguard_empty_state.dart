import 'package:flutter/material.dart';

import 'rainguard_state_message.dart';

class RainGuardEmptyState extends StatelessWidget {
  const RainGuardEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return RainGuardStateMessage(icon: icon, title: title, message: message);
  }
}
