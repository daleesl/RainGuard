import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';
import '../utils/map_helper.dart';

class ReportModal extends StatefulWidget {
  const ReportModal({super.key});

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  ReportType selectedType = ReportType.rain;
  String? selectedFloodLevel;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String _fileName = "No file chosen";
  XFile? _pickedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _fileName = image.name;
        _pickedImage = image;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      Position position = await _determinePosition();
      // Upload image (if any) to Firebase Storage first
      String? downloadUrl;
      if (_pickedImage != null) {
        final storageRef = FirebaseStorage.instance.ref();
        
        // Clean the file name to avoid any special character issues in Firebase
        String cleanName = _pickedImage!.name.replaceAll(RegExp(r'[^a-zA-Z0-9\.]'), '_');
        String path = 'reports/${DateTime.now().millisecondsSinceEpoch}_$cleanName';
        final fileRef = storageRef.child(path);
        
        try {
          // Define metadata for ALL platforms to ensure the image displays properly
          final metadata = SettableMetadata(
            contentType: _pickedImage!.mimeType ?? 'image/jpeg',
          );

          TaskSnapshot snapshot;
          // Use kIsWeb to seamlessly route between Mobile (Android/iOS) and Web
          if (!kIsWeb && _pickedImage!.path.isNotEmpty) {
            // For Android and iOS: Stream directly from the local file storage (Best Performance)
            snapshot = await fileRef.putFile(File(_pickedImage!.path), metadata);
          } else {
            // For Web: Read bytes into memory since browsers don't have direct filesystem access
            final bytes = await _pickedImage!.readAsBytes();
            snapshot = await fileRef.putData(bytes, metadata);
          }
          
          // Get the URL safely from the snapshot directly indicating it actually reached the server
          downloadUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          debugPrint("Firebase Storage Upload Error: $e");
          String errorMsg = e.toString();
          if (errorMsg.contains('object-not-found')) {
             throw Exception("Upload silently failed. Check Firebase Storage Rules (must allow read/write).");
          }
          throw Exception("Failed to upload image: $e");
        }
      }

      // Determine current user id if any
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      // Creating the standard report data map
      Map<String, dynamic> reportData = {
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'report_type': selectedType.name,
        'flood_level': selectedType == ReportType.flood ? selectedFloodLevel : null,
        'risk_level': RiskLevel.risk.name,
        'description': _descriptionController.text.trim(),
        'image_url': downloadUrl,
        'created_at': Timestamp.fromDate(DateTime.now()),
      };

      await FirebaseFirestore.instance.collection('reports').add(reportData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildTypeCard(ReportType type) {
    bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
        });
      },
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MapHelper.getReportIcon(type),
              color: isSelected ? Colors.blue : Colors.black54,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              MapHelper.getReportTypeName(type),
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Report Update',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Share your observations to help the community stay safe',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // Report Type Selection (icon-based dropdown)
            const Text(
              'Report Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ReportType>(
              initialValue: selectedType,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              items: ReportType.values.map((type) {
                return DropdownMenuItem<ReportType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(MapHelper.getReportIcon(type), color: Colors.black54),
                      const SizedBox(width: 10),
                      Text(MapHelper.getReportTypeName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedType = v ?? ReportType.rain;
                  if (selectedType != ReportType.flood) selectedFloodLevel = null;
                });
              },
            ),

            const SizedBox(height: 16),

            // Conditional flood level dropdown
            if (selectedType == ReportType.flood) ...[
              const Text('Flood Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedFloodLevel,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                items: [
                  'ankle level',
                  'knee level',
                  'waist level',
                  'above waist level',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
                onChanged: (v) => setState(() => selectedFloodLevel = v),
              ),
              const SizedBox(height: 16),
            ],

            // Location
            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: "Current Location",
              readOnly: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),
            
            // Description
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Describe the situation...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // Upload Photo
            const Text(
              'Upload Photo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (_pickedImage != null) ...[
              // preview
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade50,
                ),
                clipBehavior: Clip.hardEdge,
                child: kIsWeb
                    ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                    : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.shade700),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => setState(() { _pickedImage = null; _fileName = 'No file chosen'; }),
                    child: const Text('Remove'),
                  )
                ],
              ),
            ] else ...[
              InkWell(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: Colors.black54),
                      const SizedBox(width: 12),
                      const Text('Choose photo from gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(_fileName, style: TextStyle(color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 25),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 10), // Padding below button for modal
          ],
        ),
      ),
    );
  }
}
