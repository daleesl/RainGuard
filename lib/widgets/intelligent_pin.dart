import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../utils/map_helper.dart';

class IntelligentPin extends StatelessWidget {
  final Report report;

  const IntelligentPin({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color riskColor = MapHelper.getRiskColor(report.risk);
    IconData reportIcon = MapHelper.getReportIcon(report.type);

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [

          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              )
            ),
          ),
          // Foreground Icon (Report Type)
          Icon(
            reportIcon,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }
}
