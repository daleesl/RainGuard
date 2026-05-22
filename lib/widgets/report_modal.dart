import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../theme/rainguard_theme.dart';
import '../utils/location_constants.dart';
import '../utils/map_helper.dart';
import 'settings/verification_sheet.dart';

enum _ReportLocationMode { gps, manual }

class ReportModal extends StatefulWidget {
  const ReportModal({super.key});

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  static const int _maxImages = 5;

  ReportType selectedType = ReportType.rain;
  String? selectedFloodLevel;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  final List<XFile> _pickedImages = [];
  _ReportLocationMode _locationMode = _ReportLocationMode.gps;
  LatLng? _manualLocation;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final remainingSlots = _maxImages - _pickedImages.length;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can attach up to 5 photos.')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (!mounted) return;

    if (images.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(images.take(remainingSlots));
      });
    }
  }

  void _removeImage(XFile image) {
    setState(() => _pickedImages.remove(image));
  }

  Future<void> _openManualLocationPicker() async {
    final selectedLocation = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ManualLocationPicker(
          initialPoint:
              _manualLocation ??
              const LatLng(
                RainGuardCoverage.calambaMapLatitude,
                RainGuardCoverage.calambaMapLongitude,
              ),
        );
      },
    );

    if (!mounted || selectedLocation == null) return;
    setState(() {
      _locationMode = _ReportLocationMode.manual;
      _manualLocation = selectedLocation;
    });
  }

  void _useCurrentGpsLocation() {
    setState(() => _locationMode = _ReportLocationMode.gps);
  }

  Future<void> _submitReport({bool skipDuplicateCheck = false}) async {
    if (_locationMode == _ReportLocationMode.manual &&
        _manualLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a location on the map first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ReportService.submitCommunityReport(
        type: selectedType,
        floodLevel: selectedFloodLevel,
        description: _descriptionController.text,
        images: _pickedImages,
        manualLocation: _locationMode == _ReportLocationMode.manual
            ? _manualLocation
            : null,
        skipDuplicateCheck: skipDuplicateCheck,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is DuplicateReportException) {
          setState(() => _isSubmitting = false);
          final shouldContinue = await _showDuplicateReportDialog(e);
          if (!mounted || shouldContinue != true) return;
          await _submitReport(skipDuplicateCheck: true);
          return;
        }

        if (e is ReportVerificationRequiredException) {
          setState(() => _isSubmitting = false);
          final shouldVerify = await _showVerificationRequiredDialog(e.status);
          if (!mounted || shouldVerify != true) return;
          _showVerificationSheet();
          return;
        }

        if (e is ReportSavedAsDraftException) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Connection issue. Report saved as draft and will retry.',
              ),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showVerificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VerificationSheet(),
    );
  }

  Future<bool?> _showVerificationRequiredDialog(String status) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Verification required',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          content: Text(
            _verificationMessage(status),
            style: const TextStyle(fontSize: 10, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verify ID'),
            ),
          ],
        );
      },
    );
  }

  String _verificationMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Your ID is still pending admin review. You can submit reports once an admin approves your account.';
      case 'rejected':
        return 'Your ID verification was rejected. Upload a clearer valid ID photo before submitting reports.';
      case 'unverified':
      default:
        return 'Only verified users can submit community reports. Upload a valid ID photo first.';
    }
  }

  Future<bool?> _showDuplicateReportDialog(
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
                      color: RainGuardColors.softBlue.withOpacity(0.55),
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

  Widget _buildTypeCard(ReportType type, {required double width}) {
    final isSelected = selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          selectedType = type;
          if (selectedType != ReportType.flood) selectedFloodLevel = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? RainGuardColors.softBlue : Colors.white,
          border: Border.all(
            color: isSelected ? RainGuardColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              MapHelper.getReportIcon(type),
              color: isSelected ? RainGuardColors.primary : Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                MapHelper.getReportTypeName(type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? RainGuardColors.primary : Colors.black87,
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickedImage(XFile image, int index) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: kIsWeb
                ? Image.network(image.path, fit: BoxFit.cover)
                : Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 7,
          left: 7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.58),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black.withOpacity(0.58),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _removeImage(image),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    if (_pickedImages.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: RainGuardColors.softBlue.withOpacity(0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: RainGuardColors.primary.withOpacity(0.28),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: RainGuardColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap to add report photos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RainGuardColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Attach up to 5 clear images if it is safe to take them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pickedImages.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            return _buildPickedImage(_pickedImages[index], index);
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RainGuardColors.softBlue.withOpacity(0.54),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: RainGuardColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_pickedImages.length} photo${_pickedImages.length == 1 ? '' : 's'} attached',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RainGuardColors.ink,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        _pickedImages.length >= _maxImages ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Add more'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RainGuardColors.primary,
                      side: const BorderSide(color: RainGuardColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _pickedImages.clear();
                    }),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Remove all'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LocationChoiceCard(
                icon: Icons.my_location_rounded,
                label: 'Current GPS',
                isSelected: _locationMode == _ReportLocationMode.gps,
                onTap: _useCurrentGpsLocation,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocationChoiceCard(
                icon: Icons.add_location_alt_outlined,
                label: 'Choose on map',
                isSelected: _locationMode == _ReportLocationMode.manual,
                onTap: _openManualLocationPicker,
              ),
            ),
          ],
        ),
        if (_locationMode == _ReportLocationMode.manual) ...[
          const SizedBox(height: 10),
          _ManualLocationSummary(
            location: _manualLocation,
            onChangeTap: _openManualLocationPicker,
          ),
        ],
      ],
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Share your observations to help the community stay safe',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
            ),
            const SizedBox(height: 20),

            // Report Type Selection
            const Text(
              'Report Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 10) / 2;

                return Row(
                  children: [
                    _buildTypeCard(ReportType.rain, width: cardWidth),
                    const SizedBox(width: 10),
                    _buildTypeCard(ReportType.flood, width: cardWidth),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Conditional flood level dropdown
            if (selectedType == ReportType.flood) ...[
              const Text(
                'Flood Level',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedFloodLevel,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items:
                    [
                          'ankle level',
                          'knee level',
                          'waist level',
                          'above waist level',
                        ]
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s[0].toUpperCase() + s.substring(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => selectedFloodLevel = v),
              ),
              const SizedBox(height: 16),
            ],

            // Location
            _buildLocationSection(),

            const SizedBox(height: 20),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Describe the situation...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildPhotoUploadSection(),

            const SizedBox(height: 25),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RainGuardColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

class _LocationChoiceCard extends StatelessWidget {
  const _LocationChoiceCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? RainGuardColors.softBlue.withOpacity(0.78)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? RainGuardColors.primary
                  : RainGuardColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? RainGuardColors.primary
                    : RainGuardColors.secondaryText,
                size: 19,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected
                          ? RainGuardColors.primary
                          : RainGuardColors.ink,
                      fontSize: 10,
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
  }
}

class _ManualLocationSummary extends StatelessWidget {
  const _ManualLocationSummary({
    required this.location,
    required this.onChangeTap,
  });

  final LatLng? location;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final coordinateText = location == null
        ? 'No map point selected yet'
        : '${location!.latitude.toStringAsFixed(5)}, ${location!.longitude.toStringAsFixed(5)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RainGuardColors.warningFill.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RainGuardColors.warningText.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            location == null
                ? Icons.location_searching_rounded
                : Icons.location_on_rounded,
            color: RainGuardColors.warningText,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manually selected location',
                  style: TextStyle(
                    color: RainGuardColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  coordinateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RainGuardColors.secondaryText,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeTap,
            style: TextButton.styleFrom(
              foregroundColor: RainGuardColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
            ),
            child: Text(location == null ? 'Choose' : 'Change'),
          ),
        ],
      ),
    );
  }
}

class _ManualLocationPicker extends StatefulWidget {
  const _ManualLocationPicker({required this.initialPoint});

  final LatLng initialPoint;

  @override
  State<_ManualLocationPicker> createState() => _ManualLocationPickerState();
}

class _ManualLocationPickerState extends State<_ManualLocationPicker> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.58,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: RainGuardColors.homeIndicator,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: RainGuardColors.softBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add_location_alt_rounded,
                      color: RainGuardColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose report location',
                          style: TextStyle(
                            color: RainGuardColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tap the map where the report happened.',
                          style: TextStyle(
                            color: RainGuardColors.secondaryText,
                            fontSize: 8,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 360,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: widget.initialPoint,
                      initialZoom: RainGuardCoverage.calambaMapZoom,
                      onTap: (_, point) {
                        setState(() => _selectedPoint = point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.rainguard',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 54,
                            height: 54,
                            point: _selectedPoint,
                            child: const Icon(
                              Icons.location_pin,
                              color: RainGuardColors.primary,
                              size: 46,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RainGuardColors.softBlue.withOpacity(0.58),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      color: RainGuardColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedPoint.latitude.toStringAsFixed(5)}, '
                        '${_selectedPoint.longitude.toStringAsFixed(5)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RainGuardColors.ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedPoint),
                  style: FilledButton.styleFrom(
                    backgroundColor: RainGuardColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Use this location',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
