import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'mandatory_profile_setup_screen2.dart';

class MandatoryProfileSetupScreen1 extends StatefulWidget {
  const MandatoryProfileSetupScreen1({
    super.key,
    this.nameController,
    this.dateOfBirth,
    this.gender,
    this.selfieFile,
    this.selfieUrl,
    this.isBusy = false,
  });

  final TextEditingController? nameController;
  final DateTime? dateOfBirth;
  final String? gender;

  final File? selfieFile;
  final String? selfieUrl;

  final bool isBusy;

  @override
  State<MandatoryProfileSetupScreen1> createState() =>
      _MandatoryProfileSetupScreen1State();
}

class _MandatoryProfileSetupScreen1State
    extends State<MandatoryProfileSetupScreen1> {
  static const Color orange = Color(0xFFFF6600);
  static const Color green = Color(0xFF22A447);
  static const Color blue = Color(0xFF1976D2);

  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263238);
  static const Color muted = Color(0xFF7A858F);
  static const Color red = Color(0xFFD92D20);

  late final TextEditingController nameController;
  late final bool _ownsNameController;

  final ImagePicker _picker = ImagePicker();

  DateTime? dateOfBirth;
  String? gender;

  File? selfieFile;
  String? selfieUrl;

  @override
  void initState() {
    super.initState();

    _ownsNameController = widget.nameController == null;

    nameController =
        widget.nameController ?? TextEditingController();

    dateOfBirth = widget.dateOfBirth;
    gender = widget.gender;

    selfieFile = widget.selfieFile;
    selfieUrl = widget.selfieUrl;
  }

  @override
  void dispose() {
    if (_ownsNameController) {
      nameController.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  Future<void> selectDate() async {
    final now = DateTime.now();

    final DateTime? selected = await showDatePicker(
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

    if (selected == null || !mounted) return;

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
                  'Add Profile Photo',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Camera से फोटो लें या image URL दें।',
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
                        subtitle: 'Take Photo',
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
  // CAMERA
  // ============================================================

  Future<void> pickSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) return;

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
  // URL
  // ============================================================

  Future<void> enterSelfieUrl() async {
    final controller = TextEditingController(
      text: selfieUrl ?? '',
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Profile Photo URL',
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
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
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

    if (result == null || !mounted) return;

    setState(() {
      selfieUrl = result;
      selfieFile = null;
    });
  }

  // ============================================================
  // GENDER
  // ============================================================

  Future<void> selectGender() async {
    final String? result = await showModalBottomSheet<String>(
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
              20,
              20,
              25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
          ),
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      gender = result;
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? green.withOpacity(.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected
                ? green
                : const Color(0xFFE3E8ED),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? green : blue,
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const Spacer(),
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
  // VALIDATE
  // ============================================================

  bool validate() {
    if (selfieFile == null &&
        (selfieUrl == null ||
            selfieUrl!.trim().isEmpty)) {
      showMessage(
        'Please add your profile photo.',
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

    if (gender == null || gender!.trim().isEmpty) {
      showMessage(
        'Please select Male or Female.',
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

    if (widget.isBusy) return;

    if (!validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MandatoryProfileSetupScreen2(
          name: nameController.text.trim(),
          dateOfBirth: dateOfBirth!,
          gender: gender!,

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
          backgroundColor: success ? green : red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: blue,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFE3E8ED),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
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
                          'Walker Information',
                          style: TextStyle(
                            fontSize: 19,
                            color: textDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: green.withOpacity(.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'STEP 1',
                      style: TextStyle(
                        color: green,
                        fontSize: 10,
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
                    const Text(
                      'Tell us about yourself',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Enter your basic Walker information.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // PROFILE PHOTO
                    // ==================================================

                    InkWell(
                      onTap: busy ? null : showSelfieOptions,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: selfieFile != null ||
                                    selfieUrl != null
                                ? green.withOpacity(.45)
                                : const Color(0xFFE3E8ED),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: orange.withOpacity(.10),
                                borderRadius:
                                    BorderRadius.circular(17),
                              ),
                              child: selfieFile != null
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(17),
                                      child: Image.file(
                                        selfieFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : selfieUrl != null &&
                                          selfieUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(17),
                                          child: Image.network(
                                            selfieUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons
                                                    .add_a_photo_rounded,
                                                color: orange,
                                                size: 28,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .add_a_photo_rounded,
                                          color: orange,
                                          size: 28,
                                        ),
                            ),

                            const SizedBox(width: 13),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile Photo',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Camera or image URL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: muted,
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

                    // ==================================================
                    // NAME
                    // ==================================================

                    field(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_rounded,
                    ),

                    // ==================================================
                    // DOB
                    // ==================================================

                    InkWell(
                      onTap: busy ? null : selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 17,
                        ),
                        margin: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE3E8ED),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
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
                                  color: dateOfBirth == null
                                      ? muted
                                      : textDark,
                                  fontWeight: dateOfBirth == null
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

                    // ==================================================
                    // GENDER
                    // ==================================================

                    InkWell(
                      onTap: busy ? null : selectGender,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 17,
                        ),
                        margin: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE3E8ED),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              gender == 'Female'
                                  ? Icons.female_rounded
                                  : Icons.male_rounded,
                              color: blue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                gender == null
                                    ? 'Gender'
                                    : gender!,
                                style: TextStyle(
                                  color: gender == null
                                      ? muted
                                      : textDark,
                                  fontWeight: gender == null
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

                    const SizedBox(height: 8),

                    // ==================================================
                    // NEXT
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: busy ? null : next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          disabledBackgroundColor:
                              green.withOpacity(.45),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(17),
                          ),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
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
                                  ),
                                ],
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
