import 'package:flutter/material.dart';

import 'rainguard_state_message.dart';

class RainGuardErrorState extends StatelessWidget {
  const RainGuardErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return RainGuardStateMessage(
      icon: Icons.wifi_off_rounded,
      iconColor: Colors.red.shade700,
      title: title,
      message: message,
    );
  }
}
