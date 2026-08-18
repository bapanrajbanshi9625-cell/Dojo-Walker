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

  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263238);
  static const Color muted = Color(0xFF7A858F);
  static const Color red = Color(0xFFD92D20);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emergencyNameController =
      TextEditingController();

  final TextEditingController emergencyMobileController =
      TextEditingController();

  bool _saving = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emergencyNameController.dispose();
    emergencyMobileController.dispose();
    super.dispose();
  }

  // ============================================================
  // ADDRESS
  // IMPORTANT:
  // Firestore main address field = "Address"
  // ============================================================

  String get fullAddress {
    final parts = <String>[
      widget.village.trim(),
      widget.city.trim(),
      widget.district.trim(),
      widget.state.trim(),
      widget.pinCode.trim(),
    ].where((value) => value.isNotEmpty).toList();

    return parts.join(', ');
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool validate() {
    if (emergencyNameController.text.trim().isEmpty) {
      _showMessage(
        'Please enter emergency contact name.',
        false,
      );
      return false;
    }

    final mobile =
        emergencyMobileController.text.trim();

    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      _showMessage(
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

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Session expired. Please login again.',
        false,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final uid = user.uid;

      String? profileSelfieUrl = widget.selfieUrl;

      // ========================================================
      // 1. UPLOAD SELFIE TO FIREBASE STORAGE
      // ========================================================

      if (widget.selfieFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('walkers')
            .child(uid)
            .child('profile')
            .child('profile_selfie.jpg');

        await storageRef.putFile(
          widget.selfieFile!,
          SettableMetadata(
            contentType: 'image/jpeg',
          ),
        );

        profileSelfieUrl =
            await storageRef.getDownloadURL();
      }

      // ========================================================
      // 2. FIRESTORE DOCUMENT
      // ========================================================

      final walkerRef = FirebaseFirestore.instance
          .collection('walkers')
          .doc(uid);

      // ========================================================
      // 3. COMPLETE PROFILE DATA
      // ========================================================

      final Map<String, dynamic> profileData = {
        // ------------------------------------------------------
        // IDENTITY
        // ------------------------------------------------------

        'Walker Uid': uid,

        'Full Name': widget.name.trim(),

        'Mobile number':
            user.phoneNumber ?? '',

        'Aadhar Number':
            widget.aadhaar.trim(),

        'Date Of Birth':
            Timestamp.fromDate(widget.dateOfBirth),

        // ------------------------------------------------------
        // ADDRESS
        // MAIN FIRESTORE FIELD = Address
        // ------------------------------------------------------

        'Address': fullAddress,

        // Individual address fields also stored
        // for Admin/search/display purposes.

        'Village': widget.village.trim(),

        'City': widget.city.trim(),

        'District': widget.district.trim(),

        'State': widget.state.trim(),

        'Pincode': widget.pinCode.trim(),

        // ------------------------------------------------------
        // SELFIE
        // ------------------------------------------------------

        'Profile Selfie':
            profileSelfieUrl ?? '',

        // ------------------------------------------------------
        // VERIFICATION
        // ------------------------------------------------------

        'profileCompleted': true,

        'verificationStatus': 'pending',

        'walkerIdActive': false,

        // ------------------------------------------------------
        // EMERGENCY CONTACT
        // ------------------------------------------------------

        'Emergency Contact Name':
            emergencyNameController.text.trim(),

        'Emergency Contact Mobile':
            emergencyMobileController.text.trim(),

        // ------------------------------------------------------
        // TIMESTAMPS
        // ------------------------------------------------------

        'profileSubmittedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      // ========================================================
      // 4. SAVE EVERYTHING TO WALKERS/{UID}
      // ========================================================

      await walkerRef.set(
        profileData,
        SetOptions(merge: true),
      );

      // ========================================================
      // 5. SUCCESS
      // ========================================================

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      // ========================================================
      // 6. GO TO PENDING VERIFICATION SCREEN
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
        _saving = false;
      });

      _showMessage(
        _firebaseError(e),
        false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Unable to submit profile. Please try again.',
        false,
      );
    }
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firebase permission denied. Please check Firestore rules.';

      case 'unauthorized':
        return 'You are not authorized to upload this profile.';

      case 'object-not-found':
        return 'Profile image could not be uploaded.';

      case 'unauthenticated':
        return 'Your login session has expired.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return e.message ??
            'Firebase error. Please try again.';
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
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

  Widget _field({
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
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E8ED),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.fact_check_rounded,
                color: green,
              ),
              SizedBox(width: 9),
              Text(
                'Profile Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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
            'Address',
            fullAddress,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: textDark,
                fontWeight: FontWeight.w700,
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
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
                            'Verification Details',
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

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: green.withOpacity(.10),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'STEP 2',
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
                  padding:
                      const EdgeInsets.fromLTRB(
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
                        'Review your information and add an emergency contact.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: muted,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // SUMMARY
                      _summaryCard(),

                      const SizedBox(height: 18),

                      // ADDRESS CARD
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
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
                                  Icons.location_on_rounded,
                                  color: blue,
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'Address',
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

                            _addressItem(
                              'Village / Locality',
                              widget.village,
                            ),

                            _addressItem(
                              'City / Town',
                              widget.city,
                            ),

                            _addressItem(
                              'District',
                              widget.district,
                            ),

                            _addressItem(
                              'State',
                              widget.state,
                            ),

                            _addressItem(
                              'PIN Code',
                              widget.pinCode,
                            ),

                            const SizedBox(height: 4),

                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF5F8FC),
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons
                                        .home_rounded,
                                    size: 19,
                                    color: green,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      fullAddress,
                                      style:
                                          const TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: textDark,
                                        fontWeight:
                                            FontWeight.w600,
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

                      // EMERGENCY CONTACT
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
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
                              'This person can be contacted if required.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: muted,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _field(
                              controller:
                                  emergencyNameController,
                              label:
                                  'Emergency Contact Name',
                              icon:
                                  Icons.person_outline_rounded,
                            ),

                            _field(
                              controller:
                                  emergencyMobileController,
                              label:
                                  'Emergency Contact Mobile',
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

                      // INFORMATION
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF0F6FF),
                          borderRadius:
                              BorderRadius.circular(17),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: blue,
                              size: 21,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'After submitting, your profile will be sent to DOJO Platform for verification. Your Walker account will remain locked until an admin approves your verification.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.5,
                                  color:
                                      Color(0xFF34506E),
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
                        height: 55,
                        child: ElevatedButton(
                          onPressed:
                              _saving
                                  ? null
                                  : submitProfile,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: green,
                            disabledBackgroundColor:
                                green.withOpacity(.55),
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(17),
                            ),
                          ),
                          child: _saving
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
                                        color:
                                            Colors.white,
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
                          'You can continue after DOJO Platform approval.',
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
      ),
    );
  }

  // ============================================================
  // ADDRESS ITEM
  // ============================================================

  Widget _addressItem(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
