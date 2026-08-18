import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/profile_field.dart';
import '../widgets/profile_image_card.dart';
import '../widgets/profile_progress_header.dart';
import '../widgets/profile_section_title.dart';

class ProfileDetailsPage extends StatelessWidget {
  const ProfileDetailsPage({
    super.key,
    required this.nameController,
    required this.aadhaarController,
    required this.villageController,
    required this.cityController,
    required this.districtController,
    required this.stateController,
    required this.pinCodeController,
    required this.dateOfBirth,
    required this.selfieFile,
    required this.selfieUrl,
    required this.isBusy,
    required this.currentPage,
    required this.onSelectDate,
    required this.onImageOptions,
    required this.onNext,
  });

  final TextEditingController nameController;
  final TextEditingController aadhaarController;
  final TextEditingController villageController;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController stateController;
  final TextEditingController pinCodeController;

  final DateTime? dateOfBirth;

  final File? selfieFile;
  final String? selfieUrl;

  final bool isBusy;
  final int currentPage;

  final VoidCallback onSelectDate;

  final Future<void> Function({
    required String type,
    required String title,
  }) onImageOptions;

  final VoidCallback onNext;

  static const Color text = Color(0xFF263746);
  static const Color muted = Color(0xFF7A8289);

  @override
  Widget build(BuildContext context) {
    final String dobText = dateOfBirth == null
        ? 'Select date of birth'
        : '${dateOfBirth!.day.toString().padLeft(2, '0')}/'
            '${dateOfBirth!.month.toString().padLeft(2, '0')}/'
            '${dateOfBirth!.year}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileProgressHeader(
            currentPage: currentPage,
            aadhaarVerified: false,
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFF3EC),
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(.14),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primary,
                  size: 27,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Complete your profile details. Aadhaar verification will be performed on the next step.',
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const ProfileSectionTitle(
            icon: Icons.camera_front_rounded,
            title: 'Profile Selfie',
            subtitle: 'Add a clear front-facing selfie.',
          ),

          const SizedBox(height: 14),

          ProfileImageCard(
            title: 'Profile Selfie',
            subtitle: 'Photo or image URL',
            file: selfieFile,
            url: selfieUrl,
            type: 'selfie',
            enabled: !isBusy,
            onAddImage: () {
              onImageOptions(
                type: 'selfie',
                title: 'Profile Selfie',
              );
            },
          ),

          const SizedBox(height: 27),

          const ProfileSectionTitle(
            icon: Icons.person_outline_rounded,
            title: 'Personal Details',
            subtitle: 'Enter your basic information.',
          ),

          const SizedBox(height: 14),

          ProfileField(
            label: 'Full Name',
            hint: 'Enter full name',
            controller: nameController,
            icon: Icons.person_outline_rounded,
            enabled: !isBusy,
            capitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: isBusy ? null : onSelectDate,
            borderRadius: BorderRadius.circular(15),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                prefixIcon: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFFE0E5E8),
                  ),
                ),
              ),
              child: Text(
                dobText,
                style: TextStyle(
                  color: dateOfBirth == null ? muted : text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          ProfileField(
            label: 'Aadhaar Number',
            hint: 'Enter 12-digit Aadhaar number',
            controller: aadhaarController,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            maxLength: 12,
            enabled: !isBusy,
            capitalization: TextCapitalization.none,
          ),

          const SizedBox(height: 27),

          const ProfileSectionTitle(
            icon: Icons.location_on_outlined,
            title: 'Address Details',
            subtitle: 'Enter your residential location.',
          ),

          const SizedBox(height: 14),

          ProfileField(
            label: 'Village / Locality',
            hint: 'Enter village or locality',
            controller: villageController,
            icon: Icons.home_work_outlined,
            enabled: !isBusy,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ProfileField(
                  label: 'City / Town',
                  hint: 'City / Town',
                  controller: cityController,
                  icon: Icons.location_city_outlined,
                  enabled: !isBusy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfileField(
                  label: 'District',
                  hint: 'District',
                  controller: districtController,
                  icon: Icons.map_outlined,
                  enabled: !isBusy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ProfileField(
                  label: 'State',
                  hint: 'State',
                  controller: stateController,
                  icon: Icons.public_outlined,
                  enabled: !isBusy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfileField(
                  label: 'PIN Code',
                  hint: '6 digits',
                  controller: pinCodeController,
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !isBusy,
                  capitalization: TextCapitalization.none,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isBusy ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                disabledBackgroundColor:
                    const Color(0xFF16A34A).withOpacity(.65),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'NEXT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 10,
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
