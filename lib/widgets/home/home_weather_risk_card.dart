import 'package:flutter/material.dart';

import '../../models/home_risk_assessment.dart';
import '../../theme/rainguard_theme.dart';
import '../rainguard_card.dart';

class HomeWeatherRiskCard extends StatelessWidget {
  const HomeWeatherRiskCard({
    super.key,
    required this.isLoading,
    required this.temp,
    required this.description,
    required this.riskAssessment,
    required this.isLoadingRisk,
    required this.riskLoadFailed,
  });

  final bool isLoading;
  final String temp;
  final String description;
  final HomeRiskAssessment? riskAssessment;
  final bool isLoadingRisk;
  final bool riskLoadFailed;

  @override
  Widget build(BuildContext context) {
    final riskLevel = riskAssessment?.level;
    final hasActiveRisk = riskAssessment?.hasActiveRisk ?? false;
    final riskColor = riskLoadFailed
        ? Colors.red.shade700
        : switch (riskLevel) {
            HomeFloodRiskLevel.high => Colors.red.shade700,
            HomeFloodRiskLevel.watch => Colors.amber.shade800,
            HomeFloodRiskLevel.clear => Colors.green.shade700,
            null => RainGuardColors.primary,
          };
    final riskStatus = switch ((isLoadingRisk, riskLoadFailed, riskLevel)) {
      (true, _, _) => 'Checking current risk',
      (_, true, _) => 'Risk status unavailable',
      (_, _, HomeFloodRiskLevel.high) => 'Active flood risk',
      (_, _, HomeFloodRiskLevel.watch) => 'Flood watch',
      _ => 'Clear',
    };
    final riskDetail = switch ((isLoadingRisk, riskLoadFailed)) {
      (true, _) => 'Reviewing recent reports and official alerts',
      (_, true) => 'Pull to refresh current safety information',
      _ => riskAssessment?.reason ?? 'No current risk information',
    };
    final updateLabel = riskAssessment == null
        ? null
        : '${riskAssessment!.lastSourceUpdateAt == null ? 'Checked' : 'Updated'} '
              '${TimeOfDay.fromDateTime(riskAssessment!.lastUpdatedAt).format(context)}';

    return RainGuardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isLoading ? '-- \u00B0C' : temp,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            color: RainGuardColors.deepInk,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: RainGuardColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: RainGuardColors.softBlue,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Icon(
                    riskLevel == HomeFloodRiskLevel.high
                        ? Icons.thunderstorm_rounded
                        : riskLevel == HomeFloodRiskLevel.watch
                        ? Icons.water_drop_outlined
                        : Icons.wb_sunny_rounded,
                    size: 38,
                    color: hasActiveRisk
                        ? Colors.amber.shade700
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flood Risk Assessment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: RainGuardColors.ink,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        riskStatus,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: hasActiveRisk || riskLoadFailed
                              ? riskColor
                              : RainGuardColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        riskDetail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RainGuardColors.sectionLabel,
                          height: 1.3,
                          fontSize: 8,
                        ),
                      ),
                      if (updateLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          updateLabel,
                          style: const TextStyle(
                            color: RainGuardColors.muted,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 86,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        riskLevel == HomeFloodRiskLevel.high
                            ? Icons.warning_amber_rounded
                            : riskLevel == HomeFloodRiskLevel.watch
                            ? Icons.visibility_outlined
                            : Icons.shield_outlined,
                        color: riskColor,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoadingRisk
                            ? '...'
                            : riskLoadFailed
                            ? 'N/A'
                            : riskAssessment?.levelLabel ?? 'N/A',
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
