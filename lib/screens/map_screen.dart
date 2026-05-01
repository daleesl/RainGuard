import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../widgets/intelligent_pin.dart';
import '../widgets/report_modal.dart';
import '../utils/map_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final LatLng _initialCenter = const LatLng(14.2050462, 121.1582127);
  final MapController _mapController = MapController();

  void _showReportDetails(Report report) {
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
              
              // Image Section (with loading and error fallback)
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddReportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const ReportModal(),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecentReportItem(Color color, String title, String subtitle, String timeStr) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'RainGuard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent.shade400,
        iconTheme: const IconThemeData(color: Colors.white), // For drawer if added
      ),
      drawer: const Drawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              'Flood Map',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          
        
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.rainguard',
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
                      builder: (context, snapshot) {
                        List<Marker> markers = [];
                        
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            try {
                              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                              Report report = Report.fromFirestore(data, doc.id);
                              
                              markers.add(
                                Marker(
                                  width: 60.0,
                                  height: 60.0,
                                  point: LatLng(report.latitude, report.longitude),
                                  child: GestureDetector(
                                    onTap: () => _showReportDetails(report),
                                    child: IntelligentPin(report: report),
                                  ),
                                ),
                              );
                            } catch (e) {
                              print("Error parsing document ${doc.id}: $e");
                            }
                          }
                        }

                        return MarkerLayer(
                          markers: markers,
                        );
                      },
                    ),
                  ],
                ),
            
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _showAddReportModal,
                    backgroundColor: Colors.blueAccent.shade400,
                    foregroundColor: Colors.white,
                    elevation: 4.0,
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ],
            ),
          ),
          
      
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Map Legend',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildLegendItem(Colors.red, 'Flood'),
                        const SizedBox(height: 12),
                        _buildLegendItem(Colors.yellowAccent.shade700, 'Risk'),
                        const SizedBox(height: 12),
                        _buildLegendItem(Colors.green, 'Safe'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recent Reports Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Reports',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentReportItem(
                          Colors.red, 
                          'Flood reported here', 
                          'Downtown Area', 
                          '10 mins ago'
                        ),
                        _buildRecentReportItem(
                          Colors.yellowAccent.shade700, 
                          'Risk are detected', 
                          'Low lying district', 
                          '10 mins ago'
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Navigation Bar is now handled by MainWrapper
    );
  }
}
