import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  static const Color orange = Color(0xFFFF6600);
  static const Color green = Color(0xFF22A447);
  static const Color blue = Color(0xFF1976D2);

  static const Color background = Color(0xFFF5F8FC);
  static const Color textDark = Color(0xFF263238);
  static const Color muted = Color(0xFF7A858F);
  static const Color red = Color(0xFFD92D20);

  // ============================================================
  // SERVICES
  // ============================================================

  final ImagePicker _picker = ImagePicker();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

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

  // ============================================================
  // AADHAAR DOCUMENTS
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
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

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
    ].where((String value) => value.isNotEmpty).toList();

    return parts.join(', ');
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String get formattedDateOfBirth {
    return '${widget.dateOfBirth.year}-'
        '${widget.dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${widget.dateOfBirth.day.toString().padLeft(2, '0')}';
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
          backgroundColor: success ? green : red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // IMAGE OPTIONS
  // ============================================================

  Future<void> showDocumentOptions({
    required String title,
    required bool isFront,
  }) async {
    if (_saving) return;

    await showModalBottomSheet<void>(
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
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take Photo',
                        color: orange,
                        onTap: () {
                          Navigator.pop(sheetContext);
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
                          Navigator.pop(sheetContext);
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
  // PICK AADHAAR IMAGE
  // ============================================================

  Future<void> pickAadhaarImage({
    required bool isFront,
  }) async {
    if (_saving) return;

    try {
      final XFile? image = await _picker.pickImage(
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
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Unable to open camera. Please check camera permission.',
        false,
      );
    }
  }

  // ============================================================
  // ENTER AADHAAR URL
  // ============================================================

  Future<void> enterAadhaarUrl({
    required bool isFront,
  }) async {
    if (_saving) return;

    final String oldUrl = isFront
        ? aadhaarFrontUrl ?? ''
        : aadhaarBackUrl ?? '';

    final TextEditingController controller =
        TextEditingController(
      text: oldUrl,
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
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
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'https://...',
              prefixIcon:
                  const Icon(Icons.link_rounded),
              filled: true,
              fillColor: background,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
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
                final String value =
                    controller.text.trim();

                final Uri? uri =
                    Uri.tryParse(value);

                if (uri == null ||
                    !(uri.scheme == 'http' ||
                        uri.scheme == 'https') ||
                    uri.host.isEmpty) {
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

    if (result == null || !mounted) return;

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
  // RESOLVE IMAGE
  // ============================================================

  Future<String> _resolveImage({
    required String uid,
    required String folder,
    required String fileName,
    File? file,
    String? url,
  }) async {
    final String cleanUrl =
        url?.trim() ?? '';

    // ----------------------------------------------------------
    // EXISTING URL
    // ----------------------------------------------------------

    if (cleanUrl.isNotEmpty) {
      return cleanUrl;
    }

    // ----------------------------------------------------------
    // UPLOAD FILE
    // ----------------------------------------------------------

    if (file != null) {
      final Reference ref = _storage
          .ref()
          .child('walkers')
          .child(uid)
          .child(folder)
          .child(fileName);

      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      return await ref.getDownloadURL();
    }

    throw Exception(
      'Required image is missing.',
    );
  }

  // ============================================================
  // VALIDATE
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
    // FRONT
    // ----------------------------------------------------------

    if (aadhaarFrontFile == null &&
        (aadhaarFrontUrl == null ||
            aadhaarFrontUrl!.trim().isEmpty)) {
      showMessage(
        'Please add Aadhaar Front.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // BACK
    // ----------------------------------------------------------

    if (aadhaarBackFile == null &&
        (aadhaarBackUrl == null ||
            aadhaarBackUrl!.trim().isEmpty)) {
      showMessage(
        'Please add Aadhaar Back.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // VILLAGE
    // ----------------------------------------------------------

    if (villageController.text.trim().isEmpty) {
      showMessage(
        'Please enter Village / Locality.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // CITY
    // ----------------------------------------------------------

    if (cityController.text.trim().isEmpty) {
      showMessage(
        'Please enter City / Town.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // DISTRICT
    // ----------------------------------------------------------

    if (districtController.text.trim().isEmpty) {
      showMessage(
        'Please enter District.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // STATE
    // ----------------------------------------------------------

    if (stateController.text.trim().isEmpty) {
      showMessage(
        'Please enter State.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // PIN
    // ----------------------------------------------------------

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
    // EMERGENCY CONTACT OPTIONAL
    // ----------------------------------------------------------

    final String emergencyName =
        emergencyNameController.text.trim();

    final String emergencyMobile =
        emergencyMobileController.text.trim();

    final bool hasEmergencyName =
        emergencyName.isNotEmpty;

    final bool hasEmergencyMobile =
        emergencyMobile.isNotEmpty;

    if (hasEmergencyName ||
        hasEmergencyMobile) {
      if (!hasEmergencyName) {
        showMessage(
          'Please enter emergency contact name or leave the entire contact empty.',
          false,
        );
        return false;
      }

      if (!hasEmergencyMobile) {
        showMessage(
          'Please enter emergency contact mobile or leave the entire contact empty.',
          false,
        );
        return false;
      }

      if (!RegExp(r'^\d{10}$').hasMatch(
        emergencyMobile,
      )) {
        showMessage(
          'Enter a valid 10-digit emergency mobile number.',
          false,
        );
        return false;
      }
    }

    // ----------------------------------------------------------
    // NAME
    // ----------------------------------------------------------

    if (widget.name.trim().isEmpty) {
      showMessage(
        'Name is missing. Please go back and enter your name.',
        false,
      );
      return false;
    }

    // ----------------------------------------------------------
    // SELFIE
    // ----------------------------------------------------------

    final String selfie =
        widget.selfieUrl?.trim() ?? '';

    if (widget.selfieFile == null &&
        selfie.isEmpty) {
      showMessage(
        'Profile selfie is missing. Please go back and add your selfie.',
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

    final User? user = currentUser;

    if (user == null) {
      showMessage(
        'Session expired. Please login again.',
        false,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      // ========================================================
      // UID
      // ========================================================

      final String uid = user.uid;

      // ========================================================
      // WALKER ID
      // ========================================================

      final String walkerId =
          createWalkerId(uid);

      // ========================================================
      // SELFIE
      // ========================================================

      final String selfieUrl =
          await _resolveImage(
        uid: uid,
        folder: 'profile',
        fileName: 'selfie.jpg',
        file: widget.selfieFile,
        url: widget.selfieUrl,
      );

      // ========================================================
      // AADHAAR FRONT
      // ========================================================

      final String aadhaarFront =
          await _resolveImage(
        uid: uid,
        folder: 'aadhaar',
        fileName: 'front.jpg',
        file: aadhaarFrontFile,
        url: aadhaarFrontUrl,
      );

      // ========================================================
      // AADHAAR BACK
      // ========================================================

      final String aadhaarBack =
          await _resolveImage(
        uid: uid,
        folder: 'aadhaar',
        fileName: 'back.jpg',
        file: aadhaarBackFile,
        url: aadhaarBackUrl,
      );

      // ========================================================
      // BASIC VALUES
      // ========================================================

      final String fullName =
          widget.name.trim();

      final String phoneNumber =
          user.phoneNumber ?? '';

      final String dateOfBirth =
          formattedDateOfBirth;

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
      //
      // IMPORTANT:
      //
      // नीचे पुराने/lowercase fields भी रखे गए हैं और
      // तुम्हारे Admin panel वाले exact field names भी।
      //
      // इससे existing app/admin code टूटेगा नहीं।
      // ========================================================

      final Map<String, dynamic> data = {
        // ======================================================
        // AUTH / IDENTITY
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

        'dateofbirth': dateOfBirth,

        'Date Of Birth': dateOfBirth,

        'dateOfBirth': dateOfBirth,

        'gender': gender,

        'Gender': gender,

        // ======================================================
        // SELFIE
        // ======================================================

        'selfie': selfieUrl,

        'Profile Selfie': selfieUrl,

        'profileSelfie': selfieUrl,

        'profileImage': selfieUrl,

        'profileImageUrl': selfieUrl,

        'selfieUrl': selfieUrl,

        // ======================================================
        // AADHAAR NUMBER
        // ======================================================

        'aadhaarNumber': aadhaarNumber,

        'Aadhar Number': aadhaarNumber,

        'Aadhaar Number': aadhaarNumber,

        // ======================================================
        // AADHAAR DOCUMENTS
        // ======================================================

        'aadhaarfront': aadhaarFront,

        'aadhaarFront': aadhaarFront,

        'aadhaar_front': aadhaarFront,

        'Aadhaar Front': aadhaarFront,

        'aadhaarback': aadhaarBack,

        'aadhaarBack': aadhaarBack,

        'aadhaar_back': aadhaarBack,

        'Aadhaar Back': aadhaarBack,

        // ======================================================
        // AADHAAR UPLOAD FLAGS
        // ======================================================

        'aadhaar_front_uploaded': true,

        'aadhaar_back_uploaded': true,

        'aadhaarFrontUploaded': true,

        'aadhaarBackUploaded': true,

        // ======================================================
        // AADHAAR VERIFICATION
        // ======================================================

        'aadhaarVerified': false,

        'aadhaar_verified': false,

        'nameMatched': false,

        'dobMatched': false,

        // ======================================================
        // ADDRESS
        // ======================================================

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

        'address': address,

        'Adress': address,

        'Address': address,

        // ======================================================
        // OPTIONAL EMERGENCY CONTACT
        // ======================================================

        'emergencyContactName':
            emergencyName,

        'emergencyContactMobile':
            emergencyMobile,

        // ======================================================
        // PROFILE STATE
        // ======================================================
        //
        // VERY IMPORTANT:
        //
        // profileCompleted = true
        // मतलब mandatory profile पूरा.
        //
        // verificationStatus = pending
        // मतलब Admin approval बाकी.
        //
        // इसलिए app को दोबारा Step 1/Step 2 पर नहीं जाना चाहिए.
        // ======================================================

        'profileCompleted': true,

        'profile_completed': true,

        'isProfileCompleted': true,

        'verificationStatus': 'pending',

        'verification_status': 'pending',

        'status': 'pending',

        // ======================================================
        // ADMIN STATE
        // ======================================================

        'adminApproved': false,

        'adminRejected': false,

        'adminApprovedAt': null,

        'adminRejectedAt': null,

        'adminReviewedAt': null,

        // ======================================================
        // WALKER ACTIVE STATE
        // ======================================================

        'isActive': false,

        'isVerified': false,

        'isAvailable': false,

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
      // SAVE WALKER DOCUMENT
      // ========================================================

      await _firestore
          .collection('walkers')
          .doc(uid)
          .set(
            data,
            SetOptions(merge: true),
          );

      // ========================================================
      // ALSO UPDATE USERS DOCUMENT
      // ========================================================
      //
      // अगर users/{uid} पहले से मौजूद है तो profile state
      // वहाँ भी sync हो जाएगी.
      //
      // अगर rules users collection में write allow नहीं करते,
      // तो यह failure पूरे submit को रोक सकता है.
      //
      // इसलिए इसे अलग try/catch में रखा गया है.
      // Main walkers document पहले ही save हो चुका होगा.
      // ========================================================

      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .set(
          {
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
        // users collection optional sync.
        // Main walkers profile is already saved.
      }

      // ========================================================
      // SAVE SUCCESS
      // ========================================================

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      showMessage(
        'Profile submitted successfully.',
        true,
      );

      // ========================================================
      // SMALL DELAY
      // ========================================================

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      // ========================================================
      // PENDING VERIFICATION SCREEN
      // ========================================================

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) =>
              const PendingVerificationScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      showMessage(
        _firebaseError(e),
        false,
      );
    } catch (e) {
      if (!mounted) return;

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

  String _firebaseError(
    FirebaseException e,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firebase permission denied. Check Firestore/Storage rules.';

      case 'unauthenticated':
        return 'Login session expired. Please login again.';

      case 'network-request-failed':
        return 'Network error. Check internet connection.';

      case 'object-not-found':
        return 'Image could not be uploaded.';

      case 'unauthorized':
        return 'Firebase Storage permission denied.';

      case 'quota-exceeded':
        return 'Firebase Storage quota exceeded.';

      case 'canceled':
        return 'Upload cancelled.';

      case 'retry-limit-exceeded':
        return 'Upload failed after several attempts.';

      case 'unknown':
        return e.message ??
            'Unknown Firebase error occurred.';

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
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        obscureText: obscureText,
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
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFE3E8ED),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
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
  // DOCUMENT CARD
  // ============================================================

  Widget documentCard({
    required String title,
    required String subtitle,
    required bool isFront,
  }) {
    final File? file = isFront
        ? aadhaarFrontFile
        : aadhaarBackFile;

    final String? url = isFront
        ? aadhaarFrontUrl
        : aadhaarBackUrl;

    final bool added =
        file != null ||
        (url != null && url.trim().isNotEmpty);

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
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
                color:
                    blue.withOpacity(.08),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const Icon(
                            Icons
                                .image_not_supported_rounded,
                            color: blue,
                            size: 29,
                          );
                        },
                      ),
                    )
                  : url != null &&
                          url.trim().isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                          child:
                              Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return const Icon(
                                Icons.badge_rounded,
                                color: blue,
                                size: 29,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.badge_rounded,
                          color: blue,
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
                      color: textDark,
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
                          ? green
                          : muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              added
                  ? Icons
                      .check_circle_rounded
                  : Icons
                      .chevron_right_rounded,
              color: added
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
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
                Icons.person_rounded,
                color: green,
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
          _summaryRow(
            'Walker Role',
            'Walker',
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
              style: const TextStyle(
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
  // SECTION CONTAINER
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
          color: const Color(0xFFE3E8ED),
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
        backgroundColor: background,
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
                      color: Color(0xFFE8EDF1),
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
                        color: orange,
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
                    const SizedBox(width: 12),
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
                                  orange,
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
                        color:
                            green.withOpacity(
                          .10,
                        ),
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
                          color: green,
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
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aadhaar & Address',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight:
                              FontWeight.w900,
                          color: textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'Complete your Aadhaar and address details.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: muted,
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
                                  color: blue,
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
                                  'Camera or image URL',
                              isFront: true,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            documentCard(
                              title:
                                  'Aadhaar Back',
                              subtitle:
                                  'Camera or image URL',
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
                                  color: blue,
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
                                    background,
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
                                        green,
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
                      // EMERGENCY CONTACT
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
                                  color: orange,
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
                                          textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  'OPTIONAL',
                                  style:
                                      TextStyle(
                                    color:
                                        muted,
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
                              'यह जानकारी देना आपकी इच्छा है। खाली छोड़कर भी आगे बढ़ सकते हैं।',
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
                              const Color(
                            0xFFF0F6FF,
                          ),
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
                              color: blue,
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
                      // SUBMIT BUTTON
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
                                green
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
                            color: muted,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 5,
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
