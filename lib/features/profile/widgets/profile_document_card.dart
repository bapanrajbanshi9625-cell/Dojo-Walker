import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileDocumentCard extends StatelessWidget {
  final String label;
  final bool uploaded;
  final VoidCallback onUpload;
  final VoidCallback? onView;
  final VoidCallback? onCopyUrl;

  const ProfileDocumentCard({
    super.key,
    required this.label,
    required this.uploaded,
    required this.onUpload,
    this.onView,
    this.onCopyUrl,
  });

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Color(0xFF7C3AED);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: iconColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      uploaded
                          ? 'Uploaded'
                          : 'Not available',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: uploaded
                            ? const Color(0xFF2E9B5B)
                            : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (uploaded) ...[
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 17,
                    ),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: iconColor,
                      side: const BorderSide(
                        color: iconColor,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(9),
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 9,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCopyUrl,
                    icon: const Icon(
                      Icons.copy_outlined,
                      size: 17,
                    ),
                    label: const Text('Copy URL'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF2563EB),
                      side: const BorderSide(
                        color: Color(0xFF2563EB),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(9),
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpload,
                icon: const Icon(
                  Icons.upload_outlined,
                  size: 17,
                ),
                label: const Text('Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: iconColor,
                  side: const BorderSide(
                    color: iconColor,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(9),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 9,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
