// File location:
// lib/features/profile_setup/screens/mandatory_profile_setup_screen1.dart

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
  // ============================================================
  // CONTROLLER
  // ============================================================

  late final TextEditingController nameController;
  late final bool _ownsNameController;

  // ============================================================
  // STATE
  // ============================================================

  DateTime? dateOfBirth;
  String? gender;
  String? selfieUrl;

  // ============================================================
  // INIT
  // ============================================================

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

  // ============================================================
  // DISPOSE
  // ============================================================

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
    if (widget.isBusy) {
      return;
    }

    final DateTime now = DateTime.now();

    DateTime initialDate = dateOfBirth ??
        DateTime(
          now.year - 18,
          now.month,
          now.day,
        );

    if (initialDate.isAfter(now)) {
      initialDate = now;
    }

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
  // PROFILE PHOTO URL
  // ============================================================

  Future<void> enterSelfieUrl() async {
    if (widget.isBusy) {
      return;
    }

    final TextEditingController controller =
        TextEditingController(
      text: selfieUrl ?? '',
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeData theme = Theme.of(dialogContext);
        final ColorScheme colors = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Profile Photo URL',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'https://...',
              prefixIcon: Icon(
                Icons.link_rounded,
                color: AppColors.blue,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: AppColors.green,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
              ),
              onPressed: () {
                final String value = controller.text.trim();

                final Uri? uri = Uri.tryParse(value);

                if (uri == null ||
                    uri.host.isEmpty ||
                    !(uri.scheme == 'http' ||
                        uri.scheme == 'https')) {
                  ScaffoldMessenger.of(dialogContext)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Enter a valid image URL.',
                        ),
                        backgroundColor: AppColors.red,
                      ),
                    );

                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text(
                'USE URL',
              ),
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

    showMessage(
      'Profile photo URL added.',
      true,
    );
  }

  // ============================================================
  // GENDER
  // ============================================================

  Future<void> selectGender() async {
    if (widget.isBusy) {
      return;
    }

    final String? result =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (BuildContext sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);

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
                Text(
                  'Select Gender',
                  style: theme.textTheme.titleLarge?.copyWith(
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

  // ============================================================
  // GENDER OPTION
  // ============================================================

  Widget _genderOption({
    required BuildContext context,
    required String value,
    required IconData icon,
  }) {
    final bool selected = gender == value;

    final Color backgroundColor = selected
        ? AppColors.green.withOpacity(.08)
        : AppColors.surface;

    final Color borderColor =
        selected ? AppColors.green : AppColors.border;

    final Color iconColor =
        selected ? AppColors.green : AppColors.blue;

    return InkWell(
      onTap: () {
        Navigator.pop(
          context,
          value,
        );
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(
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
    final String cleanSelfie =
        selfieUrl?.trim() ?? '';

    final String cleanName =
        nameController.text.trim();

    if (cleanSelfie.isEmpty) {
      showMessage(
        'Please add your profile photo URL.',
        false,
      );
      return false;
    }

    final Uri? selfieUri =
        Uri.tryParse(cleanSelfie);

    if (selfieUri == null ||
        selfieUri.host.isEmpty ||
        !(selfieUri.scheme == 'http' ||
            selfieUri.scheme == 'https')) {
      showMessage(
        'Please enter a valid profile photo URL.',
        false,
      );
      return false;
    }

    if (cleanName.isEmpty) {
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
          selfieUrl: selfieUrl!.trim(),
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
              success ? AppColors.green : AppColors.red,
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
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.muted,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.blue,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
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

    final bool hasSelfie =
        selfieUrl != null &&
        selfieUrl!.trim().isNotEmpty;

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
              decoration: BoxDecoration(
                color: AppColors.surface,
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
                    child: Icon(
                      Icons.pets_rounded,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                        const SizedBox(height: 2),
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
                    child: Text(
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
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
                    Text(
                      'Tell us about yourself',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Enter your basic Walker information.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // PROFILE PHOTO
                    // ==================================================

                    InkWell(
                      onTap: busy
                          ? null
                          : enterSelfieUrl,
                      borderRadius:
                          BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: hasSelfie
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
                                    BorderRadius.circular(17),
                              ),
                              child: hasSelfie
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius
                                              .circular(17),
                                      child: Image.network(
                                        selfieUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Icon(
                                            Icons
                                                .image_not_supported_rounded,
                                            color:
                                                AppColors.orange,
                                            size: 28,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons
                                          .add_a_photo_rounded,
                                      color:
                                          AppColors.orange,
                                      size: 28,
                                    ),
                            ),

                            const SizedBox(width: 13),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile Photo',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w800,
                                      color:
                                          AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hasSelfie
                                        ? 'Photo added • Tap to replace'
                                        : 'Testing के लिए Image URL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: hasSelfie
                                          ? AppColors.green
                                          : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              hasSelfie
                                  ? Icons
                                      .check_circle_rounded
                                  : Icons
                                      .chevron_right_rounded,
                              color: hasSelfie
                                  ? AppColors.green
                                  : AppColors.muted,
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
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
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
                                  color: dateOfBirth == null
                                      ? AppColors.muted
                                      : AppColors.textDark,
                                  fontWeight: dateOfBirth ==
                                          null
                                      ? FontWeight.w400
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
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
                          color: AppColors.surface,
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
                                      : AppColors.textDark,
                                  fontWeight: gender == null
                                      ? FontWeight.w400
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.green,
                          disabledBackgroundColor:
                              AppColors.green
                                  .withOpacity(.45),
                          foregroundColor:
                              AppColors.onPrimary,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(17),
                          ),
                        ),
                        child: busy
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color:
                                      AppColors.onPrimary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'NEXT',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w900,
                                      letterSpacing: .5,
                                      color: AppColors
                                          .onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons
                                        .arrow_forward_rounded,
                                    color: AppColors
                                        .onPrimary,
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
