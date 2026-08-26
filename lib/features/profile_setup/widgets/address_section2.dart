import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AddressSection2 extends StatelessWidget {
  const AddressSection2({
    super.key,
    required this.villageController,
    required this.cityController,
    required this.districtController,
    required this.stateController,
    required this.pinController,
    required this.fullAddress,
    required this.enabled,
  });

  final TextEditingController villageController;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController stateController;
  final TextEditingController pinController;

  final String fullAddress;
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
                Icons.location_on_rounded,
                color: AppColors.blue,
              ),
              SizedBox(width: 9),
              Text(
                'Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _field(
            controller: villageController,
            label: 'Village / Locality',
            icon: Icons.location_on_rounded,
          ),

          _field(
            controller: cityController,
            label: 'City / Town',
            icon: Icons.location_city_rounded,
          ),

          _field(
            controller: districtController,
            label: 'District',
            icon: Icons.map_rounded,
          ),

          _field(
            controller: stateController,
            label: 'State',
            icon: Icons.public_rounded,
          ),

          _field(
            controller: pinController,
            label: 'PIN Code',
            icon: Icons.pin_drop_rounded,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.home_rounded,
                  color: AppColors.green,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    fullAddress.isEmpty
                        ? 'Address preview'
                        : fullAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
