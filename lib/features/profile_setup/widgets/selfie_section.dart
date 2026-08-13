import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SelfieSection extends StatelessWidget {
  final File? selfieFile;
  final VoidCallback? onTap;

  const SelfieSection({
    super.key,
    required this.selfieFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: selfieFile == null
                    ? const Icon(
                        Icons.person,
                        size: 65,
                        color: AppColors.primary,
                      )
                    : Image.file(
                        selfieFile!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
