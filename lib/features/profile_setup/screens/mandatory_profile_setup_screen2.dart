import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

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
  // DATE
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
  // URL DIALOG
  // ============================================================

  Future<String?> enterDocumentUrl({
    required String title,
    String existingUrl = '',
  }) async {
    final TextEditingController controller =
        TextEditingController(
      text: existingUrl,
    );

    final String? result =
        await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: const TextStyle(
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
                backgroundColor:
                    AppColors.green,
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
              child: const Text('USE URL'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  // ============================================================
  // DOCUMENT URL
  // ============================================================

  Future<void> selectAadhaarFront() async {
    if (_saving) return;

    final String? result =
        await enterDocumentUrl(
      title: 'Aadhaar Front URL',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      aadhaarFrontUrl = result;
    });

    showMessage(
      'Aadhaar Front URL added.',
      true,
    );
  }

  Future<void> selectAadhaarBack() async {
    if (_saving) return;

    final String? result =
        await enterDocumentUrl(
      title: 'Aadhaar Back URL',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      aadhaarBackUrl = result;
    });

    showMessage(
      'Aadhaar Back URL added.',
      true,
    );
  }

  String? aadhaarFrontUrl;
  String? aadhaarBackUrl;

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

    if (aadhaarFrontUrl == null ||
        aadhaarFrontUrl!.trim().isEmpty) {
      showMessage(
        'Please add Aadhaar Front URL.',
        false,
      );
      return false;
    }

    if (aadhaarBackUrl == null ||
        aadhaarBackUrl!.trim().isEmpty) {
      showMessage(
        'Please add Aadhaar Back URL.',
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

    // ==========================================================
    // OPTIONAL EMERGENCY CONTACT
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

    if (widget.selfieUrl.trim().isEmpty) {
      showMessage(
        'Profile selfie URL is missing. Please go back.',
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

      final String gender =
          widget.gender.trim();

      final String aadhaarNumber =
          aadhaarController.text.trim();

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

      final String address =
          fullAddress;

      final String emergencyName =
          emergencyNameController.text.trim();

      final String emergencyMobile =
          emergencyMobileController.text.trim();

      // ========================================================
      // FIRESTORE DATA
      // ========================================================

      final Map<String, dynamic> data =
          <String, dynamic>{
        // ======================================================
        // IDENTITY
        // ======================================================

        'authUid': uid,
        'uid': uid,
        'Walker Uid': uid,
        'walkerUid': uid,

        'walkerId': walkerId,
        'Walker ID': walkerId,

        'role': 'walker',

        // ======================================================
        // BASIC PROFILE
        // ======================================================

        'fullName': fullName,
        'Full Name': fullName,
        'name': fullName,

        'phoneNumber': phoneNumber,
        'Mobile number': phoneNumber,
        'mobileNumber': phoneNumber,

        'dateofbirth':
            formattedDateOfBirth,

        'Date Of Birth':
            formattedDateOfBirth,

        'dateOfBirth':
            formattedDateOfBirth,

        'gender': gender,
        'Gender': gender,

        // ======================================================
        // PROFILE PHOTO URL
        // ======================================================

        'selfie':
            widget.selfieUrl.trim(),

        'Profile Selfie':
            widget.selfieUrl.trim(),

        'profileSelfie':
            widget.selfieUrl.trim(),

        'profileImage':
            widget.selfieUrl.trim(),

        'profileImageUrl':
            widget.selfieUrl.trim(),

        'selfieUrl':
            widget.selfieUrl.trim(),

        // ======================================================
        // AADHAAR
        // ======================================================

        'aadhaarNumber':
            aadhaarNumber,

        'Aadhar Number':
            aadhaarNumber,

        'Aadhaar Number':
            aadhaarNumber,

        'aadhaarfront':
            aadhaarFrontUrl,

        'aadhaarFront':
            aadhaarFrontUrl,

        'aadhaar_front':
            aadhaarFrontUrl,

        'Aadhaar Front':
            aadhaarFrontUrl,

        'aadhaarback':
            aadhaarBackUrl,

        'aadhaarBack':
            aadhaarBackUrl,

        'aadhaar_back':
            aadhaarBackUrl,

        'Aadhaar Back':
            aadhaarBackUrl,

        'aadhaar_front_uploaded':
            true,

        'aadhaar_back_uploaded':
            true,

        'aadhaarFrontUploaded':
            true,

        'aadhaarBackUploaded':
            true,

        // ======================================================
        // VERIFICATION
        // ======================================================

        'aadhaarVerified':
            false,

        'aadhaar_verified':
            false,

        'nameMatched':
            false,

        'dobMatched':
            false,

        // ======================================================
        // ADDRESS
        // ======================================================

        'village':
            village,

        'Village':
            village,

        'city':
            city,

        'City':
            city,

        'district':
            district,

        'District':
            district,

        'state':
            state,

        'State':
            state,

        'pincode':
            pincode,

        'Pincode':
            pincode,

        'pinCode':
            pincode,

        'address':
            address,

        'Adress':
            address,

        'Address':
            address,

        // ======================================================
        // EMERGENCY
        // ======================================================

        'emergencyContactName':
            emergencyName,

        'emergencyContactMobile':
            emergencyMobile,

        // ======================================================
        // PROFILE STATE
        // ======================================================

        'profileCompleted':
            true,

        'profile_completed':
            true,

        'isProfileCompleted':
            true,

        'verificationStatus':
            'pending',

        'verification_status':
            'pending',

        'status':
            'pending',

        // ======================================================
        // ADMIN STATE
        // ======================================================

        'adminApproved':
            false,

        'adminRejected':
            false,

        'adminApprovedAt':
            null,

        'adminRejectedAt':
            null,

        'adminReviewedAt':
            null,

        // ======================================================
        // WALKER STATE
        // ======================================================

        'isActive':
            false,

        'isVerified':
            false,

        'isAvailable':
            false,

        // ======================================================
        // TIMESTAMPS
        // ======================================================

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),

        'submittedAt':
            FieldValue.serverTimestamp(),
      };

      // ========================================================
      // WALKERS
      // ========================================================

      await _firestore
          .collection('walkers')
          .doc(uid)
          .set(
            data,
            SetOptions(
              merge: true,
            ),
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
          SetOptions(
            merge: true,
          ),
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
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // PENDING VERIFICATION
      // ========================================================

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
    } catch (e) {
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
  // TEXT FIELD
  // ============================================================

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
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
            color: AppColors.blue,
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
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
  // DOCUMENT CARD
  // ============================================================

  Widget documentCard({
    required String title,
    required String subtitle,
    required bool isFront,
  }) {
    final String? url = isFront
        ? aadhaarFrontUrl
        : aadhaarBackUrl;

    final bool added =
        url != null &&
        url.trim().isNotEmpty;

    return InkWell(
      onTap: _saving
          ? null
          : isFront
              ? selectAadhaarFront
              : selectAadhaarBack,
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: added
                ? AppColors.green
                    .withOpacity(.45)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.blue
                    .withOpacity(.08),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: added
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                      child: Image.network(
                        url!,
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
                            color:
                                AppColors.blue,
                            size: 29,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.badge_rounded,
                      color:
                          AppColors.blue,
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
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    added
                        ? 'Document added • Tap to replace'
                        : subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: added
                          ? AppColors.green
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              added
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: added
                  ? AppColors.green
                  : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget summaryCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
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
                  fontWeight:
                      FontWeight.w900,
                  color:
                      AppColors.textDark,
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
          _summaryRow(
            'Walker Role',
            'Walker',
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
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color:
                    AppColors.textDark,
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
  // SECTION
  // ============================================================

  Widget sectionContainer({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
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
                  color: Colors.white,
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
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
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
                                  AppColors
                                      .orange,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Aadhaar & Address',
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
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      child:
                          const Text(
                        'STEP 2',
                        style:
                            TextStyle(
                          color:
                              AppColors.green,
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
                      const EdgeInsets.fromLTRB(
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
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight:
                              FontWeight.w900,
                          color:
                              AppColors.textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'Complete your Aadhaar and address details.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color:
                              AppColors.muted,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // SUMMARY
                      // ==================================================

                      summaryCard(),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // AADHAAR
                      // ==================================================

                      sectionContainer(
                        child: Column(
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
                                      AppColors
                                          .blue,
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
                                        AppColors
                                            .textDark,
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
                              icon: Icons
                                  .credit_card_rounded,
                              keyboardType:
                                  TextInputType
                                      .number,
                              maxLength: 12,
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            documentCard(
                              title:
                                  'Aadhaar Front',
                              subtitle:
                                  'Testing के लिए Image URL',
                              isFront: true,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            documentCard(
                              title:
                                  'Aadhaar Back',
                              subtitle:
                                  'Testing के लिए Image URL',
                              isFront: false,
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

                      sectionContainer(
                        child: Column(
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
                                      AppColors
                                          .blue,
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
                                        AppColors
                                            .textDark,
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
                              icon: Icons
                                  .location_on_rounded,
                            ),

                            field(
                              controller:
                                  cityController,
                              label:
                                  'City / Town',
                              icon: Icons
                                  .location_city_rounded,
                            ),

                            field(
                              controller:
                                  districtController,
                              label:
                                  'District',
                              icon: Icons
                                  .map_rounded,
                            ),

                            field(
                              controller:
                                  stateController,
                              label:
                                  'State',
                              icon: Icons
                                  .public_rounded,
                            ),

                            field(
                              controller:
                                  pinController,
                              label:
                                  'PIN Code',
                              icon: Icons
                                  .pin_drop_rounded,
                              keyboardType:
                                  TextInputType
                                      .number,
                              maxLength: 6,
                            ),

                            Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .all(13),
                              decoration:
                                  BoxDecoration(
                                color:
                                    AppColors
                                        .background,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Icon(
                                    Icons
                                        .home_rounded,
                                    color:
                                        AppColors
                                            .green,
                                    size: 19,
                                  ),
                                  const SizedBox(
                                    width: 9,
                                  ),
                                  Expanded(
                                    child: Text(
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
                                            AppColors
                                                .textDark,
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

                      sectionContainer(
                        child: Column(
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
                                      AppColors
                                          .orange,
                                ),
                                SizedBox(
                                  width: 9,
                                ),
                                Expanded(
                                  child:
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
                                          AppColors
                                              .textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  'OPTIONAL',
                                  style:
                                      TextStyle(
                                    color:
                                        AppColors
                                            .muted,
                                    fontSize:
                                        10,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            const Text(
                              'यह जानकारी optional है। खाली छोड़कर भी आगे बढ़ सकते हैं।',
                              style:
                                  TextStyle(
                                fontSize:
                                    11.5,
                                color:
                                    AppColors
                                        .muted,
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            field(
                              controller:
                                  emergencyNameController,
                              label:
                                  'Emergency Contact Name (Optional)',
                              icon: Icons
                                  .person_outline_rounded,
                            ),

                            field(
                              controller:
                                  emergencyMobileController,
                              label:
                                  'Emergency Contact Mobile (Optional)',
                              icon: Icons
                                  .phone_rounded,
                              keyboardType:
                                  TextInputType
                                      .phone,
                              maxLength: 10,
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
                                .all(15),
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.blue
                                  .withOpacity(.06),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            17,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Icon(
                              Icons
                                  .info_outline_rounded,
                              color:
                                  AppColors
                                      .blue,
                              size: 21,
                            ),
                            SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child: Text(
                                'आपकी जानकारी DOJO Platform verification के लिए भेजी जाएगी। Profile पूरा होने के बाद Admin approval तक Walker account pending रहेगा।',
                                style:
                                    TextStyle(
                                  fontSize:
                                      11.5,
                                  height:
                                      1.5,
                                  color:
                                      AppColors
                                          .textDark,
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
                                AppColors
                                    .green,
                            disabledBackgroundColor:
                                AppColors
                                    .green
                                    .withOpacity(
                              .55,
                            ),
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
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
                                      width: 21,
                                      height: 21,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.5,
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 12,
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
                                      width: 9,
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
                          style: TextStyle(
                            fontSize: 10.5,
                            color:
                                AppColors.muted,
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
