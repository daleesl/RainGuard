import 'package:flutter/material.dart';

import '../../theme/rainguard_theme.dart';
import '../rainguard_status_chip.dart';

class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.verificationStatus,
    required this.onVerifyTap,
  });

  final String displayName;
  final String email;
  final String verificationStatus;
  final VoidCallback onVerifyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RainGuardColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: RainGuardColors.softBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person_rounded,
              color: RainGuardColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: RainGuardColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onVerifyTap,
                  borderRadius: BorderRadius.circular(RainGuardRadii.pill),
                  child: RainGuardStatusChip(
                    label: _verificationPillLabel(verificationStatus),
                    icon: _verificationPillIcon(verificationStatus),
                    tone: _verificationPillTone(verificationStatus),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: RainGuardColors.secondaryText,
          ),
        ],
      ),
    );
  }

  String _verificationPillLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified resident';
      case 'pending':
        return 'Verification pending';
      case 'rejected':
        return 'Verification rejected';
      case 'unverified':
      default:
        return 'Unverified resident';
    }
  }

  IconData _verificationPillIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'rejected':
        return Icons.error_outline_rounded;
      case 'unverified':
      default:
        return Icons.shield_outlined;
    }
  }

  RainGuardStatusTone _verificationPillTone(String status) {
    switch (status) {
      case 'verified':
        return RainGuardStatusTone.success;
      case 'pending':
      case 'rejected':
        return RainGuardStatusTone.warning;
      case 'unverified':
      default:
        return RainGuardStatusTone.info;
    }
  }
}
