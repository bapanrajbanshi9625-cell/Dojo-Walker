import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../features/profile_setup/screens/mandatory_profile_setup_screen1.dart';
import '../features/profile_setup/screens/mandatory_profile_setup_screen2.dart';
import '../features/profile_setup/services/aadhaar_verification_service.dart';
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

  final _nameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _villageController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  DateTime? _dateOfBirth;

  File? _selfieFile;
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;

  String? _selfieUrl;
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;

  int _currentPage = 0;

  bool _isSaving = false;
  bool _isVerifying = false;

  bool _aadhaarVerified = false;
  bool _nameMatched = false;
  bool _dobMatched = false;

  String _verificationMessage = '';

  static const Color green = Color(0xFF16A34A);

  bool get _busy => _isSaving || _isVerifying;

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _chooseImage({
    required String title,
    required ImageSource source,
    required String type,
  }) async {
    if (_busy) return;

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) return;

      final file = File(image.path);

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
    } catch (_) {
      _showError(
        'Unable to open $title. Please check camera permission.',
      );
    }
  }

  // ============================================================
  // URL
  // ============================================================

  Future<void> _enterImageUrl({
    required String type,
    required String title,
  }) async {
    if (_busy) return;

    final controller = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'Paste image URL',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                final uri = Uri.tryParse(value);

                if (uri == null ||
                    (uri.scheme != 'http' &&
                        uri.scheme != 'https')) {
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (url == null || !mounted) return;

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
  // IMAGE OPTIONS
  // ============================================================

  Future<void> _showImageOptions({
    required String type,
    required String title,
  }) async {
    if (_busy) return;

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
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Choose how you want to add the image.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8289),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _optionCard(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take photo',
                        onTap: () {
                          Navigator.pop(sheetContext);

                          _chooseImage(
                            title: title,
                            source: ImageSource.camera,
                            type: type,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _optionCard(
                        icon: Icons.link_rounded,
                        title: 'URL',
                        subtitle: 'Paste image URL',
                        onTap: () {
                          Navigator.pop(sheetContext);

                          _enterImageUrl(
                            type: type,
                            title: '$title URL',
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
            borderRadius: BorderRadius.circular(18),
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
                  color: AppColors.primary.withOpacity(.10),
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
  // PAGE 1
  // ============================================================

  void _nextPage() {
    if (_selfieFile == null &&
        (_selfieUrl == null || _selfieUrl!.isEmpty)) {
      _showError('Please add your profile selfie.');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name.');
      return;
    }

    if (_dateOfBirth == null) {
      _showError('Please select your date of birth.');
      return;
    }

    final aadhaar = _aadhaarController.text.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      _showError('Please enter a valid 12-digit Aadhaar number.');
      return;
    }

    if (_villageController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _districtController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty) {
      _showError('Please complete your address details.');
      return;
    }

    if (!RegExp(r'^\d{6}$')
        .hasMatch(_pinCodeController.text.trim())) {
      _showError('Please enter a valid 6-digit PIN code.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _currentPage = 1;
    });

    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // ============================================================
  // BACK
  // ============================================================

  void _previousPage() {
    if (_busy) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _currentPage = 0;
    });

    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    if (_busy) return;

    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(
        now.year - 18,
        now.month,
        now.day,
      ),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (result == null || !mounted) return;

    setState(() {
      _dateOfBirth = result;
      _resetVerification();
    });
  }

  // ============================================================
  // SAVE + FIREBASE
  // ============================================================

  Future<void> _saveAndContinue() async {
    if (_busy) return;

    final frontAvailable =
        _aadhaarFrontFile != null ||
        (_aadhaarFrontUrl?.trim().isNotEmpty ?? false);

    final backAvailable =
        _aadhaarBackFile != null ||
        (_aadhaarBackUrl?.trim().isNotEmpty ?? false);

    if (!frontAvailable) {
      _showError('Please add Aadhaar Front.');
      return;
    }

    if (!backAvailable) {
      _showError('Please add Aadhaar Back.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError('Login session not found. Please login again.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
      _verificationMessage =
          'Submitting Aadhaar for verification...';
      _aadhaarVerified = false;
      _nameMatched = false;
      _dobMatched = false;
    });

    try {
      final result =
          await AadhaarVerificationService.verify(
        authUid: user.uid,
        name: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        aadhaarNumber: _aadhaarController.text.trim(),
        frontFile: _aadhaarFrontFile,
        backFile: _aadhaarBackFile,
        frontUrl: _aadhaarFrontUrl,
        backUrl: _aadhaarBackUrl,
      );

      if (!mounted) return;

      if (!result.verified) {
        _showError(
          result.message ??
              'Aadhaar verification was not successful.',
        );
        return;
      }

      if (!result.nameMatched) {
        _showError(
          'The entered name does not match Aadhaar.',
        );
        return;
      }

      if (!result.dobMatched) {
        _showError(
          'The entered Date of Birth does not match Aadhaar.',
        );
        return;
      }

      setState(() {
        _aadhaarVerified = true;
        _nameMatched = true;
        _dobMatched = true;
        _isSaving = true;
        _verificationMessage =
            'Verification successful. Saving profile...';
      });

      await ProfileSetupService.saveWalkerProfile(
        authUid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        name: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        aadhaar: _aadhaarController.text.trim(),
        village: _villageController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        selfieFile: _selfieFile,
        selfieUrl: _selfieUrl,
        aadhaarFrontFile: _aadhaarFrontFile,
        aadhaarFrontUrl: _aadhaarFrontUrl,
        aadhaarBackFile: _aadhaarBackFile,
        aadhaarBackUrl: _aadhaarBackUrl,
        aadhaarVerified: true,
        nameMatched: true,
        dobMatched: true,
        aadhaarVerifiedName: result.verifiedName ?? '',
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isVerifying = false;
        });
      }
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetVerification() {
    _aadhaarVerified = false;
    _nameMatched = false;
    _dobMatched = false;
    _verificationMessage = '';
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),

      // AppBar intentionally removed.
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MandatoryProfileSetupScreen1(
              nameController: _nameController,
              aadhaarController: _aadhaarController,
              villageController: _villageController,
              cityController: _cityController,
              districtController: _districtController,
              stateController: _stateController,
              pinCodeController: _pinCodeController,
              dateOfBirth: _dateOfBirth,
              selfieFile: _selfieFile,
              selfieUrl: _selfieUrl,
              isBusy: _busy,
              onSelectDate: _selectDate,
              onImageOptions: _showImageOptions,
              onNext: _nextPage,
            ),

            MandatoryProfileSetupScreen2(
              aadhaarFrontFile: _aadhaarFrontFile,
              aadhaarFrontUrl: _aadhaarFrontUrl,
              aadhaarBackFile: _aadhaarBackFile,
              aadhaarBackUrl: _aadhaarBackUrl,
              aadhaarVerified: _aadhaarVerified,
              nameMatched: _nameMatched,
              dobMatched: _dobMatched,
              verificationMessage: _verificationMessage,
              isVerifying: _isVerifying,
              isSaving: _isSaving,
              onImageOptions: _showImageOptions,
              onBack: _previousPage,
              onSave: _saveAndContinue,
            ),
          ],
        ),
      ),
    );
  }

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
