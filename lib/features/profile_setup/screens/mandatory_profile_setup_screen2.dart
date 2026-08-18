// lib/features/profile_setup/screens/mandatory_profile_setup_2.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'pending_verification_screen.dart';

class MandatoryProfileSetup2 extends StatefulWidget {
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
  static const Color blue = Color(0xFF1976D2);
  static const Color red = Color(0xFFD92D20);

  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263238);
  static const Color muted = Color(0xFF7A858F);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emergencyNameController =
      TextEditingController();

  final TextEditingController emergencyPhoneController =
      TextEditingController();

  final TextEditingController experienceController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool agreeTerms = false;
  bool isSubmitting = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool validate() {
    if (emergencyNameController.text.trim().isEmpty) {
      showMessage(
        'Please enter emergency contact name.',
        false,
      );
      return false;
    }

    final phone =
        emergencyPhoneController.text.trim();

    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      showMessage(
        'Enter a valid 10-digit emergency contact number.',
        false,
      );
      return false;
    }

    if (!agreeTerms) {
      showMessage(
        'Please accept the DOJO Walker terms to continue.',
        false,
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> submitProfile() async {
    FocusScope.of(context).unfocus();

    if (isSubmitting) return;

    if (!validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Your login session has expired. Please login again.',
        false,
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final uid = user.uid;

      // ========================================================
      // SELFIE URL
      // ========================================================

      String? profileSelfieUrl = widget.selfieUrl;

      // --------------------------------------------------------
      // If selfie came from camera, upload to Firebase Storage.
      // --------------------------------------------------------

      if (widget.selfieFile != null) {
        final file = widget.selfieFile!;

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('walkers')
            .child(uid)
            .child('profile')
            .child('profile_selfie.jpg');

        await storageRef.putFile(file);

        profileSelfieUrl =
            await storageRef.getDownloadURL();
      }

      // ========================================================
      // FIRESTORE DATA
      // ========================================================

      final walkerData = <String, dynamic>{
        // ------------------------------------------------------
        // Identity
        // ------------------------------------------------------

        'Walker Uid': uid,

        'uid': uid,

        // ------------------------------------------------------
        // Personal Information
        // ------------------------------------------------------

        'Full Name': widget.name,

        'Mobile number':
            user.phoneNumber ?? '',

        'Date Of Birth':
            Timestamp.fromDate(widget.dateOfBirth),

        'Aadhar Number':
            widget.aadhaar,

        // ------------------------------------------------------
        // Address
        // ------------------------------------------------------

        'Adress': {
          'Village / Locality': widget.village,
          'City / Town': widget.city,
          'District': widget.district,
          'State': widget.state,
          'Pincode': widget.pinCode,
        },

        'Pincode': widget.pinCode,

        // ------------------------------------------------------
        // Selfie
        // ------------------------------------------------------

        'Profile Selfie':
            profileSelfieUrl ?? '',

        // ------------------------------------------------------
        // Emergency Contact
        // ------------------------------------------------------

        'emergencyContactName':
            emergencyNameController.text.trim(),

        'emergencyContactPhone':
            emergencyPhoneController.text.trim(),

        // ------------------------------------------------------
        // Walker Experience
        // ------------------------------------------------------

        'experience':
            experienceController.text.trim(),

        // ------------------------------------------------------
        // PROFILE STATE
        // ------------------------------------------------------

        'profileCompleted': true,

        'profileSetupCompleted': true,

        // ------------------------------------------------------
        // VERIFICATION STATE
        // IMPORTANT
        // ------------------------------------------------------

        'verificationStatus': 'pending',

        'walkerIdActive': false,

        // ------------------------------------------------------
        // Admin fields
        // ------------------------------------------------------

        'adminApproved': false,

        'adminRejected': false,

        // ------------------------------------------------------
        // Timestamps
        // ------------------------------------------------------

        'profileSubmittedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),

        'createdAt':
            FieldValue.serverTimestamp(),
      };

      // ========================================================
      // SAVE / MERGE
      // ========================================================

      await FirebaseFirestore.instance
          .collection('walkers')
          .doc(uid)
          .set(
            walkerData,
            SetOptions(merge: true),
          );

      if (!mounted) return;

      // ========================================================
      // OPEN PENDING VERIFICATION
      // ========================================================

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const PendingVerificationScreen(),
        ),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      String message =
          'Unable to submit your profile.';

      if (e.code == 'permission-denied') {
        message =
            'Firebase permission denied. Please check Firestore rules.';
      } else if (e.code == 'unauthenticated') {
        message =
            'Login session expired. Please login again.';
      } else if (e.code == 'storage/unauthorized') {
        message =
            'Unable to upload selfie. Storage permission denied.';
      } else if (e.message != null &&
          e.message!.trim().isNotEmpty) {
        message = e.message!;
      }

      showMessage(message, false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      showMessage(
        'Something went wrong. Please try again.',
        false,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message,
    bool success,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? green : red,
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
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
  // SUMMARY ITEM
  // ============================================================

  Widget summaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: blue.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: blue,
              size: 21,
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
                    fontSize: 10.5,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
                  // BACK
                  InkWell(
                    onTap: isSubmitting
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    borderRadius:
                        BorderRadius.circular(14),
                    child: Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F7),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: textDark,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

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
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Final Verification',
                          style: TextStyle(
                            fontSize: 19,
                            color: textDark,
                            fontWeight:
                                FontWeight.w900,
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
                    const Text(
                      'Almost there!',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Review your information and complete the final details.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: muted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // PROFILE SUMMARY
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(21),
                        border: Border.all(
                          color: const Color(
                            0xFFE3E8ED,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .person_pin_rounded,
                                color: blue,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Profile Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w900,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          summaryItem(
                            icon:
                                Icons.person_rounded,
                            title: 'Full Name',
                            value: widget.name,
                          ),

                          summaryItem(
                            icon:
                                Icons.badge_rounded,
                            title:
                                'Aadhaar Number',
                            value:
                                '•••• •••• ${widget.aadhaar.substring(widget.aadhaar.length - 4)}',
                          ),

                          summaryItem(
                            icon: Icons
                                .calendar_month_rounded,
                            title:
                                'Date of Birth',
                            value:
                                '${widget.dateOfBirth.day.toString().padLeft(2, '0')}/'
                                '${widget.dateOfBirth.month.toString().padLeft(2, '0')}/'
                                '${widget.dateOfBirth.year}',
                          ),

                          summaryItem(
                            icon: Icons
                                .location_on_rounded,
                            title: 'Address',
                            value:
                                '${widget.village}, ${widget.city}, '
                                '${widget.district}, ${widget.state} - '
                                '${widget.pinCode}',
                          ),

                          if (widget.selfieFile != null ||
                              widget.selfieUrl != null)
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(
                                      12),
                              decoration: BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF0FFF5,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                        14),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color: green,
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Walker selfie added successfully',
                                      style: TextStyle(
                                        color: green,
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
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // EMERGENCY CONTACT
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(21),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .contact_emergency_rounded,
                                color: orange,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Emergency Contact',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w900,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Someone we can contact if needed.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: muted,
                            ),
                          ),

                          const SizedBox(height: 16),

                          field(
                            controller:
                                emergencyNameController,
                            label:
                                'Emergency Contact Name',
                            icon:
                                Icons.person_outline_rounded,
                          ),

                          field(
                            controller:
                                emergencyPhoneController,
                            label:
                                'Emergency Contact Number',
                            icon:
                                Icons.phone_rounded,
                            keyboardType:
                                TextInputType.phone,
                            maxLength: 10,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // EXPERIENCE
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(21),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .workspace_premium_rounded,
                                color: blue,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Walker Experience',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w900,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Optional — tell us about your dog walking experience.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: muted,
                            ),
                          ),

                          const SizedBox(height: 15),

                          TextField(
                            controller:
                                experienceController,
                            maxLines: 4,
                            maxLength: 300,
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Example: I have experience walking dogs for 2 years...',
                              hintStyle:
                                  const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor:
                                  const Color(
                                0xFFF8FAFC,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        16),
                                borderSide:
                                    BorderSide.none,
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        16),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(0xFFE3E8ED),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // TERMS
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFFF8F2,
                        ),
                        borderRadius:
                            BorderRadius.circular(17),
                        border: Border.all(
                          color: orange.withOpacity(.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: agreeTerms,
                            activeColor: green,
                            onChanged: isSubmitting
                                ? null
                                : (value) {
                                    setState(() {
                                      agreeTerms =
                                          value ?? false;
                                    });
                                  },
                          ),
                          const SizedBox(width: 5),
                          const Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(top: 11),
                              child: Text(
                                'I confirm that the information provided by me is correct and I agree to the DOJO Walker terms and verification process.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(
                                    0xFF6B4B35,
                                  ),
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // SUBMIT BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            isSubmitting
                                ? null
                                : submitProfile,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: green,
                          disabledBackgroundColor:
                              green.withOpacity(.45),
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    17),
                          ),
                        ),
                        child: isSubmitting
                            ? const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  SizedBox(
                                    width: 21,
                                    height: 21,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<
                                              Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'SUBMITTING...',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w900,
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
                                    size: 21,
                                  ),
                                  SizedBox(width: 9),
                                  Text(
                                    'SUBMIT FOR VERIFICATION',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w900,
                                      letterSpacing: .3,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        'After submission, your account will remain locked until DOJO Platform approves your verification.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.45,
                          color: muted,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'DOJO Platform • DOJO Walker',
                        style: TextStyle(
                          fontSize: 11,
                          color: orange,
                          fontWeight:
                              FontWeight.w800,
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
