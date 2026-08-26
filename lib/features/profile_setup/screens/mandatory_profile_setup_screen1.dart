import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'mandatory_profile_setup_screen2.dart';

class MandatoryProfileSetupScreen1 extends StatefulWidget {
  const MandatoryProfileSetupScreen1({
    super.key,
    this.nameController,
    this.dateOfBirth,
    this.gender,
    this.selfieUrl,
    this.isBusy = false,
  });

  final TextEditingController? nameController;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? selfieUrl;
  final bool isBusy;

  @override
  State<MandatoryProfileSetupScreen1> createState() =>
      _MandatoryProfileSetupScreen1State();
}

class _MandatoryProfileSetupScreen1State
    extends State<MandatoryProfileSetupScreen1> {
  late final TextEditingController nameController;
  late final bool _ownsNameController;

  DateTime? dateOfBirth;
  String? gender;
  String? selfieUrl;

  @override
  void initState() {
    super.initState();

    _ownsNameController = widget.nameController == null;

    nameController =
        widget.nameController ?? TextEditingController();

    dateOfBirth = widget.dateOfBirth;
    gender = widget.gender;
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
    final DateTime now = DateTime.now();

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

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      dateOfBirth = selected;
    });
  }

  // ============================================================
  // SELFIE URL
  // ============================================================

  Future<void> enterSelfieUrl() async {
    final TextEditingController controller =
        TextEditingController(
      text: selfieUrl ?? '',
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
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
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'https://...',
              prefixIcon: const Icon(
                Icons.link_rounded,
              ),
              filled: true,
              fillColor: AppColors.background,
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
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final String value =
                    controller.text.trim();

                final Uri? uri =
                    Uri.tryParse(value);

                if (uri == null ||
                    uri.host.isEmpty ||
                    !(uri.scheme == 'http' ||
                        uri.scheme == 'https')) {
                  ScaffoldMessenger.of(dialogContext)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
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
    });
  }

  // ============================================================
  // GENDER
  // ============================================================

  Future<void> selectGender() async {
    final String? result =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (BuildContext sheetContext) {
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
                    color: AppColors.textDark,
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

    if (result == null || !mounted) {
      return;
    }

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
              ? AppColors.green.withOpacity(.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected
                ? AppColors.green
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? AppColors.green
                  : AppColors.blue,
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.green,
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
    if (selfieUrl == null ||
        selfieUrl!.trim().isEmpty) {
      showMessage(
        'Please add your profile photo URL.',
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

    if (widget.isBusy) {
      return;
    }

    if (!validate()) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MandatoryProfileSetupScreen2(
          name: nameController.text.trim(),
          dateOfBirth: dateOfBirth!,
          gender: gender!,
          selfieUrl: selfieUrl!,
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
          backgroundColor: success
              ? AppColors.green
              : AppColors.red,
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
            color: AppColors.blue,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool busy = widget.isBusy;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    color: AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius:
                          BorderRadius.circular(14),
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
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Walker Information',
                          style: TextStyle(
                            fontSize: 19,
                            color: AppColors.textDark,
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
                      color:
                          AppColors.green.withOpacity(.10),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'STEP 1',
                      style: TextStyle(
                        color: AppColors.green,
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
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Enter your basic Walker information.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ==================================================
                    // PROFILE PHOTO URL
                    // ==================================================

                    InkWell(
                      onTap:
                          busy ? null : enterSelfieUrl,
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
                            color: selfieUrl != null &&
                                    selfieUrl!
                                        .trim()
                                        .isNotEmpty
                                ? AppColors.green
                                    .withOpacity(.45)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.orange
                                    .withOpacity(.10),
                                borderRadius:
                                    BorderRadius.circular(
                                  17,
                                ),
                              ),
                              child: selfieUrl != null &&
                                      selfieUrl!
                                          .trim()
                                          .isNotEmpty
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        17,
                                      ),
                                      child:
                                          Image.network(
                                        selfieUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Icon(
                                            Icons
                                                .image_not_supported_rounded,
                                            color: AppColors
                                                .orange,
                                            size: 28,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .add_a_photo_rounded,
                                      color:
                                          AppColors.orange,
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'Profile Photo',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w800,
                                      color: AppColors
                                          .textDark,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Testing के लिए Image URL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted,
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
                      onTap:
                          busy ? null : selectDate,
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
                            color: AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .calendar_month_rounded,
                              color: AppColors.blue,
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
                                  color: dateOfBirth ==
                                          null
                                      ? AppColors.muted
                                      : AppColors
                                          .textDark,
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
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // GENDER
                    // ==================================================

                    InkWell(
                      onTap:
                          busy ? null : selectGender,
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
                            color: AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              gender == 'Female'
                                  ? Icons.female_rounded
                                  : Icons.male_rounded,
                              color: AppColors.blue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                gender == null
                                    ? 'Gender'
                                    : gender!,
                                style: TextStyle(
                                  color: gender == null
                                      ? AppColors.muted
                                      : AppColors
                                          .textDark,
                                  fontWeight: gender ==
                                          null
                                      ? FontWeight.w400
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,
                              color: AppColors.muted,
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
                        onPressed:
                            busy ? null : next,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.green,
                          disabledBackgroundColor:
                              AppColors.green
                                  .withOpacity(.45),
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
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
                                    MainAxisAlignment
                                        .center,
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
