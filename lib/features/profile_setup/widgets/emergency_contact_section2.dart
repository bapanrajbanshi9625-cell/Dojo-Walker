import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

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
          color: DojoWalkerColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: DojoWalkerColors.textMuted,
          ),
          prefixIcon: Icon(
            icon,
            color: DojoWalkerColors.primary,
          ),
          filled: true,
          fillColor: DojoWalkerColors.background,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: DojoWalkerColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: DojoWalkerColors.success,
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
        color: DojoWalkerColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DojoWalkerColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.contact_emergency_rounded,
                color: DojoWalkerColors.primary,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: DojoWalkerColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'OPTIONAL',
                style: TextStyle(
                  color: DojoWalkerColors.textMuted,
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
