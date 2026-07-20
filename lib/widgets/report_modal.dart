import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/report_model.dart';
import '../services/geocoding_service.dart';
import '../services/report_service.dart';
import '../utils/location_constants.dart';
import 'report/manual_location_picker.dart';
import 'report/duplicate_report_dialog.dart';
import 'report/report_location_section.dart';
import 'report/report_modal_sections.dart';
import 'report/report_type_section.dart';
import 'report/verification_required_dialog.dart';
import 'settings/verification_sheet.dart';

class ReportModal extends StatefulWidget {
  const ReportModal({super.key});

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  static const int _maxImages = 5;
  static const double _maxPickedImageDimension = 1600;
  static const int _pickedImageQuality = 82;

  ReportType selectedType = ReportType.rain;
  String? selectedFloodLevel;
  String? selectedRainIntensity;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  final List<XFile> _pickedImages = [];
  ReportLocationMode _locationMode = ReportLocationMode.gps;
  LatLng? _manualLocation;
  String? _manualLocationName;
  bool _isResolvingManualLocation = false;

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
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: _pickedImageQuality,
      maxHeight: _maxPickedImageDimension,
      maxWidth: _maxPickedImageDimension,
    );
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
        return ManualLocationPicker(
          initialPoint:
              _manualLocation ??
              const LatLng(
                RainGuardCoverage.mapLatitude,
                RainGuardCoverage.mapLongitude,
              ),
        );
      },
    );

    if (!mounted || selectedLocation == null) return;
    setState(() {
      _locationMode = ReportLocationMode.manual;
      _manualLocation = selectedLocation;
      _manualLocationName = null;
      _isResolvingManualLocation = true;
    });
    await _resolveManualLocationName(selectedLocation);
  }

  void _useCurrentGpsLocation() {
    setState(() {
      _locationMode = ReportLocationMode.gps;
      _isResolvingManualLocation = false;
    });
  }

  Future<void> _resolveManualLocationName(LatLng location) async {
    final locationKey = _locationKey(location);

    try {
      final resolvedName = await GeocodingService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (!mounted || _locationKey(_manualLocation) != locationKey) return;

      setState(() {
        _manualLocationName = _isUsefulLocationName(resolvedName)
            ? resolvedName
            : null;
        _isResolvingManualLocation = false;
      });
    } catch (_) {
      if (!mounted || _locationKey(_manualLocation) != locationKey) return;
      setState(() {
        _manualLocationName = null;
        _isResolvingManualLocation = false;
      });
    }
  }

  static String _locationKey(LatLng? location) {
    if (location == null) return '';
    return '${location.latitude.toStringAsFixed(5)},'
        '${location.longitude.toStringAsFixed(5)}';
  }

  static bool _isUsefulLocationName(String value) {
    final cleanValue = value.trim();
    return cleanValue.isNotEmpty &&
        cleanValue != 'Unknown Location' &&
        cleanValue != 'Location Error';
  }

  String? _missingRequiredObservationMessage() {
    if (selectedType == ReportType.rain &&
        (selectedRainIntensity == null ||
            selectedRainIntensity!.trim().isEmpty)) {
      return 'Please select the rain intensity.';
    }

    if (selectedType == ReportType.flood &&
        (selectedFloodLevel == null || selectedFloodLevel!.trim().isEmpty)) {
      return 'Please select the estimated flood water level.';
    }

    return null;
  }

  Future<void> _submitReport({bool skipDuplicateCheck = false}) async {
    final missingObservationMessage = _missingRequiredObservationMessage();
    if (missingObservationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(missingObservationMessage)));
      return;
    }

    if (_locationMode == ReportLocationMode.manual && _manualLocation == null) {
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
        rainIntensity: selectedRainIntensity,
        description: _descriptionController.text,
        images: _pickedImages,
        manualLocation: _locationMode == ReportLocationMode.manual
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
          final shouldContinue = await DuplicateReportDialog.show(context, e);
          if (!mounted || shouldContinue != true) return;
          await _submitReport(skipDuplicateCheck: true);
          return;
        }

        if (e is ReportVerificationRequiredException) {
          setState(() => _isSubmitting = false);
          final shouldVerify = await VerificationRequiredDialog.show(
            context,
            e.status,
          );
          if (!mounted || shouldVerify != true) return;
          _showVerificationSheet();
          return;
        }

        if (e is ReportCooldownException) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
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
            const ReportModalHeader(),
            const SizedBox(height: 20),

            ReportTypeSection(
              selectedFloodLevel: selectedFloodLevel,
              selectedRainIntensity: selectedRainIntensity,
              selectedType: selectedType,
              onFloodLevelChanged: (value) {
                setState(() => selectedFloodLevel = value);
              },
              onRainIntensityChanged: (value) {
                setState(() => selectedRainIntensity = value);
              },
              onTypeChanged: (type) {
                setState(() {
                  selectedType = type;
                  if (selectedType != ReportType.flood) {
                    selectedFloodLevel = null;
                  }
                  if (selectedType != ReportType.rain) {
                    selectedRainIntensity = null;
                  }
                });
              },
            ),

            // Location
            ReportLocationSection(
              mode: _locationMode,
              manualLocation: _manualLocation,
              manualLocationName: _manualLocationName,
              isResolvingManualLocation: _isResolvingManualLocation,
              onChooseManualLocation: _openManualLocationPicker,
              onUseCurrentGps: _useCurrentGpsLocation,
            ),

            const SizedBox(height: 20),

            ReportDescriptionField(controller: _descriptionController),

            const SizedBox(height: 20),

            ReportPhotoInputSection(
              images: _pickedImages,
              maxImages: _maxImages,
              onAddImages: _pickImage,
              onClearImages: () => setState(() => _pickedImages.clear()),
              onRemoveImage: _removeImage,
            ),

            const SizedBox(height: 25),

            ReportSubmitButton(
              isSubmitting: _isSubmitting,
              onSubmit: () => _submitReport(),
            ),
            const SizedBox(height: 10), // Padding below button for modal
          ],
        ),
      ),
    );
  }
}
