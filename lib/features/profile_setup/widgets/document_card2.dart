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
    return url != null && url!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final bool added = hasDocument;

    return InkWell(
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
                ? AppColors.green.withOpacity(.45)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: added
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        url!,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return Icon(
                            Icons.image_not_supported_rounded,
                            color: accentColor,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    added
                        ? 'Document added • Tap to replace'
                        : subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: added
                          ? AppColors.green
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              added
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: added
                  ? AppColors.green
                  : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
