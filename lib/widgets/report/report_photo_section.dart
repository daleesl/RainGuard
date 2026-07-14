import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/rainguard_theme.dart';

class ReportPhotoSection extends StatelessWidget {
  const ReportPhotoSection({
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
    if (images.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAddImages,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: RainGuardColors.softBlue.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: RainGuardColors.primary.withValues(alpha: 0.28),
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
          itemCount: images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            return _PickedReportImage(
              image: images[index],
              index: index,
              onRemove: onRemoveImage,
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RainGuardColors.softBlue.withValues(alpha: 0.54),
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
                      '${images.length} photo${images.length == 1 ? '' : 's'} attached',
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
                    onPressed: images.length >= maxImages ? null : onAddImages,
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
                    onPressed: onClearImages,
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
}

class _PickedReportImage extends StatelessWidget {
  const _PickedReportImage({
    required this.image,
    required this.index,
    required this.onRemove,
  });

  final XFile image;
  final int index;
  final ValueChanged<XFile> onRemove;

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withValues(alpha: 0.58),
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
            color: Colors.black.withValues(alpha: 0.58),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onRemove(image),
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
}
