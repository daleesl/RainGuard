import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../utils/map_helper.dart';

class IntelligentPin extends StatelessWidget {
  final Report report;

  const IntelligentPin({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    Color riskColor = MapHelper.getRiskColor(report.risk);
    IconData reportIcon = MapHelper.getReportIcon(report.type);

    return SizedBox(
      width: 44,
      height: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pin head
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: riskColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: const Offset(0, 2)),
              ],
              border: Border.all(color: Colors.white, width: 2.0),
            ),
            child: Center(
              child: Icon(reportIcon, color: Colors.white, size: 18),
            ),
          ),
          // Pin tail
          Container(
            width: 6,
            height: 8,
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
