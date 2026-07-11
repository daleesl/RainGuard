import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/report_model.dart';
import '../theme/rainguard_theme.dart';
import '../utils/map_helper.dart';

part 'report_details/report_details_components.dart';
part 'report_details/report_details_sheet.dart';
part 'report_details/report_image_gallery.dart';

class ReportDetailsDialog {
  static void show(BuildContext context, Report report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportDetailsSheet(report: report),
    );
  }
}
