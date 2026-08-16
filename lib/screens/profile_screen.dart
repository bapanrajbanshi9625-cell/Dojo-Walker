import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../features/profile/services/profile_firebase_service.dart';
import '../features/profile/widgets/mobile_number_card.dart';
import '../features/profile/widgets/profile_bottom_sheets.dart';
import '../features/profile/widgets/profile_document_card.dart';
import '../features/profile/widgets/profile_info_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ==========================================================
  // DOJO WALKER ORANGE
  // ==========================================================

  static const Color walkerOrange = Color(0xFFFF4B16);

  // ==========================================================
  // OPEN DOCUMENT UPLOAD
  // ==========================================================

  void _openDocumentUpload(
    BuildContext context, {
    required String documentName,
    required bool isFront,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ProfileDocumentUploadSheet(
          documentName: documentName,
          onGallery: () async {
            Navigator.pop(sheetContext);

            await _pickDocument(
              context,
              source: ImageSource.gallery,
              isFront: isFront,
            );
          },
          onCamera: () async {
            Navigator.pop(sheetContext);

            await _pickDocument(
              context,
              source: ImageSource.camera,
              isFront: isFront,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // PICK AADHAAR DOCUMENT
  // ==========================================================

  Future<void> _pickDocument(
    BuildContext context, {
    required ImageSource source,
    required bool isFront,
  }) async {
    bool loadingShown = false;

    try {
      final ImagePicker picker = ImagePicker();

      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (picked == null || !context.mounted) {
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: CircularProgressIndicator(
              color: walkerOrange,
            ),
          );
        },
      );

      loadingShown = true;

      await ProfileFirebaseService.uploadAadhaar(
        file: File(picked.path),
        isFront: isFront,
      );

      if (!context.mounted) {
        return;
      }

      if (loadingShown) {
        Navigator.pop(context);
        loadingShown = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: walkerOrange,
          content: Text(
            isFront
                ? 'Aadhaar Front uploaded successfully.'
                : 'Aadhaar Back uploaded successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      if (loadingShown) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // MOBILE NUMBER CHANGE
  // ==========================================================

  void _openMobileNumberChange(
    BuildContext context,
    String currentPhone,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return CurrentPhoneBottomSheet(
          currentPhone: currentPhone,
          onSendOtp: () async {
            Navigator.pop(sheetContext);

            await Future.delayed(
              const Duration(milliseconds: 150),
            );

            if (!context.mounted) {
              return;
            }

            _sendCurrentOtp(
              context,
              currentPhone,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // SEND CURRENT NUMBER OTP
  // ==========================================================

  Future<void> _sendCurrentOtp(
    BuildContext context,
    String currentPhone,
  ) async {
    try {
      String? verificationId;

      await ProfileFirebaseService.sendCurrentPhoneOtp(
        onCodeSent: (String id) {
          verificationId = id;
        },
        onVerificationFailed: (
          FirebaseAuthException error,
        ) {
          throw error;
        },
      );

      if (!context.mounted) {
        return;
      }

      if (verificationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to send OTP.',
            ),
          ),
        );
        return;
      }

      _openCurrentOtpSheet(
        context,
        verificationId!,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP failed: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // CURRENT OTP
  // ==========================================================

  void _openCurrentOtpSheet(
    BuildContext context,
    String verificationId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return OtpBottomSheet(
          title: 'Verify Current Number',
          subtitle:
              'Enter the OTP sent to your current mobile number.',
          buttonText: 'Verify OTP',
          onVerify: (String otp) async {
            try {
              await ProfileFirebaseService.verifyCurrentPhoneOtp(
                verificationId: verificationId,
                smsCode: otp,
              );

              if (!sheetContext.mounted) {
                return;
              }

              Navigator.pop(sheetContext);

              await Future.delayed(
                const Duration(milliseconds: 150),
              );

              if (!context.mounted) {
                return;
              }

              _openNewPhoneSheet(context);
            } catch (e) {
              if (!sheetContext.mounted) {
                return;
              }

              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'OTP verification failed: $e',
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  // ==========================================================
  // NEW PHONE SHEET
  // ==========================================================

  void _openNewPhoneSheet(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return NewPhoneBottomSheet(
          onContinue: (String newPhone) async {
            Navigator.pop(sheetContext);

            await Future.delayed(
              const Duration(milliseconds: 150),
            );

            if (!context.mounted) {
              return;
            }

            _sendNewPhoneOtp(
              context,
              newPhone,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // SEND NEW NUMBER OTP
  // ==========================================================

  Future<void> _sendNewPhoneOtp(
    BuildContext context,
    String newPhone,
  ) async {
    try {
      String? verificationId;

      await ProfileFirebaseService.sendNewPhoneOtp(
        newPhoneNumber: newPhone,
        onCodeSent: (String id) {
          verificationId = id;
        },
        onVerificationFailed: (
          FirebaseAuthException error,
        ) {
          throw error;
        },
      );

      if (!context.mounted) {
        return;
      }

      if (verificationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to send OTP.',
            ),
          ),
        );
        return;
      }

      _openNewPhoneOtpSheet(
        context,
        verificationId!,
        newPhone,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send OTP: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // NEW PHONE OTP
  // ==========================================================

  void _openNewPhoneOtpSheet(
    BuildContext context,
    String verificationId,
    String newPhone,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return OtpBottomSheet(
          title: 'Verify New Number',
          subtitle:
              'Enter the OTP sent to your new mobile number.',
          buttonText: 'Save and Continue',
          onVerify: (String otp) async {
            try {
              await ProfileFirebaseService.verifyAndUpdateNewPhone(
                verificationId: verificationId,
                smsCode: otp,
                newPhoneNumber: newPhone,
              );

              if (!sheetContext.mounted) {
                return;
              }

              Navigator.pop(sheetContext);

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: walkerOrange,
                  content: Text(
                    'Mobile number updated successfully.',
                  ),
                ),
              );
            } catch (e) {
              if (!sheetContext.mounted) {
                return;
              }

              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'Unable to update mobile number: $e',
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // ========================================================
    // LOGIN CHECK
    // ========================================================

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Center(
          child: Text(
            'Login session not found.',
            style: TextStyle(
              color: AppColors.textDark,
            ),
          ),
        ),
      );
    }

    final String walkerUid = user.uid;

    // ========================================================
    // PROFILE SCREEN
    // ========================================================

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,

      appBar: AppBar(
        backgroundColor: walkerOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ======================================================
      // FIRESTORE
      // walkers/{currentUser.uid}
      // ======================================================

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('walkers')
            .doc(walkerUid)
            .snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          // ==================================================
          // LOADING
          // ==================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: walkerOrange,
              ),
            );
          }

          // ==================================================
          // ERROR
          // ==================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load profile.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            );
          }

          // ==================================================
          // DOCUMENT NOT FOUND
          // ==================================================

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profile information not found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGrey,
                ),
              ),
            );
          }

          // ==================================================
          // FIRESTORE DATA
          // ==================================================

          final Map<String, dynamic> data =
              snapshot.data!.data() ??
                  <String, dynamic>{};

          // ==================================================
          // EXACT FIRESTORE FIELD NAMES
          // ==================================================

          final String name =
              (data['Full Name'] ?? '')
                  .toString()
                  .trim();

          final String phone =
              (data['Mobile number'] ??
                      user.phoneNumber ??
                      '')
                  .toString()
                  .trim();

          final String dateOfBirth =
              (data['Date Of Birth'] ?? '')
                  .toString()
                  .trim();

          // EXACT: "Adress"
          final String address =
              (data['Adress'] ?? '')
                  .toString()
                  .trim();

          // EXACT: "Pincode"
          final String pinCode =
              (data['Pincode'] ?? '')
                  .toString()
                  .trim();

          // EXACT: "Aadhar Number"
          final String aadhaarNumber =
              (data['Aadhar Number'] ?? '')
                  .toString()
                  .trim();

          // EXACT: "Walker Uid"
          final String uid =
              (data['Walker Uid'] ?? walkerUid)
                  .toString()
                  .trim();

          // EXACT: "Profile Selfie"
          final String profileSelfie =
              (data['Profile Selfie'] ?? '')
                  .toString()
                  .trim();

          final bool aadhaarFrontUploaded =
              data['aadhaar_front_uploaded'] == true;

          final bool aadhaarBackUploaded =
              data['aadhaar_back_uploaded'] == true;

          // ==================================================
          // MAIN UI
          // ==================================================

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // PROFILE SELFIE
                // =================================================

                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: walkerOrange,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: profileSelfie.isNotEmpty
                        ? Image.network(
                            profileSelfie,
                            fit: BoxFit.cover,
                            loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                            ) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Icon(
                                Icons.person,
                                size: 55,
                                color: Colors.white,
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.white,
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // =================================================
                // NAME
                // =================================================

                Center(
                  child: Text(
                    name.isEmpty
                        ? 'Not available'
                        : name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // =================================================
                // PROFILE INFORMATION
                // =================================================

                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // FULL NAME
                // =================================================

                ProfileInfoCard(
                  icon: Icons.person_outline,
                  iconColor: walkerOrange,
                  label: 'Full Name',
                  value: name.isEmpty
                      ? 'Not available'
                      : name,
                ),

                // =================================================
                // MOBILE
                // =================================================

                MobileNumberCard(
                  phone: phone.isEmpty
                      ? 'Not available'
                      : phone,
                  onEdit: () {
                    _openMobileNumberChange(
                      context,
                      phone,
                    );
                  },
                ),

                // =================================================
                // DATE OF BIRTH
                // =================================================

                ProfileInfoCard(
                  icon: Icons.cake_outlined,
                  iconColor: const Color(0xFFE11D48),
                  label: 'Date of Birth',
                  value: dateOfBirth.isEmpty
                      ? 'Not available'
                      : dateOfBirth,
                ),

                // =================================================
                // ADDRESS
                // =================================================

                ProfileInfoCard(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFF2563EB),
                  label: 'Address',
                  value: address.isEmpty
                      ? 'Not available'
                      : address,
                ),

                // =================================================
                // PIN CODE
                // =================================================

                ProfileInfoCard(
                  icon: Icons.pin_drop_outlined,
                  iconColor: const Color(0xFF0891B2),
                  label: 'PIN Code',
                  value: pinCode.isEmpty
                      ? 'Not available'
                      : pinCode,
                ),

                const SizedBox(height: 10),

                // =================================================
                // DOCUMENT INFORMATION
                // =================================================

                const Text(
                  'Document Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // AADHAAR NUMBER
                // =================================================

                ProfileInfoCard(
                  icon: Icons.badge_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  label: 'Aadhaar Number',
                  value: aadhaarNumber.isEmpty
                      ? 'Not available'
                      : aadhaarNumber,
                ),

                // =================================================
                // AADHAAR FRONT
                // =================================================

                ProfileDocumentCard(
                  label: 'Aadhaar Front',
                  uploaded: aadhaarFrontUploaded,
                  onUpload: () {
                    _openDocumentUpload(
                      context,
                      documentName: 'Aadhaar Front',
                      isFront: true,
                    );
                  },
                ),

                // =================================================
                // AADHAAR BACK
                // =================================================

                ProfileDocumentCard(
                  label: 'Aadhaar Back',
                  uploaded: aadhaarBackUploaded,
                  onUpload: () {
                    _openDocumentUpload(
                      context,
                      documentName: 'Aadhaar Back',
                      isFront: false,
                    );
                  },
                ),

                const SizedBox(height: 10),

                // =================================================
                // ACCOUNT INFORMATION
                // =================================================

                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // WALKER UID
                // =================================================

                ProfileInfoCard(
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF16A34A),
                  label: 'Walker UID',
                  value: uid.isEmpty
                      ? walkerUid
                      : uid,
                ),

                const SizedBox(height: 20),

                // =================================================
                // FOOTER
                // =================================================

                const Center(
                  child: Text(
                    'Your profile is securely linked to your Walker UID.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
