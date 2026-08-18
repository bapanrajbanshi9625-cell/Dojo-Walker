// lib/features/profile_setup/screens/mandatory_profile_setup_screen1.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'mandatory_profile_setup_2.dart';

class MandatoryProfileSetup1 extends StatefulWidget {
  const MandatoryProfileSetup1({
    super.key,
  });

  @override
  State<MandatoryProfileSetup1> createState() =>
      _MandatoryProfileSetup1State();
}

class _MandatoryProfileSetup1State
    extends State<MandatoryProfileSetup1> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF6600);
  static const Color green = Color(0xFF22A447);
  static const Color blue = Color(0xFF1976D2);

  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263238);
  static const Color muted = Color(0xFF7A858F);
  static const Color borderColor = Color(0xFFE3E8ED);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController aadhaarController =
      TextEditingController();

  final TextEditingController villageController =
      TextEditingController();

  final TextEditingController cityController =
      TextEditingController();

  final TextEditingController districtController =
      TextEditingController();

  final TextEditingController stateController =
      TextEditingController();

  final TextEditingController pinController =
      TextEditingController();

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  final ImagePicker picker = ImagePicker();

  File? selfieFile;
  String? selfieUrl;

  DateTime? dateOfBirth;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    aadhaarController.dispose();
    villageController.dispose();
    cityController.dispose();
    districtController.dispose();
    stateController.dispose();
    pinController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  Future<void> selectDate() async {
    final now = DateTime.now();

    final eighteenYearsAgo = DateTime(
      now.year - 18,
      now.month,
      now.day,
    );

    final selected = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: DateTime(1900),
      lastDate: eighteenYearsAgo,
      helpText: 'Select Date of Birth',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      dateOfBirth = selected;
    });
  }

  // ============================================================
  // SELFIE OPTIONS
  // ============================================================

  Future<void> showSelfieOptions() async {
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
                // Handle
                Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DADE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 22),

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
                  'Choose how you want to add your selfie.',
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
                        subtitle: 'Paste image URL',
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
  // IMAGE OPTION
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
  // CAMERA SELFIE
  // ============================================================

  Future<void> pickSelfie() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        selfieFile = File(image.path);
        selfieUrl = null;
      });
    } catch (e) {
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
    final controller = TextEditingController();

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
            textInputAction: TextInputAction.done,
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
                        uri.scheme == 'https') ||
                    uri.host.isEmpty) {
                  ScaffoldMessenger.of(dialogContext)
                      .hideCurrentSnackBar();

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
  // VALIDATION
  // ============================================================

  bool validate() {
    // ----------------------------------------------------------
    // SELFIE
    // ----------------------------------------------------------

    if (selfieFile == null &&
        (selfieUrl == null ||
            selfieUrl!.trim().isEmpty)) {
      showMessage(
        'Please add your profile selfie.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // NAME
    // ----------------------------------------------------------

    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage(
        'Please enter your full name.',
        false,
      );
      return false;
    }

    if (name.length < 3) {
      showMessage(
        'Please enter your complete name.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // DOB
    // ----------------------------------------------------------

    if (dateOfBirth == null) {
      showMessage(
        'Please select your date of birth.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // AADHAAR
    // ----------------------------------------------------------

    final aadhaar =
        aadhaarController.text.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      showMessage(
        'Enter a valid 12-digit Aadhaar number.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // ADDRESS
    // ----------------------------------------------------------

    final village =
        villageController.text.trim();

    final city =
        cityController.text.trim();

    final district =
        districtController.text.trim();

    final state =
        stateController.text.trim();

    if (village.isEmpty) {
      showMessage(
        'Please enter your village / locality.',
        false,
      );
      return false;
    }

    if (city.isEmpty) {
      showMessage(
        'Please enter your city / town.',
        false,
      );
      return false;
    }

    if (district.isEmpty) {
      showMessage(
        'Please enter your district.',
        false,
      );
      return false;
    }

    if (state.isEmpty) {
      showMessage(
        'Please enter your state.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // PIN
    // ----------------------------------------------------------

    final pin =
        pinController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
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

    if (!validate()) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MandatoryProfileSetup2(
          name: nameController.text.trim(),
          aadhaar: aadhaarController.text.trim(),
          village: villageController.text.trim(),
          city: cityController.text.trim(),
          district: districtController.text.trim(),
          state: stateController.text.trim(),
          pinCode: pinController.text.trim(),
          dateOfBirth: dateOfBirth!,
          selfieFile: selfieFile,
          selfieUrl: selfieUrl,
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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? green
              : const Color(0xFFD92D20),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
    TextCapitalization textCapitalization =
        TextCapitalization.sentences,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: blue,
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: borderColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: green,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELFIE PREVIEW
  // ============================================================

  Widget _selfiePreview() {
    if (selfieFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.file(
          selfieFile!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      );
    }

    if (selfieUrl != null &&
        selfieUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.network(
          selfieUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.link_rounded,
              color: blue,
              size: 28,
            );
          },
          loadingBuilder:
              (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: blue,
                ),
              ),
            );
          },
        ),
      );
    }

    return const Icon(
      Icons.add_a_photo_rounded,
      color: orange,
      size: 28,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                18,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8EDF1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: orange,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Walker',
                          style: TextStyle(
                            fontSize: 11,
                            color: orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 19,
                            color: textDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STEP INDICATOR
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EF),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '1 / 2',
                      style: TextStyle(
                        color: green,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // TITLE
                    // ------------------------------------------------

                    const Text(
                      'Tell us about yourself',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Complete your Walker profile to continue.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ------------------------------------------------
                    // SELFIE
                    // ------------------------------------------------

                    InkWell(
                      onTap: showSelfieOptions,
                      borderRadius:
                          BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                selfieFile != null ||
                                        selfieUrl != null
                                    ? green.withOpacity(.45)
                                    : borderColor,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color:
                                    orange.withOpacity(.10),
                                borderRadius:
                                    BorderRadius.circular(17),
                              ),
                              child: _selfiePreview(),
                            ),

                            const SizedBox(width: 13),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Walker Selfie',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selfieFile != null
                                        ? 'Selfie selected'
                                        : selfieUrl != null
                                            ? 'Selfie URL added'
                                            : 'Camera or image URL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          selfieFile != null ||
                                                  selfieUrl != null
                                              ? green
                                              : muted,
                                      fontWeight:
                                          selfieFile != null ||
                                                  selfieUrl != null
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(
                              Icons.chevron_right_rounded,
                              color: muted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ------------------------------------------------
                    // NAME
                    // ------------------------------------------------

                    field(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_rounded,
                    ),

                    // ------------------------------------------------
                    // DOB
                    // ------------------------------------------------

                    InkWell(
                      onTap: selectDate,
                      borderRadius:
                          BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 17,
                        ),
                        margin:
                            const EdgeInsets.only(
                          bottom: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .calendar_month_rounded,
                              color: blue,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                dateOfBirth == null
                                    ? 'Date of Birth'
                                    : '${dateOfBirth!.day.toString().padLeft(2, '0')}/'
                                        '${dateOfBirth!.month.toString().padLeft(2, '0')}/'
                                        '${dateOfBirth!.year}',
                                style: TextStyle(
                                  color:
                                      dateOfBirth == null
                                          ? muted
                                          : textDark,
                                  fontWeight:
                                      dateOfBirth == null
                                          ? FontWeight.w400
                                          : FontWeight.w700,
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

                    // ------------------------------------------------
                    // AADHAAR
                    // ------------------------------------------------

                    field(
                      controller: aadhaarController,
                      label: 'Aadhaar Number',
                      icon: Icons.badge_rounded,
                      keyboardType:
                          TextInputType.number,
                      maxLength: 12,
                      textCapitalization:
                          TextCapitalization.none,
                    ),

                    const SizedBox(height: 4),

                    // ------------------------------------------------
                    // ADDRESS TITLE
                    // ------------------------------------------------

                    const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Enter your current residential address.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // VILLAGE
                    // ------------------------------------------------

                    field(
                      controller: villageController,
                      label: 'Village / Locality',
                      icon: Icons.location_on_rounded,
                    ),

                    // ------------------------------------------------
                    // CITY
                    // ------------------------------------------------

                    field(
                      controller: cityController,
                      label: 'City / Town',
                      icon: Icons.location_city_rounded,
                    ),

                    // ------------------------------------------------
                    // DISTRICT
                    // ------------------------------------------------

                    field(
                      controller: districtController,
                      label: 'District',
                      icon: Icons.map_rounded,
                    ),

                    // ------------------------------------------------
                    // STATE
                    // ------------------------------------------------

                    field(
                      controller: stateController,
                      label: 'State',
                      icon: Icons.public_rounded,
                    ),

                    // ------------------------------------------------
                    // PIN
                    // ------------------------------------------------

                    field(
                      controller: pinController,
                      label: 'PIN Code',
                      icon: Icons.pin_drop_rounded,
                      keyboardType:
                          TextInputType.number,
                      maxLength: 6,
                      textCapitalization:
                          TextCapitalization.none,
                    ),

                    const SizedBox(height: 5),

                    // ------------------------------------------------
                    // NEXT
                    // ------------------------------------------------

                    Align(
                      alignment:
                          Alignment.centerRight,
                      child: SizedBox(
                        width: 145,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: next,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(17),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                'NEXT',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.w900,
                                  letterSpacing: .5,
                                ),
                              ),
                              SizedBox(width: 8),
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

                    const SizedBox(height: 8),

                    // ------------------------------------------------
                    // SECURITY NOTE
                    // ------------------------------------------------

                    const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: muted,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Your information will be securely submitted '
                            'for DOJO Platform verification.',
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.4,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
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
