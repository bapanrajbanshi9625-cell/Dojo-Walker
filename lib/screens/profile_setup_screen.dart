import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../features/profile_setup/services/profile_setup_service.dart';
import 'main_navigation_screen.dart';

class MandatoryProfileSetupScreen extends StatefulWidget {
  const MandatoryProfileSetupScreen({super.key});

  @override
  State<MandatoryProfileSetupScreen> createState() =>
      _MandatoryProfileSetupScreenState();
}

class _MandatoryProfileSetupScreenState
    extends State<MandatoryProfileSetupScreen> {
  final PageController _pageController = PageController();

  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // PAGE 1 CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _aadhaarController =
      TextEditingController();

  final TextEditingController _villageController =
      TextEditingController();

  final TextEditingController _cityController =
      TextEditingController();

  final TextEditingController _districtController =
      TextEditingController();

  final TextEditingController _stateController =
      TextEditingController();

  final TextEditingController _pinCodeController =
      TextEditingController();

  // ============================================================
  // DATE
  // ============================================================

  DateTime? _dateOfBirth;

  // ============================================================
  // IMAGES
  // ============================================================

  File? _selfieFile;
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;

  String? _selfieUrl;
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;

  // ============================================================
  // STATE
  // ============================================================

  int _currentPage = 0;

  bool _isSaving = false;
  bool _isVerifying = false;

  // ============================================================
  // VERIFIED DATA
  // ============================================================

  bool _aadhaarVerified = false;
  bool _nameMatched = false;
  bool _dobMatched = false;

  String _verificationMessage = '';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _green =
      Color(0xFF16A34A);

  static const Color _greenDark =
      Color(0xFF15803D);

  static const Color _background =
      Color(0xFFF5F7F8);

  static const Color _text =
      Color(0xFF263746);

  static const Color _muted =
      Color(0xFF7A8289);

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _chooseImage({
    required String title,
    required ImageSource source,
    required String type,
  }) async {
    if (_isSaving || _isVerifying) {
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) {
        return;
      }

      final File file = File(image.path);

      setState(() {
        if (type == 'selfie') {
          _selfieFile = file;
          _selfieUrl = null;
        } else if (type == 'front') {
          _aadhaarFrontFile = file;
          _aadhaarFrontUrl = null;
        } else {
          _aadhaarBackFile = file;
          _aadhaarBackUrl = null;
        }

        _resetVerification();
      });
    } catch (e) {
      _showError(
        'Unable to open $title. Please check permission.',
      );
    }
  }

  // ============================================================
  // URL DIALOG
  // ============================================================

  Future<void> _enterImageUrl({
    required String type,
    required String title,
  }) async {
    if (_isSaving || _isVerifying) {
      return;
    }

    final TextEditingController controller =
        TextEditingController();

    final String? url = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Paste image URL',
              prefixIcon: const Icon(
                Icons.link_rounded,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7F8),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final String value =
                    controller.text.trim();

                if (value.isEmpty ||
                    !value.startsWith('http')) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid image URL.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (url == null || !mounted) {
      return;
    }

    setState(() {
      if (type == 'selfie') {
        _selfieUrl = url;
        _selfieFile = null;
      } else if (type == 'front') {
        _aadhaarFrontUrl = url;
        _aadhaarFrontFile = null;
      } else {
        _aadhaarBackUrl = url;
        _aadhaarBackFile = null;
      }

      _resetVerification();
    });
  }

  // ============================================================
  // SOURCE POPUP
  // ============================================================

  Future<void> _showImageOptions({
    required String type,
    required String title,
    bool cameraOnly = false,
  }) async {
    if (_isSaving || _isVerifying) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
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

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Choose how you want to add the image.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _optionCard(
                        icon:
                            Icons.camera_alt_rounded,
                        title: 'Photo',
                        subtitle: 'Take photo',
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                          );

                          _chooseImage(
                            title: title,
                            source:
                                ImageSource.camera,
                            type: type,
                          );
                        },
                      ),
                    ),

                    if (!cameraOnly) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _optionCard(
                          icon:
                              Icons.link_rounded,
                          title: 'URL',
                          subtitle: 'Paste image URL',
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                            );

                            _enterImageUrl(
                              type: type,
                              title: '$title URL',
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // OPTION CARD
  // ============================================================

  Widget _optionCard({
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
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE0E5E8),
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
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE CARD
  // ============================================================

  Widget _imageCard({
    required String title,
    required String subtitle,
    required File? file,
    required String? url,
    required String type,
  }) {
    final bool hasImage =
        file != null ||
        (url != null && url.isNotEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: hasImage
              ? _green.withOpacity(.35)
              : const Color(0xFFE0E5E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
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
                  color: hasImage
                      ? const Color(0xFFEAF7EF)
                      : const Color(0xFFFFF3EC),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  hasImage
                      ? Icons.check_circle_rounded
                      : Icons.image_outlined,
                  color: hasImage
                      ? _green
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasImage
                          ? 'Image ready'
                          : subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasImage
                            ? _green
                            : _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasImage) ...[
            const SizedBox(height: 13),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 165,
                child: file != null
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        url!,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (
                              context,
                              child,
                              progress,
                            ) {
                          if (progress == null) {
                            return child;
                          }

                          return const Center(
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          );
                        },
                        errorBuilder:
                            (
                              context,
                              error,
                              stackTrace,
                            ) {
                          return Container(
                            color: const Color(
                              0xFFF5F7F8,
                            ),
                            alignment:
                                Alignment.center,
                            child: const Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .broken_image_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Unable to load image URL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              onPressed:
                  _isSaving || _isVerifying
                      ? null
                      : () {
                          _showImageOptions(
                            type: type,
                            title: title,
                          );
                        },
              icon: Icon(
                hasImage
                    ? Icons.refresh_rounded
                    : Icons.add_photo_alternate_outlined,
                size: 19,
              ),
              label: Text(
                hasImage
                    ? 'Change Image'
                    : 'Add Image',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
                      BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization capitalization =
        TextCapitalization.sentences,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: capitalization,
      enabled: !_isSaving && !_isVerifying,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _text,
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
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE0E5E8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE0E5E8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    if (_isSaving || _isVerifying) {
      return;
    }

    final DateTime now = DateTime.now();

    final DateTime? result =
        await showDatePicker(
      context: context,
      initialDate: DateTime(
        now.year - 18,
        now.month,
        now.day,
      ),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _dateOfBirth = result;
      _resetVerification();
    });
  }

  // ============================================================
  // PAGE 1 VALIDATION
  // ============================================================

  bool _validatePageOne() {
    if (_selfieFile == null &&
        (_selfieUrl == null ||
            _selfieUrl!.trim().isEmpty)) {
      _showError(
        'Please add your profile selfie.',
      );
      return false;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError(
        'Please enter your full name.',
      );
      return false;
    }

    if (_dateOfBirth == null) {
      _showError(
        'Please select your date of birth.',
      );
      return false;
    }

    final String aadhaar =
        _aadhaarController.text.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      _showError(
        'Please enter a valid 12-digit Aadhaar number.',
      );
      return false;
    }

    if (_villageController.text.trim().isEmpty) {
      _showError(
        'Please enter your village or locality.',
      );
      return false;
    }

    if (_cityController.text.trim().isEmpty) {
      _showError(
        'Please enter your city or town.',
      );
      return false;
    }

    if (_districtController.text.trim().isEmpty) {
      _showError(
        'Please enter your district.',
      );
      return false;
    }

    if (_stateController.text.trim().isEmpty) {
      _showError(
        'Please enter your state.',
      );
      return false;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(
      _pinCodeController.text.trim(),
    )) {
      _showError(
        'Please enter a valid 6-digit PIN code.',
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // NEXT
  // ============================================================

  void _nextPage() {
    if (!_validatePageOne()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _currentPage = 1;
    });

    _pageController.animateToPage(
      1,
      duration:
          const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // ============================================================
  // BACK
  // ============================================================

  void _previousPage() {
    if (_isSaving || _isVerifying) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _currentPage = 0;
    });

    _pageController.animateToPage(
      0,
      duration:
          const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // ============================================================
  // FINAL SAVE & VERIFY
  // ============================================================

  Future<void> _saveAndContinue() async {
    if (_isSaving || _isVerifying) {
      return;
    }

    final bool frontAvailable =
        _aadhaarFrontFile != null ||
        (_aadhaarFrontUrl != null &&
            _aadhaarFrontUrl!.trim().isNotEmpty);

    final bool backAvailable =
        _aadhaarBackFile != null ||
        (_aadhaarBackUrl != null &&
            _aadhaarBackUrl!.trim().isNotEmpty);

    if (!frontAvailable) {
      _showError(
        'Please add Aadhaar Front.',
      );
      return;
    }

    if (!backAvailable) {
      _showError(
        'Please add Aadhaar Back.',
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError(
        'Login session not found. Please login again.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
      _verificationMessage =
          'Verifying Aadhaar and matching Name & Date of Birth...';
      _aadhaarVerified = false;
      _nameMatched = false;
      _dobMatched = false;
    });

    try {
      // ========================================================
      // IMPORTANT
      //
      // This method MUST be connected to your actual
      // verification/admin backend.
      //
      // It must NOT simply return true.
      // ========================================================

      final AadhaarVerificationResult result =
          await AadhaarVerificationService.verify(
        name: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        aadhaarNumber:
            _aadhaarController.text.trim(),
        frontUrl:
            _aadhaarFrontUrl?.trim(),
        backUrl:
            _aadhaarBackUrl?.trim(),
      );

      if (!mounted) {
        return;
      }

      if (!result.verified) {
        _showVerificationPopup(
          title: 'Verification Failed',
          message:
              result.message ??
                  'Aadhaar verification failed.',
        );
        return;
      }

      if (!result.nameMatched) {
        _showVerificationPopup(
          title: 'Name Not Matched',
          message:
              'The name entered in your profile does not match the verified Aadhaar name.',
        );
        return;
      }

      if (!result.dobMatched) {
        _showVerificationPopup(
          title: 'Date of Birth Not Matched',
          message:
              'The Date of Birth entered in your profile does not match the verified Aadhaar Date of Birth.',
        );
        return;
      }

      setState(() {
        _aadhaarVerified = true;
        _nameMatched = true;
        _dobMatched = true;
        _verificationMessage =
            'Verification complete. Saving profile...';
        _isSaving = true;
      });

      // ========================================================
      // FINAL FIRESTORE SAVE
      // ========================================================

      await ProfileSetupService.saveWalkerProfile(
        authUid: user.uid,
        phoneNumber:
            user.phoneNumber ?? '',
        name:
            _nameController.text.trim(),
        dateOfBirth:
            _dateOfBirth!,
        aadhaar:
            _aadhaarController.text.trim(),
        village:
            _villageController.text.trim(),
        city:
            _cityController.text.trim(),
        district:
            _districtController.text.trim(),
        state:
            _stateController.text.trim(),
        pinCode:
            _pinCodeController.text.trim(),
        selfieUrl:
            _selfieUrl ?? '',
        aadhaarFrontUrl:
            _aadhaarFrontUrl ?? '',
        aadhaarBackUrl:
            _aadhaarBackUrl ?? '',
        aadhaarVerified:
            true,
        nameMatched:
            true,
        dobMatched:
            true,
        aadhaarVerifiedName:
            result.verifiedName ?? '',
      );

      if (!mounted) {
        return;
      }

      _showSuccess(
        'Verification successful. Profile saved.',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'Mandatory profile verification/save error: $e',
      );

      if (!mounted) {
        return;
      }

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // RESET VERIFICATION
  // ============================================================

  void _resetVerification() {
    _aadhaarVerified = false;
    _nameMatched = false;
    _dobMatched = false;
    _verificationMessage = '';
  }

  // ============================================================
  // VERIFICATION POPUP
  // ============================================================

  Future<void> _showVerificationPopup({
    required String title,
    required String message,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFEBEB),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _muted,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showError(String message) {
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
          backgroundColor:
              const Color(0xFFDC2626),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _showSuccess(String message) {
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
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: _green,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _progressHeader() {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 18),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              const Color(0xFFE3E7EA),
        ),
      ),
      child: Row(
        children: [
          _progressCircle(
            number: '1',
            active: _currentPage == 0,
            completed: _currentPage > 0,
          ),
          Expanded(
            child: Container(
              height: 3,
              color: _currentPage > 0
                  ? _green
                  : const Color(0xFFE3E7EA),
            ),
          ),
          _progressCircle(
            number: '2',
            active: _currentPage == 1,
            completed: false,
          ),
        ],
      ),
    );
  }

  Widget _progressCircle({
    required String number,
    required bool active,
    required bool completed,
  }) {
    final bool selected =
        active || completed;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: selected
            ? (completed
                ? _green
                : AppColors.primary)
            : const Color(0xFFF0F2F4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: completed
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 19,
            )
          : Text(
              number,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : _muted,
                fontWeight:
                    FontWeight.w900,
              ),
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
                style: const TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
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
  // GREEN PRIMARY BUTTON
  // ============================================================

  Widget _greenButton({
    required String text,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor:
              _green.withOpacity(.65),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor:
              _green.withOpacity(.25),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 19,
                    height: 19,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // PAGE 1
  // ============================================================

  Widget _pageOne() {
    final String dobText =
        _dateOfBirth == null
            ? 'Select date of birth'
            : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
              '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
              '${_dateOfBirth!.year}';

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _progressHeader(),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFFFFF3EC),
                  Colors.white,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary
                    .withOpacity(.14),
              ),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons
                      .verified_user_rounded,
                  color:
                      AppColors.primary,
                  size: 27,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Complete your basic profile details to continue to Aadhaar verification.',
                    style: TextStyle(
                      color: _text,
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

          const SizedBox(height: 25),

          _sectionTitle(
            icon:
                Icons.camera_front_rounded,
            title: 'Profile Selfie',
            subtitle:
                'Add a clear front-facing selfie.',
          ),

          const SizedBox(height: 14),

          _imageCard(
            title: 'Profile Selfie',
            subtitle:
                'Photo or image URL',
            file: _selfieFile,
            url: _selfieUrl,
            type: 'selfie',
          ),

          const SizedBox(height: 27),

          _sectionTitle(
            icon:
                Icons.person_outline_rounded,
            title: 'Personal Details',
            subtitle:
                'Enter your basic information.',
          ),

          const SizedBox(height: 14),

          _field(
            label: 'Full Name',
            hint: 'Enter full name',
            controller:
                _nameController,
            icon:
                Icons.person_outline_rounded,
            capitalization:
                TextCapitalization.words,
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: _selectDate,
            borderRadius:
                BorderRadius.circular(15),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText:
                    'Date of Birth',
                prefixIcon:
                    const Icon(
                  Icons
                      .calendar_month_rounded,
                  color:
                      AppColors.primary,
                ),
                filled: true,
                fillColor:
                    Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        Color(0xFFE0E5E8),
                  ),
                ),
              ),
              child: Text(
                dobText,
                style: TextStyle(
                  color:
                      _dateOfBirth == null
                          ? _muted
                          : _text,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          _field(
            label: 'Aadhaar Number',
            hint:
                'Enter 12-digit Aadhaar number',
            controller:
                _aadhaarController,
            icon:
                Icons.badge_outlined,
            keyboardType:
                TextInputType.number,
            maxLength: 12,
            capitalization:
                TextCapitalization.none,
          ),

          const SizedBox(height: 27),

          _sectionTitle(
            icon:
                Icons.location_on_outlined,
            title: 'Address Details',
            subtitle:
                'Enter your residential location.',
          ),

          const SizedBox(height: 14),

          _field(
            label: 'Village / Locality',
            hint:
                'Enter village or locality',
            controller:
                _villageController,
            icon:
                Icons.home_work_outlined,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'City / Town',
                  hint: 'City / Town',
                  controller:
                      _cityController,
                  icon:
                      Icons.location_city_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  label: 'District',
                  hint: 'District',
                  controller:
                      _districtController,
                  icon:
                      Icons.map_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'State',
                  hint: 'State',
                  controller:
                      _stateController,
                  icon:
                      Icons.public_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  label: 'PIN Code',
                  hint: '6 digits',
                  controller:
                      _pinCodeController,
                  icon:
                      Icons.pin_drop_outlined,
                  keyboardType:
                      TextInputType.number,
                  maxLength: 6,
                  capitalization:
                      TextCapitalization.none,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _greenButton(
            text: 'NEXT',
            onPressed:
                _isSaving ||
                        _isVerifying
                    ? null
                    : _nextPage,
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 10,
                color: _muted,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE 2
  // ============================================================

  Widget _pageTwo() {
    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _progressHeader(),

          _sectionTitle(
            icon:
                Icons.badge_outlined,
            title: 'Aadhaar Verification',
            subtitle:
                'Add both sides. Verification starts only when you tap Save & Continue.',
          ),

          const SizedBox(height: 16),

          _imageCard(
            title: 'Aadhaar Front',
            subtitle:
                'Photo or image URL',
            file: _aadhaarFrontFile,
            url: _aadhaarFrontUrl,
            type: 'front',
          ),

          const SizedBox(height: 14),

          _imageCard(
            title: 'Aadhaar Back',
            subtitle:
                'Photo or image URL',
            file: _aadhaarBackFile,
            url: _aadhaarBackUrl,
            type: 'back',
          ),

          const SizedBox(height: 18),

          if (_isVerifying ||
              _aadhaarVerified) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _aadhaarVerified
                    ? const Color(
                        0xFFEAF7EF,
                      )
                    : const Color(
                        0xFFFFF7ED,
                      ),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: _aadhaarVerified
                      ? _green
                          .withOpacity(.25)
                      : AppColors.primary
                          .withOpacity(.20),
                ),
              ),
              child: Row(
                children: [
                  if (_isVerifying)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color:
                            AppColors.primary,
                      ),
                    )
                  else
                    const Icon(
                      Icons
                          .check_circle_rounded,
                      color: _green,
                      size: 22,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _verificationMessage,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight:
                            FontWeight.w700,
                        color: _text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed:
                        _isSaving ||
                                _isVerifying
                            ? null
                            : _previousPage,
                    style: OutlinedButton.styleFrom(
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
                          16,
                        ),
                      ),
                    ),
                    child: const Text(
                      'BACK',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _greenButton(
                  text: _isVerifying
                      ? 'VERIFYING...'
                      : _isSaving
                          ? 'SAVING...'
                          : 'SAVE & CONTINUE',
                  onPressed:
                      _isSaving ||
                              _isVerifying
                          ? null
                          : _saveAndContinue,
                  loading:
                      _isVerifying ||
                          _isSaving,
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
                color: _muted,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor:
            AppColors.primary,
        elevation: 0,
        toolbarHeight: 68,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Complete Walker Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Verification required to continue',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(),
          children: [
            _pageOne(),
            _pageTwo(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pageController.dispose();

    _nameController.dispose();
    _aadhaarController.dispose();

    _villageController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();

    super.dispose();
  }
}

// =================================================================
// VERIFICATION RESULT
// =================================================================

class AadhaarVerificationResult {
  final bool verified;
  final bool nameMatched;
  final bool dobMatched;
  final String? verifiedName;
  final String? message;

  const AadhaarVerificationResult({
    required this.verified,
    required this.nameMatched,
    required this.dobMatched,
    this.verifiedName,
    this.message,
  });
}

// =================================================================
// VERIFICATION SERVICE
// =================================================================

class AadhaarVerificationService {
  AadhaarVerificationService._();

  static Future<AadhaarVerificationResult> verify({
    required String name,
    required DateTime dateOfBirth,
    required String aadhaarNumber,
    String? frontUrl,
    String? backUrl,
  }) async {
    /*
     * IMPORTANT
     *
     * DO NOT return verified=true here.
     *
     * Connect this method to your actual verification/admin
     * backend before enabling real profile completion.
     *
     * The UI is already ready for:
     *
     *   Front/Back
     *   Name verification
     *   DOB verification
     *   Loading
     *   Failure popup
     *   Final Firestore save
     *
     * Until a real verification result is supplied, profile
     * completion must remain blocked.
     */

    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    return const AadhaarVerificationResult(
      verified: false,
      nameMatched: false,
      dobMatched: false,
      message:
          'Aadhaar verification service is not connected yet. Please complete verification from the admin/backend system.',
    );
  }
}
