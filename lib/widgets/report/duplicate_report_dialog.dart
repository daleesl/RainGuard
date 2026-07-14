import 'package:flutter/material.dart';

import '../../services/report_service.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/map_helper.dart';

class DuplicateReportDialog {
  const DuplicateReportDialog._();

  static Future<bool?> show(
    BuildContext context,
    DuplicateReportException exception,
  ) {
    final reportName = MapHelper.getReportTypeName(exception.duplicate.type);

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: RainGuardColors.warningFill,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.report_problem_outlined,
                      color: RainGuardColors.warningText,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Similar report nearby',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RainGuardColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A $reportName report was already submitted near this area within the last 15 minutes.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RainGuardColors.secondaryText,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: RainGuardColors.softBlue.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Submit anyway only if your report adds new or urgent information.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RainGuardColors.ink,
                        fontSize: 9,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: RainGuardColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Submit Anyway',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: RainGuardColors.secondaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
