import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../utils/map_helper.dart';

class ReportDetailsDialog {
  static void show(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                Row(
                  children: [
                  Icon(
                    MapHelper.getReportIcon(report.type),
                    color: MapHelper.getRiskColor(report.risk),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    MapHelper.getReportTypeName(report.type),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 16),
              
              // Image Section
              Container(
                height: 220,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.hardEdge,
                child: report.imageUrl != null && report.imageUrl!.isNotEmpty
                    ? Image.network(
                        report.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400));
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40),
                            const SizedBox(height: 8),
                            Text('No image provided', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
              ),
              Center(child: Text('Image 1 of 1', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
              const SizedBox(height: 12),

              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Flood Level', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(report.floodLevel ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reported By', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Text(report.userId ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Details Section
              _buildDetailRow(Icons.warning_amber_rounded, 'Risk Level', MapHelper.getRiskLevelName(report.risk)),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.description_outlined, 'Description', report.description.isNotEmpty ? report.description : "No description provided"),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Time', report.createdAt.toString().split('.')[0]),
              
              const SizedBox(height: 24),
            
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  static Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            SizedBox(
              width: 200, // constrain width for description
              child: Text(value, style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ],
    );
  }
}
