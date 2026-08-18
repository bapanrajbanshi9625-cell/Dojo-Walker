import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.capitalization = TextCapitalization.sentences,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization capitalization;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: capitalization,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF263746),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: icon == null
            ? null
            : Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE0E5E8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE0E5E8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
