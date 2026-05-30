import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/report_draft.dart';
import '../../theme/rainguard_theme.dart';
import '../../utils/map_helper.dart';

class PendingDraftSheet extends StatelessWidget {
  const PendingDraftSheet({
    super.key,
    required this.draft,
    required this.onRetryTap,
    required this.isRetrying,
  });

  final ReportDraft draft;
  final VoidCallback onRetryTap;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final typeName = MapHelper.getReportTypeName(draft.type);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: RainGuardColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.amber.shade800.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.schedule_send_outlined,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending $typeName report',
                      style: const TextStyle(
                        color: RainGuardColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Saved locally. It will appear to others after upload.',
                      style: TextStyle(
                        color: RainGuardColors.secondaryText,
                        fontSize: 8,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            draft.description.isEmpty
                ? 'No description added.'
                : draft.description,
            style: const TextStyle(
              color: RainGuardColors.ink,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _PendingDraftMetaPill(
            color: Colors.amber.shade800,
            icon: Icons.access_time_rounded,
            label: timeago.format(draft.createdAt),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isRetrying ? null : onRetryTap,
              style: FilledButton.styleFrom(
                backgroundColor: RainGuardColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(
                isRetrying ? 'Retrying upload...' : 'Retry upload now',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep this draft until upload succeeds. It will be removed automatically after RainGuard saves it online.',
            style: TextStyle(
              color: RainGuardColors.secondaryText,
              fontSize: 8,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingDraftMetaPill extends StatelessWidget {
  const _PendingDraftMetaPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
