import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/safety_alert.dart';
import '../../theme/rainguard_theme.dart';
import '../rainguard_card.dart';
import 'notification_shared.dart';

class SafetyAlertCard extends StatelessWidget {
  const SafetyAlertCard({super.key, required this.alert});

  final SafetyAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(alert.riskLevel);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RainGuardCard(
        padding: EdgeInsets.zero,
        radius: 22,
        shadowOpacity: 0.06,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.campaign_outlined,
                                color: color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: RainGuardColors.ink,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${alert.area} barangay advisory',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: RainGuardColors.secondaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            NotificationSeverityChip(
                              color: color,
                              label: _riskLabel(alert.riskLevel),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Text(
                          alert.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8,
                            height: 1.4,
                            color: RainGuardColors.ink,
                          ),
                        ),
                        const SizedBox(height: 13),
                        NotificationMetaPill(
                          color: color,
                          icon: Icons.access_time_rounded,
                          label: timeago.format(alert.publishedAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _riskColor(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
      case 'warning':
        return Colors.red.shade700;
      case 'watch':
        return Colors.amber.shade800;
      default:
        return RainGuardColors.primary;
    }
  }

  String _riskLabel(String riskLevel) {
    return riskLevel.isEmpty
        ? 'Info'
        : '${riskLevel[0].toUpperCase()}${riskLevel.substring(1)}';
  }
}
