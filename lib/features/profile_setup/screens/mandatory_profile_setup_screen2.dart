import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/address_section2.dart';
import '../widgets/aadhaar_section2.dart';
import '../widgets/emergency_contact_section2.dart';
import '../widgets/pan_card2.dart';
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
  // URL VALIDATOR
  // ============================================================

  bool isValidUrl(String value) {
    final String cleanValue = value.trim();
    final Uri? uri = Uri.tryParse(cleanValue);

    if (uri == null || uri.host.isEmpty) {
      return false;
    }

    return uri.scheme == 'http' ||
        uri.scheme == 'https';
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  bool validate() {
    final String aadhaar =
        aadhaarController.text.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      showMessage(
        'Enter a valid 12-digit Aadhaar number.',
        false,
      );
      return false;
    }

    final String aadhaarFront =
        aadhaarFrontUrlController.text.trim();

    if (aadhaarFront.isEmpty ||
        !isValidUrl(aadhaarFront)) {
      showMessage(
        'Enter a valid Aadhaar Front Image URL.',
        false,
      );
      return false;
    }

    final String aadhaarBack =
        aadhaarBackUrlController.text.trim();

    if (aadhaarBack.isEmpty ||
        !isValidUrl(aadhaarBack)) {
      showMessage(
        'Enter a valid Aadhaar Back Image URL.',
        false,
      );
      return false;
    }

    final String pan =
        panCardUrlController.text.trim();

    if (pan.isEmpty || !isValidUrl(pan)) {
      showMessage(
        'Enter a valid PAN Card Image URL.',
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

    final String pin =
        pinController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      showMessage(
        'Enter a valid 6-digit PIN code.',
        false,
      );
      return false;
    }

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

      if (!RegExp(r'^\d{10}$')
          .hasMatch(emergencyMobile)) {
        showMessage(
          'Enter a valid 10-digit emergency mobile number.',
          false,
        );
        return false;
      }
    }

    if (widget.name.trim().isEmpty) {
      showMessage(
        'Name is missing. Please go back.',
        false,
      );
      return false;
    }

    if (widget.selfieUrl.trim().isEmpty ||
        !isValidUrl(widget.selfieUrl)) {
      showMessage(
        'Profile selfie URL is missing or invalid.',
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

    return true;
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> submitProfile() async {
    FocusScope.of(context).unfocus();

    if (_saving || !validate()) {
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
      final String walkerId = createWalkerId(uid);
      final String fullName = widget.name.trim();
      final String phoneNumber = user.phoneNumber ?? '';
      final String gender = widget.gender.trim();

      final String aadhaar =
          aadhaarController.text.trim();

      final String aadhaarFront =
          aadhaarFrontUrlController.text.trim();

      final String aadhaarBack =
          aadhaarBackUrlController.text.trim();

      final String pan =
          panCardUrlController.text.trim();

      final String village =
          villageController.text.trim();

      final String city =
          cityController.text.trim();

      final String district =
          districtController.text.trim();

      final String state =
          stateController.text.trim();

      final String pin =
          pinController.text.trim();

      final String address = fullAddress;

      final String emergencyName =
          emergencyNameController.text.trim();

      final String emergencyMobile =
          emergencyMobileController.text.trim();

      final String selfie =
          widget.selfieUrl.trim();

      final Map<String, dynamic> data =
          <String, dynamic>{
        'authUid': uid,
        'uid': uid,
        'walkerUid': uid,
        'walkerId': walkerId,
        'role': 'walker',

        'fullName': fullName,
        'name': fullName,
        'phoneNumber': phoneNumber,

        'dateOfBirth': formattedDateOfBirth,
        'dateofbirth': formattedDateOfBirth,

        'gender': gender,

        'selfie': selfie,
        'selfieUrl': selfie,
        'profileSelfie': selfie,
        'profileImage': selfie,
        'profileImageUrl': selfie,

        'aadhaarNumber': aadhaar,

        'aadhaarFront': aadhaarFront,
        'aadhaarfront': aadhaarFront,
        'aadhaar_front': aadhaarFront,
        'aadhaarFrontUploaded': true,

        'aadhaarBack': aadhaarBack,
        'aadhaarback': aadhaarBack,
        'aadhaar_back': aadhaarBack,
        'aadhaarBackUploaded': true,

        'panCard': pan,
        'panCardUrl': pan,
        'pan_card': pan,
        'panCardUploaded': true,

        'aadhaarVerified': false,
        'panVerified': false,
        'nameMatched': false,
        'dobMatched': false,

        'village': village,
        'city': city,
        'district': district,
        'state': state,
        'pincode': pin,
        'pinCode': pin,

        'address': address,
        'Adress': address,
        'Address': address,

        'emergencyContactName': emergencyName,
        'emergencyContactMobile': emergencyMobile,

        'profileCompleted': true,
        'profile_completed': true,
        'isProfileCompleted': true,

        'verificationStatus': 'pending',
        'verification_status': 'pending',
        'status': 'pending',

        'adminApproved': false,
        'adminRejected': false,

        'isActive': false,
        'isVerified': false,
        'isAvailable': false,

        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
        'submittedAt':
            FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('walkers')
          .doc(uid)
          .set(
            data,
            SetOptions(merge: true),
          );

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
  // SUMMARY
  // ============================================================

  Widget summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: AppColors.green,
              ),
              SizedBox(width: 9),
              Text(
                'Walker Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Full Name', widget.name),
          _summaryRow(
            'Date Of Birth',
            '${widget.dateOfBirth.day.toString().padLeft(2, '0')}/'
            '${widget.dateOfBirth.month.toString().padLeft(2, '0')}/'
            '${widget.dateOfBirth.year}',
          ),
          _summaryRow('Gender', widget.gender),
          _summaryRow('Walker Role', 'Walker'),
        ],
      ),
    );
  }

  Widget _summaryRow(
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
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
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
                color: AppColors.textDark,
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
                        color: AppColors.green
                            .withOpacity(.10),
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

                      summaryCard(),

                      const SizedBox(height: 18),

                      // ==================================================
                      // AADHAAR
                      // ==================================================

                      AadhaarSection2(
                        aadhaarController:
                            aadhaarController,
                        aadhaarFrontUrl:
                            aadhaarFrontUrlController.text,
                        aadhaarBackUrl:
                            aadhaarBackUrlController.text,
                        onAadhaarFrontTap: () {},
                        onAadhaarBackTap: () {},
                        enabled: !_saving,
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // PAN
                      // ==================================================

                      PanCard2(
                        controller:
                            panCardUrlController,
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
                      // EMERGENCY
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
                      // INFO
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.blue
                              .withOpacity(.06),
                          borderRadius:
                              BorderRadius.circular(17),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.blue,
                              size: 21,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'आपकी जानकारी DOJO Platform verification के लिए भेजी जाएगी। Profile पूरा होने के बाद Admin approval तक Walker account pending रहेगा।',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.5,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // SUBMIT
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
                            backgroundColor:
                                AppColors.green,
                            disabledBackgroundColor:
                                AppColors.green
                                    .withOpacity(.55),
                            foregroundColor:
                                AppColors.onPrimary,
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
                                      MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 21,
                                      height: 21,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color:
                                            AppColors.onPrimary,
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
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
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
