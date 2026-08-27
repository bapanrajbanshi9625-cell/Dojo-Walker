// File:
// lib/features/profile_setup/screens/mandatory_profile_setup_screen2.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/profile_setup_service.dart';
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

  final TextEditingController panNumberController =
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

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // WALKER ID
  // ============================================================

  String createWalkerId(String uid) {
    return ProfileSetupService.createWalkerId(uid);
  }

  // ============================================================
  // DOB
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
    ].where(
      (String value) => value.isNotEmpty,
    ).toList();

    return parts.join(', ');
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    aadhaarController.dispose();
    aadhaarFrontUrlController.dispose();
    aadhaarBackUrlController.dispose();
    panNumberController.dispose();
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

    if (cleanValue.isEmpty) {
      return false;
    }

    final Uri? uri = Uri.tryParse(cleanValue);

    if (uri == null || uri.host.isEmpty) {
      return false;
    }

    return uri.scheme == 'http' ||
        uri.scheme == 'https';
  }

  // ============================================================
  // IMAGE URL DIALOG
  // ============================================================

  Future<String?> askForImageUrl({
    required String title,
    required String currentValue,
  }) async {
    final TextEditingController controller =
        TextEditingController(
      text: currentValue,
    );

    final String? result =
        await showDialog<String>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://...',
              prefixIcon: const Icon(
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
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppColors.green,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
              ),
              onPressed: () {
                final String value =
                    controller.text.trim();

                if (!isValidUrl(value)) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  )
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid http/https image URL.',
                        ),
                      ),
                    );

                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text(
                'SAVE',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  // ============================================================
  // AADHAAR FRONT
  // ============================================================

  Future<void> selectAadhaarFront() async {
    if (_saving) {
      return;
    }

    final String? url = await askForImageUrl(
      title: 'Aadhaar Front Image',
      currentValue:
          aadhaarFrontUrlController.text.trim(),
    );

    if (url == null || !mounted) {
      return;
    }

    setState(() {
      aadhaarFrontUrlController.text = url;
    });
  }

  // ============================================================
  // AADHAAR BACK
  // ============================================================

  Future<void> selectAadhaarBack() async {
    if (_saving) {
      return;
    }

    final String? url = await askForImageUrl(
      title: 'Aadhaar Back Image',
      currentValue:
          aadhaarBackUrlController.text.trim(),
    );

    if (url == null || !mounted) {
      return;
    }

    setState(() {
      aadhaarBackUrlController.text = url;
    });
  }

  // ============================================================
  // PAN IMAGE
  // ============================================================

  Future<void> selectPanCard() async {
    if (_saving) {
      return;
    }

    final String? url = await askForImageUrl(
      title: 'PAN Card Image',
      currentValue:
          panCardUrlController.text.trim(),
    );

    if (url == null || !mounted) {
      return;
    }

    setState(() {
      panCardUrlController.text = url;
    });
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool validate() {
    // ==========================================================
    // SCREEN 1 DATA
    // ==========================================================

    final String name =
        widget.name.trim();

    final String gender =
        widget.gender.trim();

    final String selfie =
        widget.selfieUrl.trim();

    if (name.isEmpty) {
      showMessage(
        'Name is missing. Please go back.',
        false,
      );
      return false;
    }

    if (gender.isEmpty) {
      showMessage(
        'Gender is missing. Please go back.',
        false,
      );
      return false;
    }

    if (selfie.isEmpty) {
      showMessage(
        'Profile selfie is missing. Please go back.',
        false,
      );
      return false;
    }

    if (!isValidUrl(selfie)) {
      showMessage(
        'Profile selfie URL is invalid.',
        false,
      );
      return false;
    }

    // ==========================================================
    // AADHAAR NUMBER
    // ==========================================================

    final String aadhaar =
        aadhaarController.text.trim();

    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      showMessage(
        'Enter a valid 12-digit Aadhaar number.',
        false,
      );
      return false;
    }

    // ==========================================================
    // AADHAAR FRONT
    // ==========================================================

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

    // ==========================================================
    // AADHAAR BACK
    // ==========================================================

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

    // ==========================================================
    // PAN NUMBER
    // ==========================================================

    final String panNumber =
        panNumberController.text
            .trim()
            .toUpperCase();

    if (!RegExp(
      r'^[A-Z]{5}[0-9]{4}[A-Z]$',
    ).hasMatch(panNumber)) {
      showMessage(
        'Enter a valid PAN number.',
        false,
      );
      return false;
    }

    // ==========================================================
    // PAN IMAGE
    // ==========================================================

    final String panImage =
        panCardUrlController.text.trim();

    if (panImage.isEmpty) {
      showMessage(
        'Please add PAN Card document.',
        false,
      );
      return false;
    }

    if (!isValidUrl(panImage)) {
      showMessage(
        'PAN Card image URL is invalid.',
        false,
      );
      return false;
    }

    // ==========================================================
    // ADDRESS
    // ==========================================================

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

    // ==========================================================
    // EMERGENCY CONTACT
    // ==========================================================

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

      if (!RegExp(
        r'^\d{10}$',
      ).hasMatch(emergencyMobile)) {
        showMessage(
          'Enter a valid 10-digit emergency mobile number.',
          false,
        );
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // SUBMIT
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
      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        throw Exception(
          'Authentication UID is missing.',
        );
      }

      final String phone =
          (user.phoneNumber ?? '').trim();

      if (phone.isEmpty) {
        throw Exception(
          'Phone number is missing from your login account.',
        );
      }

      // ========================================================
      // VALUES
      // ========================================================

      final String fullName =
          widget.name.trim();

      final String gender =
          widget.gender.trim();

      final String selfie =
          widget.selfieUrl.trim();

      final String aadhaar =
          aadhaarController.text.trim();

      final String aadhaarFront =
          aadhaarFrontUrlController.text.trim();

      final String aadhaarBack =
          aadhaarBackUrlController.text.trim();

      final String panNumber =
          panNumberController.text
              .trim()
              .toUpperCase();

      final String panCard =
          panCardUrlController.text.trim();

      final String address =
          fullAddress;

      final String pinCode =
          pinController.text.trim();

      final String emergencyName =
          emergencyNameController.text.trim();

      final String emergencyMobile =
          emergencyMobileController.text.trim();

      // ========================================================
      // MAIN PROFILE SAVE
      //
      // ProfileSetupService handles:
      // - walkers/{uid}
      // - selfie
      // - Aadhaar
      // - PAN
      // - profileCompleted
      // - verificationStatus=pending
      // - approvalStatus=pending
      // ========================================================

      await ProfileSetupService.saveWalkerProfile(
        authUid: uid,
        phone: phone,

        name: fullName,
        dateOfBirth: widget.dateOfBirth,

        address: address,
        pinCode: pinCode,

        profileImageUrl: selfie,

        aadhaarNumber: aadhaar,

        aadhaarFrontUrl: aadhaarFront,
        aadhaarBackUrl: aadhaarBack,

        panNumber: panNumber,
        panCardUrl: panCard,

        selfieUrl: selfie,
      );

      // ========================================================
      // ADDITIONAL WALKER DATA
      //
      // ProfileSetupService currently does not accept:
      // - gender
      // - emergency contact
      //
      // So these are synced here without replacing the profile.
      // ========================================================

      final String walkerId =
          createWalkerId(uid);

      await _firestore
          .collection(
            ProfileSetupService.walkersCollection,
          )
          .doc(uid)
          .set(
        <String, dynamic>{
          // ----------------------------------------------------
          // IDENTITY COMPATIBILITY
          // ----------------------------------------------------

          'authUid': uid,
          'uid': uid,
          'userId': uid,
          'Walker Uid': uid,
          'walkerUid': uid,

          'walkerId': walkerId,
          'Walker ID': walkerId,

          'role': 'walker',

          // ----------------------------------------------------
          // BASIC PROFILE
          // ----------------------------------------------------

          'fullName': fullName,
          'Full Name': fullName,
          'name': fullName,

          'phoneNumber': phone,
          'Mobile number': phone,
          'mobileNumber': phone,
          'phone': phone,

          'dateofbirth': formattedDateOfBirth,
          'Date Of Birth': formattedDateOfBirth,
          'dateOfBirth': formattedDateOfBirth,

          'gender': gender,
          'Gender': gender,

          // ----------------------------------------------------
          // SELFIE COMPATIBILITY
          // ----------------------------------------------------

          'selfie': selfie,
          'Profile Selfie': selfie,
          'profileSelfie': selfie,
          'profileImage': selfie,
          'profileImageUrl': selfie,
          'selfieUrl': selfie,

          // ----------------------------------------------------
          // AADHAAR COMPATIBILITY
          // ----------------------------------------------------

          'aadhaarNumber': aadhaar,
          'Aadhar Number': aadhaar,
          'Aadhaar Number': aadhaar,

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

          // ----------------------------------------------------
          // PAN COMPATIBILITY
          // ----------------------------------------------------

          'panNumber': panNumber,
          'panCard': panCard,
          'pan_card': panCard,
          'panCardUrl': panCard,
          'pan_card_url': panCard,
          'PAN Card': panCard,
          'PAN Card URL': panCard,

          'pan_card_uploaded': true,
          'panCardUploaded': true,

          // ----------------------------------------------------
          // ADDRESS COMPATIBILITY
          // ----------------------------------------------------

          'village':
              villageController.text.trim(),
          'Village':
              villageController.text.trim(),

          'city':
              cityController.text.trim(),
          'City':
              cityController.text.trim(),

          'district':
              districtController.text.trim(),
          'District':
              districtController.text.trim(),

          'state':
              stateController.text.trim(),
          'State':
              stateController.text.trim(),

          'pincode': pinCode,
          'Pincode': pinCode,
          'pinCode': pinCode,

          'address': address,
          'Adress': address,
          'Address': address,

          // ----------------------------------------------------
          // EMERGENCY
          // ----------------------------------------------------

          'emergencyContactName':
              emergencyName,

          'emergencyContactMobile':
              emergencyMobile,

          // ----------------------------------------------------
          // VERIFICATION STATE
          //
          // IMPORTANT:
          // Profile completion != admin approval.
          // ----------------------------------------------------

          'profileCompleted': true,
          'profile_completed': true,
          'isProfileCompleted': true,

          'verificationStatus': 'pending',
          'verification_status': 'pending',

          'approvalStatus': 'pending',

          'status': 'pending',

          'adminApproved': false,
          'adminRejected': false,

          'approved': false,
          'isApproved': false,

          // ----------------------------------------------------
          // WALKER STATE
          // ----------------------------------------------------

          'active': false,
          'isActive': false,
          'isAvailable': false,
          'isOnline': false,

          // ----------------------------------------------------
          // TIMESTAMP
          // ----------------------------------------------------

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
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
            'userId': uid,

            'walkerUid': uid,
            'walkerId': walkerId,

            'role': 'walker',

            'name': fullName,
            'fullName': fullName,

            'phone': phone,
            'phoneNumber': phone,

            'gender': gender,

            'dateOfBirth':
                formattedDateOfBirth,

            'profileImage': selfie,
            'profileImageUrl': selfie,
            'selfieUrl': selfie,

            'profileCompleted': true,

            'verificationStatus':
                'pending',

            'approvalStatus':
                'pending',

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {
        // Users sync is secondary.
        //
        // The main walker profile has already been saved.
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
        const Duration(
          milliseconds: 500,
        ),
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
        firebaseError(e),
        false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      showMessage(
        message.isEmpty
            ? 'Unable to submit profile. Please try again.'
            : message,
        false,
      );
    }
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String firebaseError(
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

      case 'failed-precondition':
        return 'Firebase configuration is incomplete.';

      default:
        return e.message ??
            'Firebase error. Please try again.';
    }
  }

  // ============================================================
  // PAN NUMBER FIELD
  // ============================================================

  Widget panNumberField() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller: panNumberController,
        enabled: !_saving,
        textCapitalization:
            TextCapitalization.characters,
        keyboardType:
            TextInputType.text,
        maxLength: 10,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        decoration: InputDecoration(
          counterText: '',
          labelText: 'PAN Number',
          hintText: 'ABCDE1234F',
          labelStyle: const TextStyle(
            color: AppColors.muted,
          ),
          prefixIcon: const Icon(
            Icons.badge_rounded,
            color: AppColors.blue,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
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
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color:
                          AppColors.borderLight,
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
                            AppColors.orange,
                        borderRadius:
                            BorderRadius
                                .circular(14),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color:
                            AppColors.onPrimary,
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
                                  AppColors
                                      .orange,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            'Verification Details',
                            style:
                                TextStyle(
                              fontSize: 19,
                              color:
                                  AppColors
                                      .textDark,
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
                        color: AppColors
                            .green
                            .withOpacity(.10),
                        borderRadius:
                            BorderRadius
                                .circular(12),
                      ),
                      child:
                          const Text(
                        'STEP 2',
                        style:
                            TextStyle(
                          color:
                              AppColors
                                  .green,
                          fontSize: 10,
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
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
                        'Complete Verification',
                        style:
                            TextStyle(
                          fontSize: 23,
                          fontWeight:
                              FontWeight
                                  .w900,
                          color:
                              AppColors
                                  .textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'Submit your identity, address and emergency details for DOJO verification.',
                        style:
                            TextStyle(
                          fontSize: 12.5,
                          color:
                              AppColors
                                  .muted,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // PROFILE SUMMARY
                      // ==================================================

                      ProfileSummaryCard2(
                        name: widget.name,
                        dateOfBirth:
                            widget.dateOfBirth,
                        gender:
                            widget.gender,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // AADHAAR
                      // ==================================================

                      AadhaarSection2(
                        aadhaarController:
                            aadhaarController,
                        aadhaarFrontUrl:
                            aadhaarFrontUrlController
                                .text
                                .trim(),
                        aadhaarBackUrl:
                            aadhaarBackUrlController
                                .text
                                .trim(),
                        onAadhaarFrontTap:
                            selectAadhaarFront,
                        onAadhaarBackTap:
                            selectAadhaarBack,
                        enabled:
                            !_saving,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // PAN NUMBER
                      // ==================================================

                      panNumberField(),

                      // ==================================================
                      // PAN IMAGE
                      // ==================================================

                      PanCard2(
                        url: panCardUrlController
                                .text
                                .trim()
                                .isEmpty
                            ? null
                            : panCardUrlController
                                .text
                                .trim(),
                        onTap:
                            selectPanCard,
                        enabled:
                            !_saving,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

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
                        enabled:
                            !_saving,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // EMERGENCY
                      // ==================================================

                      EmergencyContactSection2(
                        nameController:
                            emergencyNameController,
                        mobileController:
                            emergencyMobileController,
                        enabled:
                            !_saving,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // INFORMATION
                      // ==================================================

                      const ProfileInfoCard2(),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // SUBMIT
                      // ==================================================

                      ProfileSubmitButton2(
                        onPressed:
                            submitProfile,
                        saving: _saving,
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
                            fontSize: 10.5,
                            color:
                                AppColors
                                    .muted,
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
