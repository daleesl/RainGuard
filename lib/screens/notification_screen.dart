import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../utils/map_helper.dart';
import '../widgets/report_details_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent.shade400,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'RainGuard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading notifications'));
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1, // +1 for the header
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                );
              }

              final doc = docs[index - 1];
              Report report;
              try {
                report = Report.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
              } catch (e) {
                return const SizedBox.shrink(); // Skip unparseable reports
              }

              return _buildNotificationCard(context, report);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Report report) {
    // Determine colors matching the screenshot style based on risk level
    Color cardColor;
    Color iconColor;
    Color pillColor;
    
    if (report.risk == RiskLevel.flood) {
      cardColor = Colors.red.shade100.withOpacity(0.5);
      iconColor = Colors.red.shade800;
      pillColor = Colors.red.shade200.withOpacity(0.5);
    } else if (report.risk == RiskLevel.risk || report.type == ReportType.rain) {
      cardColor = Colors.amber.shade100.withOpacity(0.5);
      iconColor = Colors.orange.shade800;
      pillColor = Colors.amber.shade200.withOpacity(0.5);
    } else {
      cardColor = Colors.green.shade100.withOpacity(0.5);
      iconColor = Colors.green.shade800;
      pillColor = Colors.green.shade200.withOpacity(0.5);
    }

    final String timeAgoString = timeago.format(report.createdAt);
    
    // Description text processing
    String descriptionText = report.description.isNotEmpty 
        ? report.description 
        : "${MapHelper.getReportTypeName(report.type)} reported in the area.";

    // Get report title
    String titleText = '${MapHelper.getReportTypeName(report.type)} Detected';

    return GestureDetector(
      onTap: () {
        ReportDetailsDialog.show(context, report);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.black87),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reported by ${report.userId ?? 'User'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              descriptionText,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (report.floodLevel != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${report.floodLevel}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.access_time, size: 14, color: Colors.black87),
                const SizedBox(width: 4),
                Text(
                  timeAgoString,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}