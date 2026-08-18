import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../pages/aadhaar_verification_page.dart';
import '../pages/profile_details_page.dart';
import '../services/aadhaar_verification_service.dart';
import '../services/profile_setup_service.dart';

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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

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

  static const Color _green = Color(0xFF16A34A);
  static const Color _background = Color(0xFFF5F7F8);
  static const Color _text = Color(0xFF263746);
  static const Color _muted = Color(0xFF7A8289);

  bool get _isBusy => _isSaving || _isVerifying;

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _chooseImage({
    required String title,
    required ImageSource source,
    required String type,
  }) async {
    if (_isBusy) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) return;

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
    if (_isBusy) return;

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
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'Paste image URL',
              prefixIcon: const Icon(Icons.link_rounded),
              filled: true,
              fillColor: const Color(0xFFF5F7F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final String value = controller.text.trim();

                final Uri? parsed = Uri.tryParse(value);

                if (parsed == null ||
                    !(parsed.scheme == 'http' ||
                        parsed.scheme == 'https')) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid image URL.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, value);
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
    if (_isBusy) return;

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
                        icon: Icons.camera_alt_rounded,
                        title: 'Photo',
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
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    if (_isBusy) return;

    final DateTime now = DateTime.now();

    final DateTime? result = await showDatePicker(
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

    if (result == null || !mounted) return;

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
        (_selfieUrl == null || _selfieUrl!.trim().isEmpty)) {
      _showError('Please add your profile selfie.');
      return false;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name.');
      return false;
    }

    if (_dateOfBirth == null) {
      _showError('Please select your date of birth.');
      return false;
    }

    final String aadhaar = _aadhaarController.text.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      _showError(
        'Please enter a valid 12-digit Aadhaar number.',
      );
      return false;
    }

    if (_villageController.text.trim().isEmpty) {
      _showError('Please enter your village or locality.');
      return false;
    }

    if (_cityController.text.trim().isEmpty) {
      _showError('Please enter your city or town.');
      return false;
    }

    if (_districtController.text.trim().isEmpty) {
      _showError('Please enter your district.');
      return false;
    }

    if (_stateController.text.trim().isEmpty) {
      _showError('Please enter your state.');
      return false;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(
      _pinCodeController.text.trim(),
    )) {
      _showError('Please enter a valid 6-digit PIN code.');
      return false;
    }

    return true;
  }

  // ============================================================
  // NEXT
  // ============================================================

  void _nextPage() {
    if (!_validatePageOne()) return;

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
    if (_isBusy) return;

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
  // SAVE
  // ============================================================

  Future<void> _saveAndContinue() async {
    if (_isBusy) return;

    final bool frontAvailable =
        _aadhaarFrontFile != null ||
        (_aadhaarFrontUrl != null &&
            _aadhaarFrontUrl!.trim().isNotEmpty);

    final bool backAvailable =
        _aadhaarBackFile != null ||
        (_aadhaarBackUrl != null &&
            _aadhaarBackUrl!.trim().isNotEmpty);

    if (!frontAvailable) {
      _showError('Please add Aadhaar Front.');
      return;
    }

    if (!backAvailable) {
      _showError('Please add Aadhaar Back.');
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError(
        'Login session not found. Please login again.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
      _aadhaarVerified = false;
      _nameMatched = false;
      _dobMatched = false;
      _verificationMessage =
          'Submitting Aadhaar for verification...';
    });

    try {
      final AadhaarVerificationResult result =
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
        await _showVerificationPopup(
          title: 'Aadhaar Verification Failed',
          message: result.message ??
              'Aadhaar verification was not successful.',
        );
        return;
      }

      if (!result.nameMatched) {
        await _showVerificationPopup(
          title: 'Name Not Matched',
          message:
              'The entered name does not match the verified Aadhaar name.',
        );
        return;
      }

      if (!result.dobMatched) {
        await _showVerificationPopup(
          title: 'Date of Birth Not Matched',
          message:
              'The entered Date of Birth does not match the verified Aadhaar Date of Birth.',
        );
        return;
      }

      setState(() {
        _aadhaarVerified = true;
        _nameMatched = true;
        _dobMatched = true;
        _verificationMessage =
            'Aadhaar, Name and Date of Birth verified. Saving profile...';
        _isSaving = true;
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

      _showSuccess(
        'Verification successful. Profile saved.',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        '/main',
      );
    } catch (e) {
      debugPrint(
        'Profile verification/save error: $e',
      );

      if (!mounted) return;

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
  // RESET
  // ============================================================

  void _resetVerification() {
    _aadhaarVerified = false;
    _nameMatched = false;
    _dobMatched = false;
    _verificationMessage = '';
  }

  // ============================================================
  // POPUP
  // ============================================================

  Future<void> _showVerificationPopup({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(12),
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
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
  // MESSAGES
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

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
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      elevation: 0,
      toolbarHeight: 68,
      titleSpacing: 20,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ProfileDetailsPage(
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
              isBusy: _isBusy,
              currentPage: _currentPage,
              onSelectDate: _selectDate,
              onImageOptions: _showImageOptions,
              onNext: _nextPage,
            ),
            AadhaarVerificationPage(
              currentPage: _currentPage,
              aadhaarVerified: _aadhaarVerified,
              nameMatched: _nameMatched,
              dobMatched: _dobMatched,
              verificationMessage: _verificationMessage,
              isVerifying: _isVerifying,
              isSaving: _isSaving,
              aadhaarFrontFile: _aadhaarFrontFile,
              aadhaarFrontUrl: _aadhaarFrontUrl,
              aadhaarBackFile: _aadhaarBackFile,
              aadhaarBackUrl: _aadhaarBackUrl,
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
