import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileImageCard extends StatelessWidget {
  const ProfileImageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.url,
    required this.type,
    required this.enabled,
    required this.onAddImage,
  });

  final String title;
  final String subtitle;
  final File? file;
  final String? url;
  final String type;
  final bool enabled;
  final VoidCallback onAddImage;

  static const Color green = Color(0xFF16A34A);
  static const Color text = Color(0xFF263746);
  static const Color muted = Color(0xFF7A8289);

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        file != null ||
        (url != null && url!.trim().isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: hasImage
              ? green.withOpacity(.35)
              : const Color(0xFFE0E5E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasImage
                      ? const Color(0xFFEAF7EF)
                      : const Color(0xFFFFF3EC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  hasImage
                      ? Icons.check_circle_rounded
                      : Icons.image_outlined,
                  color: hasImage
                      ? green
                      : AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasImage ? 'Image ready' : subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasImage ? green : muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasImage) ...[
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 165,
                child: file != null
                    ? Image.file(
                        file!,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        url!,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }

                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5F7F8),
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Unable to load image URL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              onPressed: enabled ? onAddImage : null,
              icon: Icon(
                hasImage
                    ? Icons.refresh_rounded
                    : Icons.add_photo_alternate_outlined,
                size: 19,
              ),
              label: Text(
                hasImage ? 'Change Image' : 'Add Image',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withOpacity(.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
