import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../features/profile_setup/services/profile_setup_service.dart';
import '../features/profile_setup/widgets/date_of_birth_field.dart';
import '../features/profile_setup/widgets/locked_info_card.dart';
import '../features/profile_setup/widgets/profile_text_field.dart';
import '../features/profile_setup/widgets/save_profile_button.dart';
import '../features/profile_setup/widgets/selfie_section.dart';
import 'main_navigation_screen.dart';

class MandatoryProfileSetupScreen extends StatefulWidget {
  const MandatoryProfileSetupScreen({super.key});

  @override
  State<MandatoryProfileSetupScreen> createState() =>
      _MandatoryProfileSetupScreenState();
}

class _MandatoryProfileSetupScreenState
    extends State<MandatoryProfileSetupScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _aadhaarController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _pinCodeController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _dateOfBirth;
  File? _selfieFile;

  bool _isSaving = false;

  // =====================================================
  // TAKE SELFIE
  // =====================================================

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _selfieFile = File(image.path);
      });
    } catch (e) {
      debugPrint('Selfie camera error: $e');

      _showMessage(
        'Unable to open camera: $e',
      );
    }
  }

  // =====================================================
  // DATE OF BIRTH
  // =====================================================

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();

    final DateTime initialDate = DateTime(
      now.year - 18,
      now.month,
      now.day,
    );

    final DateTime firstDate = DateTime(
      1900,
      1,
      1,
    );

    final DateTime lastDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _dateOfBirth = selectedDate;
    });
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =====================================================
  // SAVE PROFILE
  // =====================================================

  Future<void> _saveProfile() async {
    final String name =
        _nameController.text.trim();

    final String aadhaar =
        _aadhaarController.text.trim();

    final String address =
        _addressController.text.trim();

    final String pinCode =
        _pinCodeController.text.trim();

    // =====================================================
    // VALIDATION
    // =====================================================

    if (_selfieFile == null) {
      _showMessage(
        'Please take your selfie.',
      );
      return;
    }

    if (name.isEmpty) {
      _showMessage(
        'Please enter your full name.',
      );
      return;
    }

    if (_dateOfBirth == null) {
      _showMessage(
        'Please select your date of birth.',
      );
      return;
    }

    if (aadhaar.length != 12) {
      _showMessage(
        'Please enter a valid 12-digit Aadhaar number.',
      );
      return;
    }

    if (address.isEmpty) {
      _showMessage(
        'Please enter your address.',
      );
      return;
    }

    if (pinCode.length != 6) {
      _showMessage(
        'Please enter a valid 6-digit PIN Code.',
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Login session not found. Please login again.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // =================================================
      // FIREBASE PROFILE SERVICE
      // =================================================

      await ProfileSetupService.saveWalkerProfile(
        walkerUid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        name: name,
        dateOfBirth: _dateOfBirth!,
        aadhaar: aadhaar,
        address: address,
        pinCode: pinCode,
        selfieFile: _selfieFile!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Profile saved successfully!',
      );

      // =================================================
      // GO TO MAIN NAVIGATION
      // =================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'Walker profile save error: $e',
      );

      _showMessage(
        'Profile save failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _nameController.dispose();
    _aadhaarController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    final String walkerUid =
        user?.uid ?? '';

    final String phoneNumber =
        user?.phoneNumber ?? 'Not available';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: const Text(
          'Complete Walker Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // SELFIE
            // =================================================

            SelfieSection(
              selfieFile: _selfieFile,
              onTap: _isSaving
                  ? null
                  : _takeSelfie,
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Take Selfie',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // FULL NAME
            // =================================================

            ProfileTextField(
              label: 'Full Name',
              hint: 'Enter full name',
              controller: _nameController,
              textCapitalization:
                  TextCapitalization.words,
            ),

            const SizedBox(height: 18),

            // =================================================
            // DATE OF BIRTH
            // =================================================

            DateOfBirthField(
              dateOfBirth: _dateOfBirth,
              onTap: _isSaving
                  ? null
                  : _selectDateOfBirth,
            ),

            const SizedBox(height: 18),

            // =================================================
            // AADHAAR
            // =================================================

            ProfileTextField(
              label: 'Aadhaar Number',
              hint: 'Enter 12-digit Aadhaar number',
              controller: _aadhaarController,
              keyboardType:
                  TextInputType.number,
              maxLength: 12,
            ),

            const SizedBox(height: 18),

            // =================================================
            // ADDRESS
            // =================================================

            ProfileTextField(
              label: 'Address',
              hint: 'Enter complete address',
              controller: _addressController,
              maxLines: 3,
              textCapitalization:
                  TextCapitalization.sentences,
            ),

            const SizedBox(height: 18),

            // =================================================
            // PIN CODE
            // =================================================

            ProfileTextField(
              label: 'PIN Code',
              hint: 'Enter 6-digit PIN code',
              controller: _pinCodeController,
              keyboardType:
                  TextInputType.number,
              maxLength: 6,
            ),

            const SizedBox(height: 18),

            // =================================================
            // MOBILE NUMBER
            // =================================================

            LockedInfoCard(
              label: 'Linked Mobile Number',
              value: phoneNumber,
              icon: Icons.phone,
            ),

            const SizedBox(height: 18),

            // =================================================
            // WALKER UID
            // =================================================

            LockedInfoCard(
              label: 'Walker UID',
              value: walkerUid.isEmpty
                  ? 'UID not available'
                  : walkerUid,
              icon: Icons.verified_user,
            ),

            const SizedBox(height: 30),

            // =================================================
            // SAVE BUTTON
            // =================================================

            SaveProfileButton(
              isSaving: _isSaving,
              onPressed: _isSaving
                  ? null
                  : _saveProfile,
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                'Your profile information will be securely linked to your Walker UID.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
