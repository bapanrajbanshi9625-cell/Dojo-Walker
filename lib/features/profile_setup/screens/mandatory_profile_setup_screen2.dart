import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_setup_service.dart';
import 'pending_verification_screen.dart';

class MandatoryProfileSetupScreen2 extends StatefulWidget {
  const MandatoryProfileSetupScreen2({
    super.key,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.selfieFile,
    this.selfieUrl,
  });

  // ============================================================
  // SCREEN 1 DATA
  // ============================================================

  final String name;
  final DateTime dateOfBirth;
  final String gender;

  final File? selfieFile;
  final String? selfieUrl;

  @override
  State<MandatoryProfileSetupScreen2> createState() =>
      _MandatoryProfileSetupScreen2State();
}

class _MandatoryProfileSetupScreen2State
    extends State<MandatoryProfileSetupScreen2> {
  // ============================================================
  // COLORS
  // ============================================================

  // Walker role color
  static const Color walkerOrange = Color(0xFFFF6600);

  // Success / approved UI
  static const Color green = Color(0xFF22A447);

  // Aadhaar / address information
  static const Color blue = Color(0xFF1976D2);

  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263238);
  static const Color muted = Color(0xFF7A858F);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final ImagePicker _picker = ImagePicker();

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

  final TextEditingController emergencyNameController =
      TextEditingController();

  final TextEditingController emergencyMobileController =
      TextEditingController();

  // ============================================================
  // AADHAAR IMAGES
  // ============================================================

  File? aadhaarFrontFile;
  String? aadhaarFrontUrl;

  File? aadhaarBackFile;
  String? aadhaarBackUrl;

  // ============================================================
  // STATE
  // ============================================================

  bool _saving = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    aadhaarController.dispose();
    villageController.dispose();
    cityController.dispose();
    districtController.dispose();
    stateController.dispose();
    pinController.dispose();
    emergencyNameController.dispose();
    emergencyMobileController.dispose();

    super.dispose();
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
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              success ? green : const Color(0xFFD92D20),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
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
    ].where((e) => e.isNotEmpty).toList();

    return parts.join(', ');
  }

  // ============================================================
  // DOCUMENT OPTIONS
  // ============================================================

  Future<void> showDocumentOptions({
    required String title,
    required bool isFront,
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
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  title,
                  style: const TextStyle(
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

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _imageOption(
                        icon:
                            Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take Photo',
                        color: walkerOrange,
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                          );

                          pickAadhaarImage(
                            isFront: isFront,
                          );
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
                          Navigator.pop(
                            sheetContext,
                          );

                          enterAadhaarUrl(
                            isFront: isFront,
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

  Future<void> pickAadhaarImage({
    required bool isFront,
  }) async {
    try {
      final XFile? image =
          await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      final File file = File(image.path);

      setState(() {
        if (isFront) {
          aadhaarFrontFile = file;
          aadhaarFrontUrl = null;
        } else {
          aadhaarBackFile = file;
          aadhaarBackUrl = null;
        }
      });

      showMessage(
        isFront
            ? 'Aadhaar Front added.'
            : 'Aadhaar Back added.',
        true,
      );
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

  Future<void> enterAadhaarUrl({
    required bool isFront,
  }) async {
    final String oldUrl = isFront
        ? aadhaarFrontUrl ?? ''
        : aadhaarBackUrl ?? '';

    final TextEditingController controller =
        TextEditingController(
      text: oldUrl,
    );

    final String? result =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: Text(
            isFront
                ? 'Aadhaar Front URL'
                : 'Aadhaar Back URL',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType:
                TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://...',
              prefixIcon: const Icon(
                Icons.link_rounded,
              ),
              filled: true,
              fillColor: background,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                final String value =
                    controller.text.trim();

                final Uri? uri =
                    Uri.tryParse(value);

                if (uri == null ||
                    !(uri.scheme == 'http' ||
                        uri.scheme ==
                            'https')) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
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
      if (isFront) {
        aadhaarFrontUrl = result;
        aadhaarFrontFile = null;
      } else {
        aadhaarBackUrl = result;
        aadhaarBackFile = null;
      }
    });

    showMessage(
      isFront
          ? 'Aadhaar Front URL added.'
          : 'Aadhaar Back URL added.',
      true,
    );
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  bool validate() {
    // Aadhaar
    if (!RegExp(r'^\d{12}$').hasMatch(
      aadhaarController.text.trim(),
    )) {
      showMessage(
        'Enter a valid 12-digit Aadhaar number.',
        false,
      );
      return false;
    }

    // Aadhaar Front
    if (aadhaarFrontFile == null &&
        (aadhaarFrontUrl == null ||
            aadhaarFrontUrl!.trim().isEmpty)) {
      showMessage(
        'Please add Aadhaar Front.',
        false,
      );
      return false;
    }

    // Aadhaar Back
    if (aadhaarBackFile == null &&
        (aadhaarBackUrl == null ||
            aadhaarBackUrl!.trim().isEmpty)) {
      showMessage(
        'Please add Aadhaar Back.',
        false,
      );
      return false;
    }

    // Village
    if (villageController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Please enter Village / Locality.',
        false,
      );
      return false;
    }

    // City
    if (cityController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Please enter City / Town.',
        false,
      );
      return false;
    }

    // District
    if (districtController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Please enter District.',
        false,
      );
      return false;
    }

    // State
    if (stateController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Please enter State.',
        false,
      );
      return false;
    }

    // PIN
    if (!RegExp(r'^\d{6}$').hasMatch(
      pinController.text.trim(),
    )) {
      showMessage(
        'Enter a valid 6-digit PIN code.',
        false,
      );
      return false;
    }

    // Emergency name
    if (emergencyNameController.text
        .trim()
        .isEmpty) {
      showMessage(
        'Please enter emergency contact name.',
        false,
      );
      return false;
    }

    // Emergency mobile
    if (!RegExp(r'^\d{10}$').hasMatch(
      emergencyMobileController.text
          .trim(),
    )) {
      showMessage(
        'Enter a valid 10-digit emergency mobile number.',
        false,
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // SUBMIT PROFILE
  // ============================================================

  Future<void> submitProfile() async {
    FocusScope.of(context).unfocus();

    if (_saving) return;

    if (!validate()) return;

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Session expired. Please login again.',
        false,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final String uid = user.uid.trim();

      if (uid.isEmpty) {
        throw Exception(
          'Firebase UID is missing.',
        );
      }

      // ========================================================
      // SAVE THROUGH CENTRAL PROFILE SERVICE
      // ========================================================

      await ProfileSetupService
          .saveWalkerProfile(
        authUid: uid,

        phoneNumber:
            user.phoneNumber?.trim() ?? '',

        name: widget.name.trim(),

        dateOfBirth:
            widget.dateOfBirth,

        gender:
            widget.gender.trim(),

        aadhaar:
            aadhaarController.text.trim(),

        village:
            villageController.text.trim(),

        city:
            cityController.text.trim(),

        district:
            districtController.text.trim(),

        state:
            stateController.text.trim(),

        pinCode:
            pinController.text.trim(),

        // Selfie from Screen 1
        selfieFile:
            widget.selfieFile,

        selfieUrl:
            widget.selfieUrl,

        // Aadhaar Front
        aadhaarFrontFile:
            aadhaarFrontFile,

        aadhaarFrontUrl:
            aadhaarFrontUrl,

        // Aadhaar Back
        aadhaarBackFile:
            aadhaarBackFile,

        aadhaarBackUrl:
            aadhaarBackUrl,

        // Emergency
        emergencyName:
            emergencyNameController
                .text
                .trim(),

        emergencyMobile:
            emergencyMobileController
                .text
                .trim(),

        // Initial verification state
        aadhaarVerified: false,
        nameMatched: false,
        dobMatched: false,
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      // ========================================================
      // SUBMITTED SUCCESSFULLY
      // ========================================================

      showMessage(
        'Profile submitted successfully. Waiting for verification.',
        true,
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      // ========================================================
      // PENDING VERIFICATION
      // ========================================================

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const PendingVerificationScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      showMessage(
        _cleanError(e),
        false,
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    final String text = error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );

    return text.isEmpty
        ? 'Profile submission failed. Please try again.'
        : text;
  }

  // ============================================================
  // FIELD
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
        decoration: InputDecoration(
          labelText: label,

          prefixIcon: Icon(
            icon,
            color: blue,
          ),

          filled: true,
          fillColor: Colors.white,

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
              color: Color(0xFFE3E8ED),
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide:
                const BorderSide(
              color: walkerOrange,
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
    required bool isFront,
  }) {
    final File? file =
        isFront
            ? aadhaarFrontFile
            : aadhaarBackFile;

    final String? url =
        isFront
            ? aadhaarFrontUrl
            : aadhaarBackUrl;

    final bool hasImage =
        file != null ||
        (url != null &&
            url.isNotEmpty);

    return InkWell(
      onTap: _saving
          ? null
          : () {
              showDocumentOptions(
                title: title,
                isFront: isFront,
              );
            },
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(15),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
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
              height: 62,
              decoration:
                  BoxDecoration(
                color:
                    blue.withOpacity(.08),
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                      child:
                          Image.file(
                        file,
                        fit:
                            BoxFit.cover,
                      ),
                    )
                  : url != null &&
                          url.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                          child:
                              Image.network(
                            url,
                            fit:
                                BoxFit.cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Icon(
                                Icons
                                    .badge_rounded,
                                color:
                                    blue,
                                size: 29,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons
                              .badge_rounded,
                          color: blue,
                          size: 29,
                        ),
            ),

            const SizedBox(
              width: 13,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          textDark,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    hasImage
                        ? 'Document added'
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
                              : FontWeight
                                  .normal,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              hasImage
                  ? Icons
                      .check_circle_rounded
                  : Icons
                      .chevron_right_rounded,
              color: hasImage
                  ? green
                  : muted,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget summaryCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFFE3E8ED),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.pets_rounded,
                color: walkerOrange,
              ),
              SizedBox(width: 9),
              Text(
                'Walker Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w900,
                  color: textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _summaryRow(
            'Full Name',
            widget.name,
          ),

          _summaryRow(
            'Date Of Birth',
            '${widget.dateOfBirth.day.toString().padLeft(2, '0')}/'
                '${widget.dateOfBirth.month.toString().padLeft(2, '0')}/'
                '${widget.dateOfBirth.year}',
          ),

          _summaryRow(
            'Gender',
            widget.gender,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style:
                  const TextStyle(
                fontSize: 11,
                color: muted,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 12,
                color: textDark,
                fontWeight:
                    FontWeight.w700,
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
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor:
            background,
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
                  border: Border(
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
                        color:
                            walkerOrange,
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .pets_rounded,
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
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Walker',
                            style:
                                TextStyle(
                              fontSize: 11,
                              color:
                                  walkerOrange,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),

                          SizedBox(
                            height: 2,
                          ),

                          Text(
                            'Aadhaar & Address',
                            style:
                                TextStyle(
                              fontSize: 19,
                              color:
                                  textDark,
                              fontWeight:
                                  FontWeight
                                      .w900,
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
                        color: green
                            .withOpacity(
                          .10,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child:
                          const Text(
                        'STEP 2',
                        style:
                            TextStyle(
                          color:
                              green,
                          fontSize:
                              10,
                          fontWeight:
                              FontWeight
                                  .w900,
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
                      const EdgeInsets
                          .fromLTRB(
                    18,
                    18,
                    18,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Aadhaar & Address',
                        style:
                            TextStyle(
                          fontSize: 23,
                          fontWeight:
                              FontWeight
                                  .w900,
                          color:
                              textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'Complete your Aadhaar and address details.',
                        style:
                            TextStyle(
                          fontSize:
                              12.5,
                          color:
                              muted,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // WALKER SUMMARY
                      // ==================================================

                      summaryCard(),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // AADHAAR CARD
                      // ==================================================

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(
                          18,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
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
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons
                                      .badge_rounded,
                                  color:
                                      blue,
                                ),
                                SizedBox(
                                  width: 9,
                                ),
                                Text(
                                  'Aadhaar',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                    color:
                                        textDark,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            field(
                              controller:
                                  aadhaarController,
                              label:
                                  'Aadhaar Number',
                              icon:
                                  Icons
                                      .credit_card_rounded,
                              keyboardType:
                                  TextInputType
                                      .number,
                              maxLength:
                                  12,
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            documentCard(
                              title:
                                  'Aadhaar Front',
                              subtitle:
                                  'Camera or image URL',
                              isFront:
                                  true,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            documentCard(
                              title:
                                  'Aadhaar Back',
                              subtitle:
                                  'Camera or image URL',
                              isFront:
                                  false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // ADDRESS
                      // ==================================================

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(
                          18,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
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
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons
                                      .location_on_rounded,
                                  color:
                                      blue,
                                ),
                                SizedBox(
                                  width: 9,
                                ),
                                Text(
                                  'Address',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                    color:
                                        textDark,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            field(
                              controller:
                                  villageController,
                              label:
                                  'Village / Locality',
                              icon:
                                  Icons
                                      .location_on_rounded,
                            ),

                            field(
                              controller:
                                  cityController,
                              label:
                                  'City / Town',
                              icon:
                                  Icons
                                      .location_city_rounded,
                            ),

                            field(
                              controller:
                                  districtController,
                              label:
                                  'District',
                              icon:
                                  Icons
                                      .map_rounded,
                            ),

                            field(
                              controller:
                                  stateController,
                              label:
                                  'State',
                              icon:
                                  Icons
                                      .public_rounded,
                            ),

                            field(
                              controller:
                                  pinController,
                              label:
                                  'PIN Code',
                              icon:
                                  Icons
                                      .pin_drop_rounded,
                              keyboardType:
                                  TextInputType
                                      .number,
                              maxLength:
                                  6,
                            ),

                            Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .all(
                                13,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF5F8FC,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
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
                                    color:
                                        green,
                                    size:
                                        19,
                                  ),

                                  const SizedBox(
                                    width: 9,
                                  ),

                                  Expanded(
                                    child:
                                        Text(
                                      fullAddress
                                              .isEmpty
                                          ? 'Address preview'
                                          : fullAddress,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            12,
                                        height:
                                            1.5,
                                        color:
                                            textDark,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // EMERGENCY
                      // ==================================================

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(
                          18,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
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
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons
                                      .contact_emergency_rounded,
                                  color:
                                      walkerOrange,
                                ),
                                SizedBox(
                                  width: 9,
                                ),
                                Text(
                                  'Emergency Contact',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                    color:
                                        textDark,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            const Text(
                              'This person can be contacted if required.',
                              style:
                                  TextStyle(
                                fontSize:
                                    11.5,
                                color:
                                    muted,
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            field(
                              controller:
                                  emergencyNameController,
                              label:
                                  'Emergency Contact Name',
                              icon:
                                  Icons
                                      .person_outline_rounded,
                            ),

                            field(
                              controller:
                                  emergencyMobileController,
                              label:
                                  'Emergency Contact Mobile',
                              icon:
                                  Icons
                                      .phone_rounded,
                              keyboardType:
                                  TextInputType
                                      .phone,
                              maxLength:
                                  10,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // INFO
                      // ==================================================

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(
                          15,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFF0F6FF,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            17,
                          ),
                        ),
                        child:
                            const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Icon(
                              Icons
                                  .info_outline_rounded,
                              color:
                                  blue,
                              size: 21,
                            ),

                            SizedBox(
                              width: 9,
                            ),

                            Expanded(
                              child:
                                  Text(
                                'आपकी जानकारी DOJO Platform verification के लिए भेजी जाएगी। Admin approval तक Walker account pending verification में रहेगा।',
                                style:
                                    TextStyle(
                                  fontSize:
                                      11.5,
                                  height:
                                      1.5,
                                  color:
                                      Color(
                                    0xFF34506E,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // SUBMIT
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,
                        height: 55,
                        child:
                            ElevatedButton(
                          onPressed:
                              _saving
                                  ? null
                                  : submitProfile,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                green,
                            disabledBackgroundColor:
                                green.withOpacity(
                              .55,
                            ),
                            foregroundColor:
                                Colors.white,
                            elevation:
                                0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                17,
                              ),
                            ),
                          ),
                          child: _saving
                              ? const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    SizedBox(
                                      width:
                                          21,
                                      height:
                                          21,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.5,
                                        color:
                                            Colors.white,
                                      ),
                                    ),

                                    SizedBox(
                                      width:
                                          12,
                                    ),

                                    Text(
                                      'SUBMITTING...',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Icon(
                                      Icons
                                          .verified_rounded,
                                    ),

                                    SizedBox(
                                      width:
                                          9,
                                    ),

                                    Text(
                                      'SUBMIT FOR VERIFICATION',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                        letterSpacing:
                                            .3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Center(
                        child: Text(
                          'You can continue after DOJO Platform approval.',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            fontSize:
                                10.5,
                            color:
                                muted,
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
      ),
    );
  }
}
