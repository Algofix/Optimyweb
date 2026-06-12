import 'package:flutter/material.dart';

/// Shows a project's cover image (16:9) with a button to upload/replace it.
class ProjectCover extends StatelessWidget {
  const ProjectCover({
    super.key,
    required this.imageUrl,
    required this.uploading,
    required this.onUpload,
  });

  final String? imageUrl;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(theme),
                    )
                  : _placeholder(theme),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: uploading ? null : onUpload,
            icon: uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    hasImage
                        ? Icons.image_outlined
                        : Icons.add_photo_alternate_outlined,
                  ),
            label: Text(
              uploading
                  ? 'Uploading…'
                  : (hasImage ? 'Change cover image' : 'Upload cover image'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(ThemeData theme) => Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: theme.colorScheme.outline,
        ),
      );
}
