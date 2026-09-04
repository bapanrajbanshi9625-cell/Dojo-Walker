// File:
// lib/features/profile_setup/widgets/document_card2.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class DocumentCard2 extends StatelessWidget {
  const DocumentCard2({
    super.key,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.onTap,
    this.accentColor = AppColors.blue,
    this.icon = Icons.badge_rounded,
  });

  final String title;
  final String subtitle;
  final String? url;
  final VoidCallback? onTap;
  final Color accentColor;
  final IconData icon;

  bool get hasDocument {
    final String value = url?.trim() ?? '';
    return value.isNotEmpty;
  }

  @override
Widget build(BuildContext context) {
  final bool added = hasDocument;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: added
                ? AppColors.green.withValues(alpha: 0.45)
               : AppColors.border,
              width: added ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              // ==================================================
              // DOCUMENT PREVIEW / ICON
              // ==================================================

              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: added
                      ? AppColors.green.withOpacity(.08)
                      : accentColor.withOpacity(.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: added
                        ? AppColors.green.withOpacity(.18)
                        : accentColor.withOpacity(.12),
                  ),
                ),
                child: added
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          url!,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          loadingBuilder: (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  value: loadingProgress
                                              .expectedTotalBytes !=
                                          null
                                      ? loadingProgress
                                              .cumulativeBytesLoaded /
                                          loadingProgress
                                              .expectedTotalBytes!
                                      : null,
                                  color: AppColors.green,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Icon(
                              Icons.image_not_supported_rounded,
                              color: AppColors.green,
                              size: 29,
                            );
                          },
                        ),
                      )
                    : Icon(
                        icon,
                        color: accentColor,
                        size: 29,
                      ),
              ),

              const SizedBox(width: 13),

              // ==================================================
              // TEXT
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      added
                          ? 'Photo uploaded • Tap to change'
                          : subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: added
                            ? AppColors.green
                            : AppColors.muted,
                        fontWeight: added
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),

                    if (!added) ...[
                      const SizedBox(height: 9),

                      // ==================================================
                      // UPLOAD PHOTO LABEL
                      // ==================================================

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(.08),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                accentColor.withOpacity(.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Upload Photo',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // RIGHT ICON
              // ==================================================

              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: added
                      ? AppColors.green.withOpacity(.08)
                      : accentColor.withOpacity(.07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  added
                      ? Icons.check_circle_rounded
                      : Icons.camera_alt_rounded,
                  size: 21,
                  color: added
                      ? AppColors.green
                      : accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
