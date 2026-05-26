import 'package:flutter/material.dart';

class VerificationRequiredDialog {
  const VerificationRequiredDialog._();

  static Future<bool?> show(BuildContext context, String status) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Verification required',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          content: Text(
            _message(status),
            style: const TextStyle(fontSize: 10, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verify ID'),
            ),
          ],
        );
      },
    );
  }

  static String _message(String status) {
    switch (status) {
      case 'pending':
        return 'Your ID is still pending admin review. You can submit reports once an admin approves your account.';
      case 'rejected':
        return 'Your ID verification was rejected. Upload a clearer valid ID photo before submitting reports.';
      case 'unverified':
      default:
        return 'Only verified users can submit community reports. Upload a valid ID photo first.';
    }
  }
}
