import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/profile_image_card.dart';
import '../widgets/profile_progress_header.dart';
import '../widgets/profile_section_title.dart';
import '../widgets/verification_status_card.dart';

class AadhaarVerificationPage extends StatelessWidget {
  const AadhaarVerificationPage({
    super.key,
    required this.currentPage,
    required this.aadhaarVerified,
    required this.nameMatched,
    required this.dobMatched,
    required this.verificationMessage,
    required this.isVerifying,
    required this.isSaving,
    required this.aadhaarFrontFile,
    required this.aadhaarFrontUrl,
    required this.aadhaarBackFile,
    required this.aadhaarBackUrl,
    required this.onImageOptions,
    required this.onBack,
    required this.onSave,
  });

  final int currentPage;

  final bool aadhaarVerified;
  final bool nameMatched;
  final bool dobMatched;

  final String verificationMessage;

  final bool isVerifying;
  final bool isSaving;

  final File? aadhaarFrontFile;
  final String? aadhaarFrontUrl;

  final File? aadhaarBackFile;
  final String? aadhaarBackUrl;

  final Future<void> Function({
    required String type,
    required String title,
  }) onImageOptions;

  final VoidCallback onBack;
  final VoidCallback onSave;

  bool get isBusy => isVerifying || isSaving;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileProgressHeader(
            currentPage: currentPage,
            aadhaarVerified: aadhaarVerified,
          ),

          const ProfileSectionTitle(
            icon: Icons.badge_outlined,
            title: 'Aadhaar Verification',
            subtitle:
                'Add both sides. Verification starts only after Save & Continue.',
          ),

          const SizedBox(height: 16),

          ProfileImageCard(
            title: 'Aadhaar Front',
            subtitle: 'Photo or image URL',
            file: aadhaarFrontFile,
            url: aadhaarFrontUrl,
            type: 'front',
            enabled: !isBusy,
            onAddImage: () {
              onImageOptions(
                type: 'front',
                title: 'Aadhaar Front',
              );
            },
          ),

          const SizedBox(height: 14),

          ProfileImageCard(
            title: 'Aadhaar Back',
            subtitle: 'Photo or image URL',
            file: aadhaarBackFile,
            url: aadhaarBackUrl,
            type: 'back',
            enabled: !isBusy,
            onAddImage: () {
              onImageOptions(
                type: 'back',
                title: 'Aadhaar Back',
              );
            },
          ),

          const SizedBox(height: 18),

          if (isVerifying || aadhaarVerified)
            VerificationStatusCard(
              isVerifying: isVerifying,
              aadhaarVerified: aadhaarVerified,
              nameMatched: nameMatched,
              dobMatched: dobMatched,
              message: verificationMessage,
            ),

          if (isVerifying || aadhaarVerified)
            const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(
                        color: Colors.orange.withOpacity(.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'BACK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      disabledBackgroundColor:
                          const Color(0xFF16A34A).withOpacity(.65),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isBusy
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isVerifying
                                    ? 'VERIFYING...'
                                    : 'SAVING...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'SAVE & CONTINUE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'Step 2 of 2 • Verification is required before completion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF7A8289),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
