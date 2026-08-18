import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'mandatory_profile_setup_screen2.dart';

class MandatoryProfileSetupScreen1 extends StatefulWidget {
  const MandatoryProfileSetupScreen1({
    super.key,

    // ============================================================
    // OPTIONAL EXTERNAL CONTROLLERS
    // ============================================================

    this.nameController,
    this.aadhaarController,
    this.villageController,
    this.cityController,
    this.districtController,
    this.stateController,
    this.pinCodeController,

    // ============================================================
    // OPTIONAL EXISTING DATA
    // ============================================================

    this.dateOfBirth,
    this.gender,
    this.selfieFile,
    this.selfieUrl,
    this.aadhaarFrontFile,
    this.aadhaarFrontUrl,
    this.aadhaarBackFile,
    this.aadhaarBackUrl,
    this.isBusy = false,

    // ============================================================
    // OPTIONAL CALLBACKS
    // ============================================================

    this.onSelectDate,
    this.onImageOptions,
    this.onNext,
  });

  final TextEditingController? nameController;
  final TextEditingController? aadhaarController;
  final TextEditingController? villageController;
  final TextEditingController? cityController;
  final TextEditingController? districtController;
  final TextEditingController? stateController;
  final TextEditingController? pinCodeController;

  final DateTime? dateOfBirth;

  final String? gender;

  final File? selfieFile;
  final String? selfieUrl;

  final File? aadhaarFrontFile;
  final String? aadhaarFrontUrl;

  final File? aadhaarBackFile;
  final String? aadhaarBackUrl;

  final bool isBusy;

  final VoidCallback? onSelectDate;
  final VoidCallback? onImageOptions;
  final VoidCallback? onNext;

  @override
  State<MandatoryProfileSetupScreen1> createState() =>
      _MandatoryProfileSetupScreen1State();
}

class _MandatoryProfileSetupScreen1State
    extends State<MandatoryProfileSetupScreen1> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF6600);
  static const Color green = Color(0xFF22A447);
  static const Color blue = Color(0xFF1976D2);

  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263238);
  static const Color muted = Color(0xFF7A858F);
  static const Color red = Color(0xFFD92D20);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController nameController;
  late final TextEditingController aadhaarController;
  late final TextEditingController villageController;
  late final TextEditingController cityController;
  late final TextEditingController districtController;
  late final TextEditingController stateController;
  late final TextEditingController pinController;

  // ============================================================
  // OWNERSHIP
  // ============================================================

  late final bool _ownsNameController;
  late final bool _ownsAadhaarController;
  late final bool _ownsVillageController;
  late final bool _ownsCityController;
  late final bool _ownsDistrictController;
  late final bool _ownsStateController;
  late final bool _ownsPinController;

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  final ImagePicker picker = ImagePicker();

  // ============================================================
  // LOCAL DATA
  // ============================================================

  DateTime? dateOfBirth;

  String? gender;

  File? selfieFile;
  String? selfieUrl;

  File? aadhaarFrontFile;
  String? aadhaarFrontUrl;

  File? aadhaarBackFile;
  String? aadhaarBackUrl;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _ownsNameController = widget.nameController == null;
    _ownsAadhaarController = widget.aadhaarController == null;
    _ownsVillageController = widget.villageController == null;
    _ownsCityController = widget.cityController == null;
    _ownsDistrictController = widget.districtController == null;
    _ownsStateController = widget.stateController == null;
    _ownsPinController = widget.pinCodeController == null;

    nameController =
        widget.nameController ?? TextEditingController();

    aadhaarController =
        widget.aadhaarController ?? TextEditingController();

    villageController =
        widget.villageController ?? TextEditingController();

    cityController =
        widget.cityController ?? TextEditingController();

    districtController =
        widget.districtController ?? TextEditingController();

    stateController =
        widget.stateController ?? TextEditingController();

    pinController =
        widget.pinCodeController ?? TextEditingController();

    dateOfBirth = widget.dateOfBirth;
    gender = widget.gender;

    selfieFile = widget.selfieFile;
    selfieUrl = widget.selfieUrl;

    aadhaarFrontFile = widget.aadhaarFrontFile;
    aadhaarFrontUrl = widget.aadhaarFrontUrl;

    aadhaarBackFile = widget.aadhaarBackFile;
    aadhaarBackUrl = widget.aadhaarBackUrl;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_ownsNameController) {
      nameController.dispose();
    }

    if (_ownsAadhaarController) {
      aadhaarController.dispose();
    }

    if (_ownsVillageController) {
      villageController.dispose();
    }

    if (_ownsCityController) {
      cityController.dispose();
    }

    if (_ownsDistrictController) {
      districtController.dispose();
    }

    if (_ownsStateController) {
      stateController.dispose();
    }

    if (_ownsPinController) {
      pinController.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // FULL ADDRESS
  // ============================================================

  String get fullAddress {
    final parts = <String>[
      villageController.text.trim(),
      cityController.text.trim(),
      districtController.text.trim(),
      stateController.text.trim(),
      pinController.text.trim(),
    ].where((value) => value.isNotEmpty).toList();

    return parts.join(', ');
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  Future<void> selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ??
          DateTime(
            now.year - 18,
            now.month,
            now.day,
          ),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      dateOfBirth = selected;
    });
  }

  // ============================================================
  // GENDER
  // ============================================================

  Future<void> selectGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DADE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Gender',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 18),
                _genderOption(
                  context: sheetContext,
                  value: 'Male',
                  icon: Icons.male_rounded,
                ),
                const SizedBox(height: 10),
                _genderOption(
                  context: sheetContext,
                  value: 'Female',
                  icon: Icons.female_rounded,
                ),
                const SizedBox(height: 10),
                _genderOption(
                  context: sheetContext,
                  value: 'Other',
                  icon: Icons.person_outline_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      gender = selected;
    });
  }

  Widget _genderOption({
    required BuildContext context,
    required String value,
    required IconData icon,
  }) {
    final bool selected = gender == value;

    return InkWell(
      onTap: () {
        Navigator.pop(context, value);
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: selected
              ? green.withOpacity(.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected
                ? green
                : const Color(0xFFE3E8ED),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? green : blue,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: green,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE OPTIONS
  // ============================================================

  Future<void> showSelfieOptions() async {
    if (widget.onImageOptions != null) {
      widget.onImageOptions!.call();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DADE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Walker Selfie',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Choose Camera or Image URL.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _imageOption(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take selfie',
                        color: orange,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          pickSelfie();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _imageOption(
                        icon: Icons.link_rounded,
                        title: 'URL',
                        subtitle: 'Image URL',
                        color: blue,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          enterSelfieUrl();
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

  // ============================================================
  // IMAGE OPTION CARD
  // ============================================================

  Widget _imageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(.15),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELFIE CAMERA
  // ============================================================

  Future<void> pickSelfie() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        selfieFile = File(image.path);
        selfieUrl = null;
      });
    } catch (_) {
      if (!mounted) return;

      showMessage(
        'Unable to open camera. Please check camera permission.',
        false,
      );
    }
  }

  // ============================================================
  // SELFIE URL
  // ============================================================

  Future<void> enterSelfieUrl() async {
    final controller = TextEditingController(
      text: selfieUrl ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Profile Selfie URL',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://...',
              prefixIcon: const Icon(
                Icons.link_rounded,
              ),
              filled: true,
              fillColor: background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final value = controller.text.trim();
                final uri = Uri.tryParse(value);

                if (uri == null ||
                    !(uri.scheme == 'http' ||
                        uri.scheme == 'https')) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid image URL.',
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
              child: const Text('USE URL'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      selfieUrl = result;
      selfieFile = null;
    });
  }

  // ============================================================
  // AADHAAR IMAGE SOURCE
  // ============================================================

  Future<void> showAadhaarOptions({
    required bool front,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DADE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  front
                      ? 'Aadhaar Front'
                      : 'Aadhaar Back',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Use camera or provide an image URL.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _imageOption(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take photo',
                        color: orange,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          pickAadhaarImage(front: front);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _imageOption(
                        icon: Icons.link_rounded,
                        title: 'URL',
                        subtitle: 'Image URL',
                        color: blue,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          enterAadhaarUrl(front: front);
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

  // ============================================================
  // AADHAAR CAMERA
  // ============================================================

  Future<void> pickAadhaarImage({
    required bool front,
  }) async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1800,
        maxHeight: 1200,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        if (front) {
          aadhaarFrontFile = File(image.path);
          aadhaarFrontUrl = null;
        } else {
          aadhaarBackFile = File(image.path);
          aadhaarBackUrl = null;
        }
      });
    } catch (_) {
      if (!mounted) return;

      showMessage(
        'Unable to open camera. Please check camera permission.',
        false,
      );
    }
  }

  // ============================================================
  // AADHAAR URL
  // ============================================================

  Future<void> enterAadhaarUrl({
    required bool front,
  }) async {
    final existingUrl = front
        ? aadhaarFrontUrl
        : aadhaarBackUrl;

    final controller = TextEditingController(
      text: existingUrl ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            front
                ? 'Aadhaar Front URL'
                : 'Aadhaar Back URL',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://...',
              prefixIcon: const Icon(
                Icons.link_rounded,
              ),
              filled: true,
              fillColor: background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final value = controller.text.trim();
                final uri = Uri.tryParse(value);

                if (uri == null ||
                    !(uri.scheme == 'http' ||
                        uri.scheme == 'https')) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid image URL.',
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
              child: const Text('USE URL'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      if (front) {
        aadhaarFrontUrl = result;
        aadhaarFrontFile = null;
      } else {
        aadhaarBackUrl = result;
        aadhaarBackFile = null;
      }
    });
  }

  // ============================================================
  // IMAGE EXISTS
  // ============================================================

  bool get hasSelfie =>
      selfieFile != null ||
      (selfieUrl?.trim().isNotEmpty ?? false);

  bool get hasAadhaarFront =>
      aadhaarFrontFile != null ||
      (aadhaarFrontUrl?.trim().isNotEmpty ?? false);

  bool get hasAadhaarBack =>
      aadhaarBackFile != null ||
      (aadhaarBackUrl?.trim().isNotEmpty ?? false);

  // ============================================================
  // VALIDATION
  // ============================================================

  bool validate() {
    if (!hasSelfie) {
      showMessage(
        'Please add your profile selfie.',
        false,
      );
      return false;
    }

    if (nameController.text.trim().isEmpty) {
      showMessage(
        'Please enter your full name.',
        false,
      );
      return false;
    }

    if (dateOfBirth == null) {
      showMessage(
        'Please select your date of birth.',
        false,
      );
      return false;
    }

    if (gender == null ||
        gender!.trim().isEmpty) {
      showMessage(
        'Please select Male, Female or Other.',
        false,
      );
      return false;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(
      aadhaarController.text.trim(),
    )) {
      showMessage(
        'Enter a valid 12-digit Aadhaar number.',
        false,
      );
      return false;
    }

    if (!hasAadhaarFront) {
      showMessage(
        'Please add Aadhaar Front image.',
        false,
      );
      return false;
    }

    if (!hasAadhaarBack) {
      showMessage(
        'Please add Aadhaar Back image.',
        false,
      );
      return false;
    }

    if (villageController.text.trim().isEmpty) {
      showMessage(
        'Please enter Village / Locality.',
        false,
      );
      return false;
    }

    if (cityController.text.trim().isEmpty) {
      showMessage(
        'Please enter City / Town.',
        false,
      );
      return false;
    }

    if (districtController.text.trim().isEmpty) {
      showMessage(
        'Please enter District.',
        false,
      );
      return false;
    }

    if (stateController.text.trim().isEmpty) {
      showMessage(
        'Please enter State.',
        false,
      );
      return false;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(
      pinController.text.trim(),
    )) {
      showMessage(
        'Enter a valid 6-digit PIN code.',
        false,
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // NEXT
  // ============================================================

  void next() {
    FocusScope.of(context).unfocus();

    if (widget.isBusy) {
      return;
    }

    if (widget.onNext != null) {
      widget.onNext!.call();
      return;
    }

    if (!validate()) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MandatoryProfileSetupScreen2(
          name: nameController.text.trim(),
          aadhaar: aadhaarController.text.trim(),
          village: villageController.text.trim(),
          city: cityController.text.trim(),
          district: districtController.text.trim(),
          state: stateController.text.trim(),
          pinCode: pinController.text.trim(),
          dateOfBirth: dateOfBirth!,
          gender: gender,
          selfieFile: selfieFile,
          selfieUrl: selfieUrl,
          aadhaarFrontFile: aadhaarFrontFile,
          aadhaarFrontUrl: aadhaarFrontUrl,
          aadhaarBackFile: aadhaarBackFile,
          aadhaarBackUrl: aadhaarBackUrl,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message,
    bool success,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? green : red,
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
  // TEXT FIELD
  // ============================================================

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textInputAction:
            TextInputAction.next,
        decoration:
            InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(
            icon,
            color: blue,
          ),
          filled: true,
          fillColor:
              Colors.white,
          counterText: '',
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide:
                BorderSide.none,
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide:
                const BorderSide(
              color:
                  Color(0xFFE3E8ED),
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide:
                const BorderSide(
              color: green,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget documentCard({
    required String title,
    required String subtitle,
    required bool hasImage,
    required VoidCallback onTap,
    File? file,
    String? url,
  }) {
    return InkWell(
      onTap: widget.isBusy
          ? null
          : onTap,
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border:
              Border.all(
            color: hasImage
                ? green.withOpacity(.45)
                : const Color(
                    0xFFE3E8ED,
                  ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 48,
              decoration:
                  BoxDecoration(
                color:
                    blue.withOpacity(.08),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: file != null
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                    )
                  : url != null &&
                          url.trim().isNotEmpty
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons
                                  .image_outlined,
                              color: blue,
                            );
                          },
                        )
                      : const Icon(
                          Icons
                              .add_photo_alternate_rounded,
                          color: blue,
                        ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasImage
                        ? 'Image added'
                        : subtitle,
                    style:
                        TextStyle(
                      fontSize: 11,
                      color: hasImage
                          ? green
                          : muted,
                      fontWeight:
                          hasImage
                              ? FontWeight.w700
                              : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasImage
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color:
                  hasImage ? green : muted,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool busy = widget.isBusy;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                18,
              ),
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                border:
                    Border(
                  bottom:
                      BorderSide(
                    color:
                        Color(0xFFE8EDF1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(
                      color: orange,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons.pets_rounded,
                      color:
                          Colors.white,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Walker',
                          style:
                              TextStyle(
                            fontSize: 11,
                            color: orange,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Personal Information',
                          style:
                              TextStyle(
                            fontSize: 19,
                            color: textDark,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          green.withOpacity(.10),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                        const Text(
                      'STEP 1',
                      style:
                          TextStyle(
                        color: green,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tell us about yourself',
                      style:
                          TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w900,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Complete your Walker profile to continue.',
                      style:
                          TextStyle(
                        fontSize: 12.5,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // SELFIE
                    // ==================================================

                    documentCard(
                      title: 'Walker Selfie',
                      subtitle:
                          'Camera or image URL',
                      hasImage: hasSelfie,
                      file: selfieFile,
                      url: selfieUrl,
                      onTap:
                          showSelfieOptions,
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // NAME
                    // ==================================================

                    field(
                      controller:
                          nameController,
                      label:
                          'Full Name',
                      icon:
                          Icons.person_rounded,
                    ),

                    // ==================================================
                    // DOB
                    // ==================================================

                    InkWell(
                      onTap: busy
                          ? null
                          : () {
                              if (widget
                                      .onSelectDate !=
                                  null) {
                                widget
                                    .onSelectDate!
                                    .call();
                              } else {
                                selectDate();
                              }
                            },
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      child:
                          Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 15,
                          vertical: 17,
                        ),
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 14,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                          border:
                              Border.all(
                            color:
                                const Color(
                              0xFFE3E8ED,
                            ),
                          ),
                        ),
                        child:
                            Row(
                          children: [
                            const Icon(
                              Icons
                                  .calendar_month_rounded,
                              color: blue,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child:
                                  Text(
                                dateOfBirth ==
                                        null
                                    ? 'Date of Birth'
                                    : '${dateOfBirth!.day.toString().padLeft(2, '0')}/'
                                        '${dateOfBirth!.month.toString().padLeft(2, '0')}/'
                                        '${dateOfBirth!.year}',
                                style:
                                    TextStyle(
                                  color: dateOfBirth ==
                                          null
                                      ? muted
                                      : textDark,
                                  fontWeight:
                                      dateOfBirth ==
                                              null
                                          ? FontWeight
                                              .w400
                                          : FontWeight
                                              .w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,
                              color: muted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // GENDER
                    // ==================================================

                    InkWell(
                      onTap: busy
                          ? null
                          : selectGender,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      child:
                          Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 15,
                          vertical: 17,
                        ),
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 14,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                          border:
                              Border.all(
                            color:
                                const Color(
                              0xFFE3E8ED,
                            ),
                          ),
                        ),
                        child:
                            Row(
                          children: [
                            Icon(
                              gender ==
                                      'Female'
                                  ? Icons
                                      .female_rounded
                                  : gender ==
                                          'Male'
                                      ? Icons
                                          .male_rounded
                                      : Icons
                                          .person_outline_rounded,
                              color: blue,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child:
                                  Text(
                                gender ??
                                    'Gender',
                                style:
                                    TextStyle(
                                  color:
                                      gender ==
                                              null
                                          ? muted
                                          : textDark,
                                  fontWeight:
                                      gender ==
                                              null
                                          ? FontWeight
                                              .w400
                                          : FontWeight
                                              .w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,
                              color: muted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // AADHAAR NUMBER
                    // ==================================================

                    field(
                      controller:
                          aadhaarController,
                      label:
                          'Aadhaar Number',
                      icon:
                          Icons.badge_rounded,
                      keyboardType:
                          TextInputType.number,
                      maxLength: 12,
                    ),

                    const SizedBox(height: 4),

                    // ==================================================
                    // AADHAAR DOCUMENTS
                    // ==================================================

                    const Text(
                      'Aadhaar Documents',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'For both documents, Camera and URL are supported.',
                      style:
                          TextStyle(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 12),

                    documentCard(
                      title:
                          'Aadhaar Front',
                      subtitle:
                          'Camera or image URL',
                      hasImage:
                          hasAadhaarFront,
                      file:
                          aadhaarFrontFile,
                      url:
                          aadhaarFrontUrl,
                      onTap: () =>
                          showAadhaarOptions(
                        front: true,
                      ),
                    ),

                    const SizedBox(height: 10),

                    documentCard(
                      title:
                          'Aadhaar Back',
                      subtitle:
                          'Camera or image URL',
                      hasImage:
                          hasAadhaarBack,
                      file:
                          aadhaarBackFile,
                      url:
                          aadhaarBackUrl,
                      onTap: () =>
                          showAadhaarOptions(
                        front: false,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // ADDRESS
                    // ==================================================

                    const Text(
                      'Address',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'All address details will be saved together.',
                      style:
                          TextStyle(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 12),

                    field(
                      controller:
                          villageController,
                      label:
                          'Village / Locality',
                      icon:
                          Icons.location_on_rounded,
                    ),

                    field(
                      controller:
                          cityController,
                      label:
                          'City / Town',
                      icon:
                          Icons.location_city_rounded,
                    ),

                    field(
                      controller:
                          districtController,
                      label:
                          'District',
                      icon:
                          Icons.map_rounded,
                    ),

                    field(
                      controller:
                          stateController,
                      label:
                          'State',
                      icon:
                          Icons.public_rounded,
                    ),

                    field(
                      controller:
                          pinController,
                      label:
                          'PIN Code',
                      icon:
                          Icons.pin_drop_rounded,
                      keyboardType:
                          TextInputType.number,
                      maxLength: 6,
                    ),

                    const SizedBox(height: 5),

                    // ==================================================
                    // ADDRESS PREVIEW
                    // ==================================================

                    if (fullAddress.isNotEmpty)
                      Container(
                        width:
                            double.infinity,
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 18,
                        ),
                        padding:
                            const EdgeInsets
                                .all(14),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFF0F6FF,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                        child:
                            Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Icon(
                              Icons
                                  .home_rounded,
                              color: blue,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child:
                                  Text(
                                fullAddress,
                                style:
                                    const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.45,
                                  color:
                                      textDark,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ==================================================
                    // NEXT
                    // ==================================================

                    Align(
                      alignment:
                          Alignment.centerRight,
                      child:
                          SizedBox(
                        width: 145,
                        height: 52,
                        child:
                            ElevatedButton(
                          onPressed:
                              busy
                                  ? null
                                  : next,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                green,
                            disabledBackgroundColor:
                                green.withOpacity(
                              .45,
                            ),
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                17,
                              ),
                            ),
                          ),
                          child:
                              busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.5,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [
                                        Text(
                                          'NEXT',
                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .w900,
                                            letterSpacing:
                                                .5,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 8,
                                        ),
                                        Icon(
                                          Icons
                                              .arrow_forward_rounded,
                                          size: 19,
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
