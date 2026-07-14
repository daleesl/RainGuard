import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/rainguard_theme.dart';
import 'report_photo_section.dart';

class ReportModalHeader extends StatelessWidget {
  const ReportModalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }
}

class ReportDescriptionField extends StatelessWidget {
  const ReportDescriptionField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
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
      ],
    );
  }
}

class ReportPhotoInputSection extends StatelessWidget {
  const ReportPhotoInputSection({
    required this.images,
    required this.maxImages,
    required this.onAddImages,
    required this.onClearImages,
    required this.onRemoveImage,
    super.key,
  });

  final List<XFile> images;
  final int maxImages;
  final VoidCallback onAddImages;
  final VoidCallback onClearImages;
  final ValueChanged<XFile> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Photo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ReportPhotoSection(
          images: images,
          maxImages: maxImages,
          onAddImages: onAddImages,
          onClearImages: onClearImages,
          onRemoveImage: onRemoveImage,
        ),
      ],
    );
  }
}

class ReportSubmitButton extends StatelessWidget {
  const ReportSubmitButton({
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: RainGuardColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isSubmitting
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
