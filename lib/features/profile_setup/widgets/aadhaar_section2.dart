import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'document_card2.dart';

class AadhaarSection2 extends StatelessWidget {
  const AadhaarSection2({
    super.key,
    required this.aadhaarController,
    required this.aadhaarFrontUrl,
    required this.aadhaarBackUrl,
    required this.onAadhaarFrontTap,
    required this.onAadhaarBackTap,
    required this.enabled,
  });

  final TextEditingController aadhaarController;

  final String? aadhaarFrontUrl;
  final String? aadhaarBackUrl;

  final VoidCallback onAadhaarFrontTap;
  final VoidCallback onAadhaarBackTap;

  final bool enabled;

  Widget _field() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: aadhaarController,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: 12,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: 'Aadhaar Number',
          labelStyle: const TextStyle(
            color: AppColors.muted,
          ),
          prefixIcon: const Icon(
            Icons.credit_card_rounded,
            color: AppColors.blue,
          ),
          filled: true,
          fillColor: AppColors.surface,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.green,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.badge_rounded,
                color: AppColors.blue,
              ),
              SizedBox(width: 9),
              Text(
                'Aadhaar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _field(),

          const SizedBox(height: 2),

          DocumentCard2(
            title: 'Aadhaar Front',
            subtitle: 'Image URL for testing',
            url: aadhaarFrontUrl,
            onTap: enabled ? onAadhaarFrontTap : null,
            accentColor: AppColors.blue,
            icon: Icons.badge_rounded,
          ),

          const SizedBox(height: 12),

          DocumentCard2(
            title: 'Aadhaar Back',
            subtitle: 'Image URL for testing',
            url: aadhaarBackUrl,
            onTap: enabled ? onAadhaarBackTap : null,
            accentColor: AppColors.blue,
            icon: Icons.badge_rounded,
          ),
        ],
      ),
    );
  }
}
