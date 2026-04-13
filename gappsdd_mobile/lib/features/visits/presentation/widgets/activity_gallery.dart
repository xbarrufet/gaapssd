import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/client_visits_data.dart';

class ActivityGallery extends StatelessWidget {
  const ActivityGallery({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onPhotoTap,
  });

  final List<LocalVisitPhoto> photos;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;
  final Function(LocalVisitPhoto) onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _AddPhotoTile(onTap: onAddPhoto);
        }

        final photo = photos[index - 1];
        return _PhotoTile(
          photo: photo,
          onRemove: () => onRemovePhoto(photo.id),
          onTap: () => onPhotoTap(photo),
        );
      },
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.add,
              size: 34,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.onRemove,
    required this.onTap,
  });

  final LocalVisitPhoto photo;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
        errorBuilder: (context, err, stack) => Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
        ),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return Center(
      child: Icon(Icons.image_rounded, color: AppColors.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thumbPath = photo.thumbnailPath.isNotEmpty ? photo.thumbnailPath : photo.localPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.surfaceHigh),
          _buildImage(thumbPath),
          // Tap target for full-screen
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),
          // Remove button
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
