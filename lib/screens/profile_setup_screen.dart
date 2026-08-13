// File location: lib/screens/profile_setup_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import 'main_navigation_screen.dart';

class MandatoryProfileSetupScreen extends StatefulWidget {
  const MandatoryProfileSetupScreen({super.key});

  @override
  State<MandatoryProfileSetupScreen> createState() =>
      _MandatoryProfileSetupScreenState();
}

class _MandatoryProfileSetupScreenState
    extends State<MandatoryProfileSetupScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _aadhaarController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _pinCodeController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _dateOfBirth;
  File? _selfieFile;

  bool _isSaving = false;

  // =====================================================
  // TAKE SELFIE
  // =====================================================

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        _selfieFile = File(image.path);
      });
    } catch (e) {
      debugPrint('Selfie camera error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open camera: $e'),
        ),
      );
    }
  }

  // =====================================================
  // DATE OF BIRTH
  // =====================================================

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();

    final DateTime initialDate = DateTime(
      now.year - 18,
      now.month,
      now.day,
    );

    final DateTime firstDate = DateTime(
      1900,
      1,
      1,
    );

    final DateTime lastDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    setState(() {
      _dateOfBirth = selectedDate;
    });
  }

  // =====================================================
  // FORMAT DATE
  // =====================================================

  String _formatDate(DateTime date) {
    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateForFirebase(DateTime date) {
    final String month =
        date.month.toString().padLeft(2, '0');

    final String day =
        date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // =====================================================
  // SAVE WALKER PROFILE
  // =====================================================

  Future<void> _saveProfile() async {
    final String name =
        _nameController.text.trim();

    final String aadhaar =
        _aadhaarController.text.trim();

    final String address =
        _addressController.text.trim();

    final String pinCode =
        _pinCodeController.text.trim();

    // =====================================================
    // VALIDATION
    // =====================================================

    if (_selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take your selfie.'),
        ),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name.'),
        ),
      );
      return;
    }

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your date of birth.',
          ),
        ),
      );
      return;
    }

    if (aadhaar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid 12-digit Aadhaar number.',
          ),
        ),
      );
      return;
    }

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your address.'),
        ),
      );
      return;
    }

    if (pinCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid 6-digit PIN Code.',
          ),
        ),
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login session not found. Please login again.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // =================================================
      // FIREBASE AUTH DATA
      // =================================================

      final String walkerUid = user.uid;

      final String phoneNumber =
          user.phoneNumber ?? '';

      // =================================================
      // FIREBASE STORAGE
      // =================================================

      final Reference photoReference =
          FirebaseStorage.instance
              .ref()
              .child('walker_profiles')
              .child(walkerUid)
              .child('selfie.jpg');

      await photoReference.putFile(
        _selfieFile!,
      );

      final String photoUrl =
          await photoReference.getDownloadURL();

      // =================================================
      // FIRESTORE
      // =================================================

      await FirebaseFirestore.instance
          .collection('walkers')
          .doc(walkerUid)
          .set(
        {
          'uid': walkerUid,
          'role': 'walker',
          'name': name,
          'dateOfBirth':
              _formatDateForFirebase(
            _dateOfBirth!,
          ),
          'aadhaarNumber': aadhaar,
          'address': address,
          'pinCode': pinCode,
          'phone': phoneNumber,
          'photoUrl': photoUrl,
          'profileCompleted': true,
          'updatedAt':
              FieldValue.serverTimestamp(),
          'createdAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile saved successfully!',
          ),
        ),
      );

      // =================================================
      // GO TO DASHBOARD
      // =================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'Walker profile save error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile save failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =====================================================
  // INPUT DECORATION
  // =====================================================

  InputDecoration _inputDecoration(
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFD5D9DE),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // =====================================================
  // LABEL
  // =====================================================

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textGrey,
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _nameController.dispose();
    _aadhaarController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    final String walkerUid =
        user?.uid ?? '';

    final String phoneNumber =
        user?.phoneNumber ?? 'Not available';

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        automaticallyImplyLeading: false,
        title: const Text(
          'Complete Walker Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // SELFIE
            // =================================================

            Center(
              child: GestureDetector(
                onTap: _isSaving
                    ? null
                    : _takeSelfie,
                child: Stack(
                  alignment:
                      Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration:
                          BoxDecoration(
                        shape:
                            BoxShape.circle,
                        color: AppColors
                            .primary
                            .withOpacity(0.10),
                        border:
                            Border.all(
                          color:
                              AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            _selfieFile == null
                                ? const Icon(
                                    Icons.person,
                                    size: 65,
                                    color:
                                        AppColors.primary,
                                  )
                                : Image.file(
                                    _selfieFile!,
                                    width: 120,
                                    height: 120,
                                    fit:
                                        BoxFit.cover,
                                  ),
                      ),
                    ),

                    Container(
                      width: 38,
                      height: 38,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.primary,
                        shape:
                            BoxShape.circle,
                        border:
                            Border.all(
                          color:
                              Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color:
                            Colors.white,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Take Selfie',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // NAME
            // =================================================

            _label('Full Name'),

            const SizedBox(height: 6),

            TextField(
              controller:
                  _nameController,
              textCapitalization:
                  TextCapitalization.words,
              decoration:
                  _inputDecoration(
                'Enter full name',
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // DATE OF BIRTH
            // =================================================

            _label('Date of Birth'),

            const SizedBox(height: 6),

            InkWell(
              onTap: _isSaving
                  ? null
                  : _selectDateOfBirth,
              borderRadius:
                  BorderRadius.circular(10),
              child: InputDecorator(
                decoration:
                    _inputDecoration(
                  'Select date of birth',
                ).copyWith(
                  suffixIcon:
                      const Icon(
                    Icons.calendar_month,
                  ),
                ),
                child: Text(
                  _dateOfBirth == null
                      ? 'Select date of birth'
                      : _formatDate(
                          _dateOfBirth!,
                        ),
                  style: TextStyle(
                    color: _dateOfBirth ==
                            null
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // AADHAAR
            // =================================================

            _label('Aadhaar Number'),

            const SizedBox(height: 6),

            TextField(
              controller:
                  _aadhaarController,
              keyboardType:
                  TextInputType.number,
              maxLength: 12,
              decoration:
                  _inputDecoration(
                'Enter 12-digit Aadhaar number',
              ).copyWith(
                counterText: '',
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // ADDRESS
            // =================================================

            _label('Address'),

            const SizedBox(height: 6),

            TextField(
              controller:
                  _addressController,
              maxLines: 3,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration:
                  _inputDecoration(
                'Enter complete address',
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // PIN CODE
            // =================================================

            _label('PIN Code'),

            const SizedBox(height: 6),

            TextField(
              controller:
                  _pinCodeController,
              keyboardType:
                  TextInputType.number,
              maxLength: 6,
              decoration:
                  _inputDecoration(
                'Enter 6-digit PIN code',
              ).copyWith(
                counterText: '',
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // MOBILE NUMBER
            // =================================================

            _label(
              'Linked Mobile Number',
            ),

            const SizedBox(height: 6),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF1F3F5,
                ),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFD5D9DE,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone,
                    color:
                        AppColors.primary,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      phoneNumber,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.black87,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.lock,
                    size: 18,
                    color:
                        Colors.grey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // WALKER UID
            // =================================================

            _label('Walker UID'),

            const SizedBox(height: 6),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(15),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF1F3F5,
                ),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFD5D9DE,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Icon(
                    Icons.verified_user,
                    color:
                        AppColors.primary,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      walkerUid.isEmpty
                          ? 'UID not available'
                          : walkerUid,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Colors.black87,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.lock,
                    size: 18,
                    color:
                        Colors.grey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // SAVE BUTTON
            // =================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  disabledBackgroundColor:
                      Colors.grey,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                onPressed:
                    _isSaving
                        ? null
                        : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 25,
                        height: 25,
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.white,
                          strokeWidth:
                              2.5,
                        ),
                      )
                    : const Text(
                        'Save Profile & Continue',
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                'Your profile information will be securely linked to your Walker UID.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
