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

  final LatLng _initialCenter = const LatLng(14.212601, 121.181149);
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
              const Divider(height: 30),
              
              // Image Section
              if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                Container(
                  height: 180,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(report.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
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

              // Details Section
              _buildDetailRow(Icons.warning_amber_rounded, 'Risk Level', MapHelper.getRiskLevelName(report.risk)),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on_outlined, 'Location', '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}'),
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
                                  width: 40.0,
                                  height: 40.0,
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
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.blueAccent.shade400,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
      
        },
      ),
    );
  }
}
