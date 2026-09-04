import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class EmergencyContactSection2 extends StatelessWidget {
  const EmergencyContactSection2({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.enabled,
  });

  final TextEditingController nameController;
  final TextEditingController mobileController;
  final bool enabled;

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.muted,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.orange,
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
                Icons.contact_emergency_rounded,
                color: AppColors.orange,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                'OPTIONAL',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _field(
            controller: nameController,
            label: 'Emergency Contact Name (Optional)',
            icon: Icons.person_outline_rounded,
          ),

          _field(
            controller: mobileController,
            label: 'Emergency Contact Mobile (Optional)',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
        ],
      ),
    );
  }
}
