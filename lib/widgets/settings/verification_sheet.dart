import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/storage_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/rainguard_theme.dart';

class VerificationSheet extends StatefulWidget {
  const VerificationSheet({super.key});

  @override
  State<VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<VerificationSheet> {
  final ImagePicker _picker = ImagePicker();
  XFile? _idPhoto;
  bool _isSubmitting = false;

  Future<void> _pickIdPhoto(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (photo == null || !mounted) return;

    setState(() {
      _idPhoto = photo;
    });
  }

  Future<void> _submitVerification() async {
    final idPhoto = _idPhoto;
    final user = FirebaseAuth.instance.currentUser;

    if (idPhoto == null || user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final idUrl = await StorageService.uploadVerificationImage(
        image: idPhoto,
        uid: user.uid,
        type: 'id_front',
      );

      await UserProfileService.submitVerificationRequest(
        idFrontUrl: idUrl,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted for review.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit verification: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _idPhoto != null && !_isSubmitting;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: RainGuardColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Verify your identity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: RainGuardColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit a clear valid ID photo so admins can approve your reporting access.',
                style: TextStyle(
                  color: RainGuardColors.secondaryText,
                  fontSize: 8,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _VerificationUploadCard(
                icon: Icons.badge_outlined,
                label: 'Valid ID photo',
                photo: _idPhoto,
                subtitle: 'Barangay ID, school ID, national ID, or any ID with your name',
                onCameraTap: () => _pickIdPhoto(ImageSource.camera),
                onGalleryTap: () => _pickIdPhoto(ImageSource.gallery),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RainGuardColors.softBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: RainGuardColors.primary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your ID photo is uploaded privately and used only to review reporting access.',
                        style: TextStyle(
                          color: Color(0xFF0B3A5B),
                          fontSize: 8,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: RainGuardColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: canSubmit ? _submitVerification : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit for review',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
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

class _VerificationUploadCard extends StatelessWidget {
  const _VerificationUploadCard({
    required this.icon,
    required this.label,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.photo,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final XFile? photo;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;

    return Material(
      color: Colors.transparent,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasPhoto ? RainGuardColors.primary : RainGuardColors.border,
            width: hasPhoto ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _PhotoPreview(photo: photo, icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: RainGuardColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasPhoto ? 'ID photo ready. You can retake or replace it.' : subtitle,
                        style: const TextStyle(
                          color: RainGuardColors.secondaryText,
                          fontSize: 8,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasPhoto ? Icons.check_circle_rounded : Icons.badge_outlined,
                  color: hasPhoto ? Colors.green.shade700 : RainGuardColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCameraTap,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RainGuardColors.primary,
                      side: const BorderSide(color: RainGuardColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onGalleryTap,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                    style: FilledButton.styleFrom(
                      backgroundColor: RainGuardColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.icon, required this.photo});

  final IconData icon;
  final XFile? photo;

  @override
  Widget build(BuildContext context) {
    final currentPhoto = photo;

    return Container(
      width: 74,
      height: 74,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: RainGuardColors.softBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RainGuardColors.border),
      ),
      child: currentPhoto == null
          ? Icon(icon, color: RainGuardColors.primary, size: 30)
          : kIsWeb
              ? FutureBuilder<Uint8List>(
                  future: currentPhoto.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  },
                )
              : Image.file(File(currentPhoto.path), fit: BoxFit.cover),
    );
  }
}
