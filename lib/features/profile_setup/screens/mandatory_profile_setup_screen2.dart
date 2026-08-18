import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/aadhaar_verification_service.dart';
import '../services/profile_setup_service.dart';

class MandatoryProfileSetup2 extends StatefulWidget {
  const MandatoryProfileSetup2({
    super.key,
    required this.name,
    required this.aadhaar,
    required this.village,
    required this.city,
    required this.district,
    required this.state,
    required this.pinCode,
    required this.dateOfBirth,
    this.selfieFile,
    this.selfieUrl,
  });

  final String name;
  final String aadhaar;

  final String village;
  final String city;
  final String district;
  final String state;
  final String pinCode;

  final DateTime dateOfBirth;

  final File? selfieFile;
  final String? selfieUrl;

  @override
  State<MandatoryProfileSetup2> createState() =>
      _MandatoryProfileSetup2State();
}

class _MandatoryProfileSetup2State
    extends State<MandatoryProfileSetup2> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF6600);
  static const Color green = Color(0xFF22A447);
  static const Color lightGreen = Color(0xFF6FCF97);
  static const Color blue = Color(0xFF1976D2);

  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263238);
  static const Color muted = Color(0xFF7A858F);

  // ============================================================
  // STATE
  // ============================================================

  final ImagePicker picker = ImagePicker();

  File? frontFile;
  File? backFile;

  String? frontUrl;
  String? backUrl;

  bool isVerifying = false;
  bool isSaving = false;

  bool aadhaarVerified = false;
  bool nameMatched = false;
  bool dobMatched = false;

  String statusMessage = '';

  bool get busy => isVerifying || isSaving;

  // ============================================================
  // IMAGE OPTIONS
  // ============================================================

  Future<void> showImageOptions({
    required String type,
  }) async {
    if (busy) return;

    final String title = type == 'front'
        ? 'Aadhaar Front'
        : 'Aadhaar Back';

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
                  'Choose how you want to add the document.',
                  style: TextStyle(
                    fontSize: 12,
                    color: muted,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: _option(
                        icon:
                            Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take photo',
                        color: orange,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          pickDocument(type);
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _option(
                        icon: Icons.link_rounded,
                        title: 'URL',
                        subtitle: 'Paste image URL',
                        color: blue,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          enterUrl(type);
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

  Widget _option({
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

  Future<void> pickDocument(String type) async {
    try {
      final XFile? image =
          await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) return;

      setState(() {
        if (type == 'front') {
          frontFile = File(image.path);
          frontUrl = null;
        } else {
          backFile = File(image.path);
          backUrl = null;
        }
      });
    } catch (_) {
      showMessage(
        'Unable to open camera.',
        false,
      );
    }
  }

  // ============================================================
  // URL
  // ============================================================

  Future<void> enterUrl(String type) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            type == 'front'
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

    if (result == null) return;

    setState(() {
      if (type == 'front') {
        frontUrl = result;
        frontFile = null;
      } else {
        backUrl = result;
        backFile = null;
      }
    });
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool validateDocuments() {
    final frontAvailable =
        frontFile != null ||
        (frontUrl != null &&
            frontUrl!.trim().isNotEmpty);

    final backAvailable =
        backFile != null ||
        (backUrl != null &&
            backUrl!.trim().isNotEmpty);

    if (!frontAvailable) {
      showMessage(
        'Please add Aadhaar Front.',
        false,
      );
      return false;
    }

    if (!backAvailable) {
      showMessage(
        'Please add Aadhaar Back.',
        false,
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> saveAndContinue() async {
    if (busy) return;

    if (!validateDocuments()) return;

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Login session not found. Please login again.',
        false,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isVerifying = true;
      statusMessage =
          'Submitting documents for verification...';

      aadhaarVerified = false;
      nameMatched = false;
      dobMatched = false;
    });

    try {
      // ========================================================
      // AADHAAR VERIFICATION
      // ========================================================

      final AadhaarVerificationResult result =
          await AadhaarVerificationService.verify(
        authUid: user.uid,
        name: widget.name,
        dateOfBirth: widget.dateOfBirth,
        aadhaarNumber: widget.aadhaar,
        frontFile: frontFile,
        backFile: backFile,
        frontUrl: frontUrl,
        backUrl: backUrl,
      );

      if (!mounted) return;

      if (!result.verified) {
        setState(() {
          isVerifying = false;
          statusMessage = '';
        });

        await showVerificationError(
          'Document Verification Failed',
          result.message ??
              'Aadhaar verification was not successful.',
        );

        return;
      }

      if (!result.nameMatched) {
        setState(() {
          isVerifying = false;
          statusMessage = '';
        });

        await showVerificationError(
          'Name Not Matched',
          'The name entered in the profile does not match the verified Aadhaar name.',
        );

        return;
      }

      if (!result.dobMatched) {
        setState(() {
          isVerifying = false;
          statusMessage = '';
        });

        await showVerificationError(
          'Date of Birth Not Matched',
          'The Date of Birth does not match the verified Aadhaar details.',
        );

        return;
      }

      // ========================================================
      // VERIFIED
      // ========================================================

      setState(() {
        aadhaarVerified = true;
        nameMatched = true;
        dobMatched = true;
        isVerifying = false;
        isSaving = true;

        statusMessage =
            'Documents verified. Saving Walker profile...';
      });

      // ========================================================
      // SAVE FIREBASE PROFILE
      // ========================================================

      await ProfileSetupService.saveWalkerProfile(
        authUid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        name: widget.name,
        dateOfBirth: widget.dateOfBirth,
        aadhaar: widget.aadhaar,
        village: widget.village,
        city: widget.city,
        district: widget.district,
        state: widget.state,
        pinCode: widget.pinCode,
        selfieFile: widget.selfieFile,
        selfieUrl: widget.selfieUrl,
        aadhaarFrontFile: frontFile,
        aadhaarFrontUrl: frontUrl,
        aadhaarBackFile: backFile,
        aadhaarBackUrl: backUrl,
        aadhaarVerified: true,
        nameMatched: true,
        dobMatched: true,
        aadhaarVerifiedName:
            result.verifiedName ?? '',
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
        statusMessage =
            'Profile submitted successfully.';
      });

      // ========================================================
      // GO TO DOJO PLATFORM VERIFICATION PENDING
      // ========================================================

      await Future<void>.delayed(
        const Duration(milliseconds: 400),
      );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/verification-pending',
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'Mandatory profile setup error: $e',
      );

      if (!mounted) return;

      setState(() {
        isVerifying = false;
        isSaving = false;
        statusMessage = '';
      });

      showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        false,
      );
    }
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  Future<void> showVerificationError(
    String title,
    String message,
  ) async {
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAEA),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFD92D20),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: muted,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
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
          backgroundColor:
              success ? green : const Color(0xFFD92D20),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
    required String type,
    required File? file,
    required String? url,
    required Color color,
  }) {
    final bool added =
        file != null ||
        (url != null && url.trim().isNotEmpty);

    return InkWell(
      onTap: () {
        showImageOptions(type: type);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: added
                ? green.withOpacity(.45)
                : const Color(0xFFE3E8ED),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color.withOpacity(.09),
                borderRadius: BorderRadius.circular(16),
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(16),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      added
                          ? Icons.check_circle_rounded
                          : Icons.badge_rounded,
                      color:
                          added ? green : color,
                      size: 29,
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    added
                        ? 'Document added'
                        : subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          added ? green : muted,
                      fontWeight:
                          added
                              ? FontWeight.w700
                              : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              added
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: added ? green : color,
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
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // CUSTOM HEADER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                18,
                15,
                18,
                17,
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
                  IconButton(
                    onPressed: busy
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 19,
                    ),
                  ),

                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: blue,
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 11),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Walker',
                          style: TextStyle(
                            fontSize: 11,
                            color: blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Document Verification',
                          style: TextStyle(
                            fontSize: 18,
                            color: textDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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
                  20,
                  18,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Document Requirements',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Add both sides of your Aadhaar for verification.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // FRONT
                    documentCard(
                      title: 'Aadhaar Front',
                      subtitle:
                          'Camera or image URL',
                      type: 'front',
                      file: frontFile,
                      url: frontUrl,
                      color: orange,
                    ),

                    const SizedBox(height: 14),

                    // BACK
                    documentCard(
                      title: 'Aadhaar Back',
                      subtitle:
                          'Camera or image URL',
                      type: 'back',
                      file: backFile,
                      url: backUrl,
                      color: blue,
                    ),

                    const SizedBox(height: 20),

                    // SECURITY CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFEFFAF3),
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color: green.withOpacity(.15),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            color: green,
                            size: 23,
                          ),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'Your documents are securely submitted for DOJO Platform verification.',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                color: Color(
                                  0xFF37604A,
                                ),
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // VERIFICATION STATUS
                    // ==================================================

                    if (statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: lightGreen
                              .withOpacity(.10),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              aadhaarVerified
                                  ? Icons
                                      .check_circle_rounded
                                  : Icons
                                      .verified_user_rounded,
                              color: green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                statusMessage,
                                style:
                                    const TextStyle(
                                  color: Color(
                                    0xFF37604A,
                                  ),
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ==================================================
                    // SAVE BUTTON - CENTER
                    // ==================================================

                    Center(
                      child: SizedBox(
                        width: 225,
                        height: 55,
                        child: ElevatedButton(
                          onPressed:
                              busy
                                  ? null
                                  : saveAndContinue,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                lightGreen,
                            disabledBackgroundColor:
                                const Color(
                              0xFFB9DEC8,
                            ),
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),
                            ),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Icon(
                                      Icons
                                          .verified_rounded,
                                      size: 20,
                                    ),
                                    SizedBox(width: 9),
                                    Text(
                                      'SAVE & CONTINUE',
                                      style: TextStyle(
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
                    ),

                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        'Your profile will be submitted to DOJO Platform after verification.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: muted,
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
