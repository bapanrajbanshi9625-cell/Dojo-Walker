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
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _aadhaarController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _pinCodeController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // STATE
  // ============================================================

  DateTime? _dateOfBirth;

  File? _selfieFile;
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;

  bool _isSaving = false;

  // ============================================================
  // TAKE SELFIE
  // ============================================================

  Future<void> _takeSelfie() async {
    if (_isSaving) {
      return;
    }

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
        'Unable to open camera. Please check camera permission.',
      );
    }
  }

  // ============================================================
  // AADHAAR IMAGE PICKER
  // ============================================================

  Future<void> _pickAadhaarImage({
    required bool front,
  }) async {
    if (_isSaving) {
      return;
    }

    final ImageSource? source =
        await _showImageSourceDialog(
      title: front
          ? 'Aadhaar Front'
          : 'Aadhaar Back',
    );

    if (source == null || !mounted) {
      return;
    }

    try {
      final XFile? image =
          await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1200,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        if (front) {
          _aadhaarFrontFile = File(image.path);
        } else {
          _aadhaarBackFile = File(image.path);
        }
      });
    } catch (e) {
      debugPrint(
        'Aadhaar image picker error: $e',
      );

      _showMessage(
        'Unable to select Aadhaar image.',
      );
    }
  }

  // ============================================================
  // IMAGE SOURCE BOTTOM SHEET
  // ============================================================

  Future<ImageSource?> _showImageSourceDialog({
    required String title,
  }) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DCE0),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withOpacity(.10),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w900,
                              color:
                                  Color(0xFF263746),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Choose how you want to upload the document.',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Color(0xFF7A8289),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _sourceButton(
                        icon:
                            Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle:
                            'Take photo',
                        onTap: () {
                          Navigator.pop(
                            context,
                            ImageSource.camera,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _sourceButton(
                        icon:
                            Icons.photo_library_rounded,
                        title: 'Gallery',
                        subtitle:
                            'Choose photo',
                        onTap: () {
                          Navigator.pop(
                            context,
                            ImageSource.gallery,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE1E5E8),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 25,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF263746),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF7A8289),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REMOVE AADHAAR IMAGE
  // ============================================================

  void _removeAadhaarImage({
    required bool front,
  }) {
    if (_isSaving) {
      return;
    }

    setState(() {
      if (front) {
        _aadhaarFrontFile = null;
      } else {
        _aadhaarBackFile = null;
      }
    });
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  Future<void> _selectDateOfBirth() async {
    if (_isSaving) {
      return;
    }

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

    final DateTime? selectedDate =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _dateOfBirth = selectedDate;
    });
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration:
              const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    final String name =
        _nameController.text.trim();

    final String aadhaar =
        _aadhaarController.text.trim();

    final String address =
        _addressController.text.trim();

    final String pinCode =
        _pinCodeController.text.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (_selfieFile == null) {
      _showMessage(
        'Please take your profile selfie.',
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

    if (_aadhaarFrontFile == null) {
      _showMessage(
        'Please upload Aadhaar front side.',
      );
      return;
    }

    if (_aadhaarBackFile == null) {
      _showMessage(
        'Please upload Aadhaar back side.',
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

    // ==========================================================
    // FIREBASE AUTH USER
    // ==========================================================

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Login session not found. Please login again.',
      );
      return;
    }

    // ==========================================================
    // SAVE START
    // ==========================================================

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint(
        '========================================',
      );
      debugPrint(
        'WALKER PROFILE SAVE',
      );
      debugPrint(
        'Firebase Auth UID: ${user.uid}',
      );
      debugPrint(
        'Phone: ${user.phoneNumber}',
      );
      debugPrint(
        '========================================',
      );

      // ========================================================
      // IMPORTANT
      //
      // ProfileSetupService now requires:
      //
      //     authUid
      //
      // NOT walkerUid.
      //
      // Firebase Auth UID is used internally.
      // It is not displayed in the UI.
      // ========================================================

      await ProfileSetupService.saveWalkerProfile(
        authUid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        name: name,
        dateOfBirth: _dateOfBirth!,
        aadhaar: aadhaar,
        address: address,
        pinCode: pinCode,
        selfieFile: _selfieFile!,
        aadhaarFrontFile: _aadhaarFrontFile!,
        aadhaarBackFile: _aadhaarBackFile!,
      );

      debugPrint(
        'Walker profile saved successfully.',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Walker profile saved successfully!',
      );

      // ========================================================
      // OPEN MAIN APP
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '========================================',
      );
      debugPrint(
        'WALKER PROFILE SAVE ERROR',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        '$stackTrace',
      );
      debugPrint(
        '========================================',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Profile save failed. Please check your internet connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // AADHAAR UPLOAD CARD
  // ============================================================

  Widget _aadhaarUploadCard({
    required String title,
    required String subtitle,
    required File? file,
    required bool front,
  }) {
    final bool uploaded = file != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: uploaded
              ? const Color(0xFFB9DEC6)
              : const Color(0xFFE1E6EA),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: uploaded
                      ? const Color(0xFFEAF7EF)
                      : const Color(0xFFFFF3ED),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  uploaded
                      ? Icons
                          .check_circle_rounded
                      : Icons.badge_outlined,
                  color: uploaded
                      ? const Color(0xFF16A34A)
                      : AppColors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF263746),
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      uploaded
                          ? 'Document selected successfully'
                          : subtitle,
                      style: TextStyle(
                        color: uploaded
                            ? const Color(
                                0xFF16A34A,
                              )
                            : const Color(
                                0xFF7A8289,
                              ),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (uploaded) ...[
            const SizedBox(height: 13),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.file(
                    file,
                    width:
                        double.infinity,
                    height: 155,
                    fit: BoxFit.cover,
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black
                          .withOpacity(.58),
                      shape:
                          const CircleBorder(),
                      child: InkWell(
                        customBorder:
                            const CircleBorder(),
                        onTap: _isSaving
                            ? null
                            : () =>
                                _removeAadhaarImage(
                                  front: front,
                                ),
                        child:
                            const Padding(
                          padding:
                              EdgeInsets.all(8),
                          child: Icon(
                            Icons
                                .close_rounded,
                            color:
                                Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 9,
                    bottom: 9,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.black
                            .withOpacity(.55),
                        borderRadius:
                            BorderRadius
                                .circular(20),
                      ),
                      child: const Text(
                        'Selected',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () =>
                      _pickAadhaarImage(
                        front: front,
                      ),
              icon: Icon(
                uploaded
                    ? Icons
                        .refresh_rounded
                    : Icons
                        .upload_file_rounded,
                size: 19,
              ),
              label: Text(
                uploaded
                    ? 'Change Document'
                    : 'Upload Document',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary
                      .withOpacity(.45),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary
                .withOpacity(.10),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF263746),
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF7A8289),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _aadhaarController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    final String phoneNumber =
        user?.phoneNumber ??
            'Not available';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F8),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        automaticallyImplyLeading:
            false,
        elevation: 0,
        titleSpacing: 20,
        toolbarHeight: 68,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Complete Walker Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Verify your profile to continue',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            35,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // INTRO CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFFFFF3EC),
                      Colors.white,
                    ],
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: AppColors
                        .primary
                        .withOpacity(.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(.025),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Icon(
                      Icons
                          .verified_user_rounded,
                      color:
                          AppColors.primary,
                      size: 27,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete your verification details. '
                        'All required information must be submitted before continuing.',
                        style: TextStyle(
                          color:
                              Color(0xFF46515A),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SELFIE
              // ==================================================

              _sectionTitle(
                icon:
                    Icons
                        .camera_front_rounded,
                title:
                    'Profile Selfie',
                subtitle:
                    'Take a clear front-facing selfie.',
              ),

              const SizedBox(height: 14),

              SelfieSection(
                selfieFile:
                    _selfieFile,
                onTap: _isSaving
                    ? null
                    : _takeSelfie,
              ),

              const SizedBox(height: 7),

              const Center(
                child: Text(
                  'Take Selfie',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // PERSONAL DETAILS
              // ==================================================

              _sectionTitle(
                icon:
                    Icons
                        .person_outline_rounded,
                title:
                    'Personal Details',
                subtitle:
                    'Enter your basic profile information.',
              ),

              const SizedBox(height: 14),

              ProfileTextField(
                label:
                    'Full Name',
                hint:
                    'Enter full name',
                controller:
                    _nameController,
                textCapitalization:
                    TextCapitalization
                        .words,
              ),

              const SizedBox(height: 16),

              DateOfBirthField(
                dateOfBirth:
                    _dateOfBirth,
                onTap: _isSaving
                    ? null
                    : _selectDateOfBirth,
              ),

              const SizedBox(height: 28),

              // ==================================================
              // AADHAAR
              // ==================================================

              _sectionTitle(
                icon:
                    Icons.badge_outlined,
                title:
                    'Aadhaar Verification',
                subtitle:
                    'Enter your Aadhaar number and upload both sides.',
              ),

              const SizedBox(height: 14),

              ProfileTextField(
                label:
                    'Aadhaar Number',
                hint:
                    'Enter 12-digit Aadhaar number',
                controller:
                    _aadhaarController,
                keyboardType:
                    TextInputType.number,
                maxLength: 12,
              ),

              const SizedBox(height: 13),

              _aadhaarUploadCard(
                title:
                    'Aadhaar Front',
                subtitle:
                    'Upload the front side of Aadhaar',
                file:
                    _aadhaarFrontFile,
                front: true,
              ),

              const SizedBox(height: 13),

              _aadhaarUploadCard(
                title:
                    'Aadhaar Back',
                subtitle:
                    'Upload the back side of Aadhaar',
                file:
                    _aadhaarBackFile,
                front: false,
              ),

              const SizedBox(height: 28),

              // ==================================================
              // ADDRESS
              // ==================================================

              _sectionTitle(
                icon:
                    Icons
                        .location_on_outlined,
                title:
                    'Address Details',
                subtitle:
                    'Provide your current residential address.',
              ),

              const SizedBox(height: 14),

              ProfileTextField(
                label:
                    'Address',
                hint:
                    'Enter complete address',
                controller:
                    _addressController,
                maxLines: 3,
                textCapitalization:
                    TextCapitalization
                        .sentences,
              ),

              const SizedBox(height: 16),

              ProfileTextField(
                label:
                    'PIN Code',
                hint:
                    'Enter 6-digit PIN code',
                controller:
                    _pinCodeController,
                keyboardType:
                    TextInputType.number,
                maxLength: 6,
              ),

              const SizedBox(height: 28),

              // ==================================================
              // ACCOUNT INFORMATION
              // ==================================================

              _sectionTitle(
                icon:
                    Icons.phone_outlined,
                title:
                    'Account Information',
                subtitle:
                    'Your login mobile number is linked automatically.',
              ),

              const SizedBox(height: 14),

              LockedInfoCard(
                label:
                    'Linked Mobile Number',
                value:
                    phoneNumber,
                icon:
                    Icons.phone_rounded,
              ),

              const SizedBox(height: 28),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SaveProfileButton(
                isSaving:
                    _isSaving,
                onPressed:
                    _isSaving
                        ? null
                        : _saveProfile,
              ),

              const SizedBox(height: 14),

              const Center(
                child: Text(
                  'Your verification information is securely linked to your Walker profile.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color:
                        Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
