import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/address_section2.dart';
import '../widgets/aadhaar_section2.dart';
import '../widgets/emergency_contact_section2.dart';
import '../widgets/pan_card2.dart';
import '../widgets/profile_info_card2.dart';
import '../widgets/profile_submit_button2.dart';
import '../widgets/profile_summary_card2.dart';
import 'pending_verification_screen.dart';

class MandatoryProfileSetupScreen2 extends StatefulWidget {
  const MandatoryProfileSetupScreen2({
    super.key,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.selfieUrl,
  });

  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String selfieUrl;

  @override
  State<MandatoryProfileSetupScreen2> createState() =>
      _MandatoryProfileSetupScreen2State();
}

class _MandatoryProfileSetupScreen2State
    extends State<MandatoryProfileSetupScreen2> {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController aadhaarController =
      TextEditingController();

  final TextEditingController aadhaarFrontUrlController =
      TextEditingController();

  final TextEditingController aadhaarBackUrlController =
      TextEditingController();

  final TextEditingController panCardUrlController =
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
  // STATE
  // ============================================================

  bool _saving = false;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    aadhaarController.dispose();
    aadhaarFrontUrlController.dispose();
    aadhaarBackUrlController.dispose();
    panCardUrlController.dispose();

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
  // WALKER ID
  // ============================================================

  String createWalkerId(String uid) {
    final String cleanUid = uid.trim();

    if (cleanUid.length >= 8) {
      return 'WKR-${cleanUid.substring(0, 8).toUpperCase()}';
    }

    return 'WKR-${cleanUid.toUpperCase()}';
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  String get formattedDateOfBirth {
    return '${widget.dateOfBirth.year}-'
        '${widget.dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${widget.dateOfBirth.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // FULL ADDRESS
  // ============================================================

  String get fullAddress {
    final List<String> parts = <String>[
      villageController.text.trim(),
      cityController.text.trim(),
      districtController.text.trim(),
      stateController.text.trim(),
      pinController.text.trim(),
    ]
        .where(
          (String value) => value.isNotEmpty,
        )
        .toList();

    return parts.join(', ');
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
  // URL VALIDATOR
  // ============================================================

  bool isValidUrl(String value) {
    final String cleanValue = value.trim();

    final Uri? uri = Uri.tryParse(cleanValue);

    if (uri == null) {
      return false;
    }

    if (uri.host.isEmpty) {
      return false;
    }

    return uri.scheme == 'http' ||
        uri.scheme == 'https';
  }

  // ============================================================
  // URL INPUT DIALOG
  // ============================================================

  Future<void> showUrlDialog({
    required String title,
    required TextEditingController controller,
  }) async {
    final TextEditingController dialogController =
        TextEditingController(
      text: controller.text,
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: dialogController,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  dialogController.text.trim(),
                );
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );

    dialogController.dispose();

    if (!mounted || result == null) {
      return;
    }

    controller.text = result;

    setState(() {});
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool validate() {
    // ----------------------------------------------------------
    // AADHAAR NUMBER
    // ----------------------------------------------------------

    final String aadhaar =
        aadhaarController.text.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      showMessage(
        'Enter a valid 12-digit Aadhaar number.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // AADHAAR FRONT
    // ----------------------------------------------------------

    final String aadhaarFront =
        aadhaarFrontUrlController.text.trim();

    if (aadhaarFront.isEmpty) {
      showMessage(
        'Please add Aadhaar Front document.',
        false,
      );
      return false;
    }

    if (!isValidUrl(aadhaarFront)) {
      showMessage(
        'Aadhaar Front image URL is invalid.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // AADHAAR BACK
    // ----------------------------------------------------------

    final String aadhaarBack =
        aadhaarBackUrlController.text.trim();

    if (aadhaarBack.isEmpty) {
      showMessage(
        'Please add Aadhaar Back document.',
        false,
      );
      return false;
    }

    if (!isValidUrl(aadhaarBack)) {
      showMessage(
        'Aadhaar Back image URL is invalid.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // PAN
    // ----------------------------------------------------------

    final String pan =
        panCardUrlController.text.trim();

    if (pan.isEmpty) {
      showMessage(
        'Please add PAN Card document.',
        false,
      );
      return false;
    }

    if (!isValidUrl(pan)) {
      showMessage(
        'PAN Card image URL is invalid.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // ADDRESS
    // ----------------------------------------------------------

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

    final String pin =
        pinController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      showMessage(
        'Enter a valid 6-digit PIN code.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // EMERGENCY CONTACT - OPTIONAL
    // ----------------------------------------------------------

    final String emergencyName =
        emergencyNameController.text.trim();

    final String emergencyMobile =
        emergencyMobileController.text.trim();

    if (emergencyName.isNotEmpty ||
        emergencyMobile.isNotEmpty) {
      if (emergencyName.isEmpty) {
        showMessage(
          'Please enter emergency contact name.',
          false,
        );
        return false;
      }

      if (emergencyMobile.isEmpty) {
        showMessage(
          'Please enter emergency contact mobile.',
          false,
        );
        return false;
      }

      if (!RegExp(r'^\d{10}$')
          .hasMatch(emergencyMobile)) {
        showMessage(
          'Enter a valid 10-digit emergency mobile number.',
          false,
        );
        return false;
      }
    }

    // ----------------------------------------------------------
    // SCREEN 1 DATA
    // ----------------------------------------------------------

    if (widget.name.trim().isEmpty) {
      showMessage(
        'Name is missing. Please go back.',
        false,
      );
      return false;
    }

    if (widget.gender.trim().isEmpty) {
      showMessage(
        'Gender is missing. Please go back.',
        false,
      );
      return false;
    }

    if (widget.selfieUrl.trim().isEmpty) {
      showMessage(
        'Profile selfie is missing. Please go back.',
        false,
      );
      return false;
    }

    if (!isValidUrl(widget.selfieUrl)) {
      showMessage(
        'Profile selfie URL is invalid.',
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

    if (_saving) {
      return;
    }

    if (!validate()) {
      return;
    }

    final User? user = currentUser;

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
      final String uid = user.uid;

      final String walkerId =
          createWalkerId(uid);

      final String fullName =
          widget.name.trim();

      final String phoneNumber =
          user.phoneNumber ?? '';

      final String cleanGender =
          widget.gender.trim();

      final String aadhaarNumber =
          aadhaarController.text.trim();

      final String aadhaarFront =
          aadhaarFrontUrlController.text.trim();

      final String aadhaarBack =
          aadhaarBackUrlController.text.trim();

      final String panCard =
          panCardUrlController.text.trim();

      final String village =
          villageController.text.trim();

      final String city =
          cityController.text.trim();

      final String district =
          districtController.text.trim();

      final String state =
          stateController.text.trim();

      final String pincode =
          pinController.text.trim();

      final String emergencyName =
          emergencyNameController.text.trim();

      final String emergencyMobile =
          emergencyMobileController.text.trim();

      final String selfieUrl =
          widget.selfieUrl.trim();

      // ========================================================
      // FIRESTORE DATA
      // ========================================================

      final Map<String, dynamic> data =
          <String, dynamic>{
        // ------------------------------------------------------
        // IDENTITY
        // ------------------------------------------------------

        'authUid': uid,
        'uid': uid,
        'Walker Uid': uid,
        'walkerUid': uid,

        'walkerId': walkerId,
        'Walker ID': walkerId,

        'role': 'walker',

        // ------------------------------------------------------
        // BASIC PROFILE
        // ------------------------------------------------------

        'fullName': fullName,
        'Full Name': fullName,
        'name': fullName,

        'phoneNumber': phoneNumber,
        'Mobile number': phoneNumber,
        'mobileNumber': phoneNumber,

        'dateofbirth': formattedDateOfBirth,
        'Date Of Birth': formattedDateOfBirth,
        'dateOfBirth': formattedDateOfBirth,

        'gender': cleanGender,
        'Gender': cleanGender,

        // ------------------------------------------------------
        // SELFIE
        // ------------------------------------------------------

        'selfie': selfieUrl,
        'Profile Selfie': selfieUrl,
        'profileSelfie': selfieUrl,
        'profileImage': selfieUrl,
        'profileImageUrl': selfieUrl,
        'selfieUrl': selfieUrl,

        // ------------------------------------------------------
        // AADHAAR
        // ------------------------------------------------------

        'aadhaarNumber': aadhaarNumber,
        'Aadhar Number': aadhaarNumber,
        'Aadhaar Number': aadhaarNumber,

        'aadhaarfront': aadhaarFront,
        'aadhaarFront': aadhaarFront,
        'aadhaar_front': aadhaarFront,
        'Aadhaar Front': aadhaarFront,

        'aadhaar_front_uploaded': true,
        'aadhaarFrontUploaded': true,

        'aadhaarback': aadhaarBack,
        'aadhaarBack': aadhaarBack,
        'aadhaar_back': aadhaarBack,
        'Aadhaar Back': aadhaarBack,

        'aadhaar_back_uploaded': true,
        'aadhaarBackUploaded': true,

        // ------------------------------------------------------
        // PAN
        // ------------------------------------------------------

        'panCard': panCard,
        'pan_card': panCard,
        'panCardUrl': panCard,
        'pan_card_url': panCard,
        'PAN Card': panCard,
        'PAN Card URL': panCard,

        'pan_card_uploaded': true,
        'panCardUploaded': true,

        // ------------------------------------------------------
        // VERIFICATION
        // ------------------------------------------------------

        'aadhaarVerified': false,
        'aadhaar_verified': false,

        'panVerified': false,
        'pan_verified': false,

        'nameMatched': false,
        'dobMatched': false,

        // ------------------------------------------------------
        // ADDRESS
        // ------------------------------------------------------

        'village': village,
        'Village': village,

        'city': city,
        'City': city,

        'district': district,
        'District': district,

        'state': state,
        'State': state,

        'pincode': pincode,
        'Pincode': pincode,
        'pinCode': pincode,

        'address': fullAddress,
        'Adress': fullAddress,
        'Address': fullAddress,

        // ------------------------------------------------------
        // EMERGENCY
        // ------------------------------------------------------

        'emergencyContactName': emergencyName,
        'emergencyContactMobile': emergencyMobile,

        // ------------------------------------------------------
        // PROFILE STATE
        // ------------------------------------------------------

        'profileCompleted': true,
        'profile_completed': true,
        'isProfileCompleted': true,

        'verificationStatus': 'pending',
        'verification_status': 'pending',
        'status': 'pending',

        // ------------------------------------------------------
        // ADMIN STATE
        // ------------------------------------------------------

        'adminApproved': false,
        'adminRejected': false,

        'adminApprovedAt': null,
        'adminRejectedAt': null,
        'adminReviewedAt': null,

        // ------------------------------------------------------
        // WALKER STATE
        // ------------------------------------------------------

        'isActive': false,
        'isVerified': false,
        'isAvailable': false,

        // ------------------------------------------------------
        // TIMESTAMPS
        // ------------------------------------------------------

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),

        'submittedAt':
            FieldValue.serverTimestamp(),
      };

      // ========================================================
      // SAVE WALKER
      // ========================================================

      await _firestore
          .collection('walkers')
          .doc(uid)
          .set(
        data,
        SetOptions(merge: true),
      );

      // ========================================================
      // USERS SYNC
      // ========================================================

      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .set(
          <String, dynamic>{
            'uid': uid,
            'walkerUid': uid,
            'walkerId': walkerId,
            'role': 'walker',
            'fullName': fullName,
            'phoneNumber': phoneNumber,
            'profileCompleted': true,
            'verificationStatus': 'pending',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {
        // Optional users sync.
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      showMessage(
        'Profile submitted successfully.',
        true,
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) =>
              const PendingVerificationScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      showMessage(
        _firebaseError(e),
        false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      showMessage(
        'Unable to submit profile. Please try again.',
        false,
      );
    }
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseError(
    FirebaseException e,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firebase permission denied. Check Firestore rules.';

      case 'unauthenticated':
        return 'Login session expired. Please login again.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection.';

      case 'unavailable':
        return 'Firebase is temporarily unavailable.';

      default:
        return e.message ??
            'Firebase error. Please try again.';
    }
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      decoration: const BoxDecoration(
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
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.onPrimary,
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
                  'Aadhaar, PAN & Address',
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
            padding:
                const EdgeInsets.symmetric(
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
              'STEP 2',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w900,
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
        backgroundColor:
            AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              _header(),

              // ==================================================
              // CONTENT
              // ==================================================

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
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
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Complete your identity and address details.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // PROFILE SUMMARY
                      // ==================================================

                      ProfileSummaryCard2(
                        name: widget.name,
                        dateOfBirth:
                            widget.dateOfBirth,
                        gender: widget.gender,
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // AADHAAR
                      // ==================================================

                      AadhaarSection2(
                        aadhaarController:
                            aadhaarController,
                        aadhaarFrontUrl:
                            aadhaarFrontUrlController
                                .text,
                        aadhaarBackUrl:
                            aadhaarBackUrlController
                                .text,
                        onAadhaarFrontTap: () {
                          showUrlDialog(
                            title:
                                'Aadhaar Front',
                            controller:
                                aadhaarFrontUrlController,
                          );
                        },
                        onAadhaarBackTap: () {
                          showUrlDialog(
                            title:
                                'Aadhaar Back',
                            controller:
                                aadhaarBackUrlController,
                          );
                        },
                        enabled: !_saving,
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // PAN
                      // ==================================================

                      PanCard2(
                        url: panCardUrlController.text,
                        onTap: () {
                          showUrlDialog(
                            title: 'PAN Card',
                            controller:
                                panCardUrlController,
                          );
                        },
                        enabled: !_saving,
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // ADDRESS
                      // ==================================================

                      AddressSection2(
                        villageController:
                            villageController,
                        cityController:
                            cityController,
                        districtController:
                            districtController,
                        stateController:
                            stateController,
                        pinController:
                            pinController,
                        fullAddress:
                            fullAddress,
                        enabled: !_saving,
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // EMERGENCY CONTACT
                      // ==================================================

                      EmergencyContactSection2(
                        nameController:
                            emergencyNameController,
                        mobileController:
                            emergencyMobileController,
                        enabled: !_saving,
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // VERIFICATION INFO
                      // ==================================================

                      const ProfileInfoCard2(),

                      const SizedBox(height: 22),

                      // ==================================================
                      // SUBMIT
                      // ==================================================

                      ProfileSubmitButton2(
                        onPressed: submitProfile,
                        saving: _saving,
                      ),

                      const SizedBox(height: 12),

                      const Center(
                        child: Text(
                          'You can continue after DOJO Platform approval.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
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
