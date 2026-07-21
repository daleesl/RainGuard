import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../utils/map_helper.dart';

class IntelligentPin extends StatelessWidget {
  final Report report;

  const IntelligentPin({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final reportColor = MapHelper.getReportColor(report);
    final reportOpacity = MapHelper.getReportOpacity(report);
    final reportIcon = MapHelper.getReportIcon(report.type);
    final isFlood = report.type == ReportType.flood;

    return Opacity(
      opacity: reportOpacity,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: isFlood ? 40 : 36,
                  height: isFlood ? 40 : 36,
                  decoration: BoxDecoration(
                    color: reportColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: reportColor.withValues(
                          alpha: isFlood ? 0.34 : 0.22,
                        ),
                        blurRadius: isFlood ? 12 : 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2.4),
                  ),
                  child: Center(
                    child: Icon(reportIcon, color: Colors.white, size: 18),
                  ),
                ),
                if (report.isAdminVerified)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.shade600,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.green.shade700,
                        size: 11,
                      ),
                    ),
                  ),
                if (report.isMutedOnMap)
                  Positioned(
                    left: -1,
                    bottom: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blueGrey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: Colors.blueGrey.shade500,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            Container(
              width: 6,
              height: 8,
              decoration: BoxDecoration(
                color: reportColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
