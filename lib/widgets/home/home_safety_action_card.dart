import 'package:flutter/material.dart';

import '../../models/home_risk_assessment.dart';
import '../../theme/rainguard_theme.dart';
import '../rainguard_card.dart';

class HomeSafetyActionCard extends StatelessWidget {
  const HomeSafetyActionCard({
    super.key,
    required this.riskAssessment,
    required this.isLoadingRisk,
    required this.riskLoadFailed,
  });

  final HomeRiskAssessment? riskAssessment;
  final bool isLoadingRisk;
  final bool riskLoadFailed;

  @override
  Widget build(BuildContext context) {
    final level = riskAssessment?.level;
    final color = riskLoadFailed
        ? Colors.red.shade700
        : switch (level) {
            HomeFloodRiskLevel.high => Colors.red.shade700,
            HomeFloodRiskLevel.watch => Colors.amber.shade800,
            HomeFloodRiskLevel.clear => Colors.green.shade700,
            null => RainGuardColors.primary,
          };
    final title = switch ((isLoadingRisk, riskLoadFailed, level)) {
      (true, _, _) => 'Checking current flood risk',
      (_, true, _) => 'Current risk information unavailable',
      (_, _, HomeFloodRiskLevel.high) => 'High risk: Avoid low-lying roads',
      (_, _, HomeFloodRiskLevel.watch) => 'Flood watch: Stay alert',
      _ => 'Clear: Stay updated',
    };
    final message = switch ((isLoadingRisk, riskLoadFailed, level)) {
      (true, _, _) => 'Reviewing recent reports and official advisories.',
      (_, true, _) => 'Pull down to retry before making safety decisions.',
      (_, _, HomeFloodRiskLevel.high) =>
        'Check the map before travelling and keep emergency items ready.',
      (_, _, HomeFloodRiskLevel.watch) =>
        'Monitor official advisories and avoid flood-prone routes.',
      _ => 'Monitor alerts and keep your safety essentials within reach.',
    };

    return RainGuardCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              level == HomeFloodRiskLevel.high
                  ? Icons.alt_route_rounded
                  : level == HomeFloodRiskLevel.watch
                  ? Icons.visibility_outlined
                  : Icons.check_circle_outline_rounded,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: RainGuardColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
