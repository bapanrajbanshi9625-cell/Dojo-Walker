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
  // OPEN DOCUMENT UPLOAD
  // ==========================================================

  void _openDocumentUpload(
    BuildContext context, {
    required String documentName,
    required bool isFront,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ProfileDocumentUploadSheet(
          documentName: documentName,

          // ---------------------------------------------------
          // GALLERY
          // ---------------------------------------------------

          onGallery: () async {
            Navigator.pop(sheetContext);

            await _pickDocument(
              context,
              source: ImageSource.gallery,
              isFront: isFront,
            );
          },

          // ---------------------------------------------------
          // CAMERA
          // ---------------------------------------------------

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
  // PICK DOCUMENT
  // ==========================================================

  Future<void> _pickDocument(
    BuildContext context, {
    required ImageSource source,
    required bool isFront,
  }) async {
    try {
      final ImagePicker picker =
          ImagePicker();

      final XFile? picked =
          await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (picked == null) {
        return;
      }

      if (!context.mounted) {
        return;
      }

      // ------------------------------------------------------
      // UPLOAD TO FIREBASE
      // ------------------------------------------------------

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        },
      );

      await ProfileFirebaseService.uploadAadhaar(
        file: File(picked.path),
        isFront: isFront,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
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

      Navigator.of(context).popUntil(
        (route) {
          return route.isFirst ||
              ModalRoute.of(context)
                      ?.isCurrent ==
                  true;
        },
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // MOBILE NUMBER EDIT FLOW
  // ==========================================================

  void _openMobileNumberChange(
    BuildContext context,
    String currentPhone,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return CurrentPhoneBottomSheet(
          currentPhone: currentPhone,

          // ---------------------------------------------------
          // SEND CURRENT NUMBER OTP
          // ---------------------------------------------------

          onSendOtp: () async {
            Navigator.pop(sheetContext);

            await Future.delayed(
              const Duration(
                milliseconds: 150,
              ),
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
  // SEND CURRENT OTP
  // ==========================================================

  Future<void> _sendCurrentOtp(
    BuildContext context,
    String currentPhone,
  ) async {
    try {
      String? verificationId;

      await ProfileFirebaseService
          .sendCurrentPhoneOtp(
        onCodeSent:
            (String id) {
          verificationId = id;
        },
        onVerificationFailed:
            (FirebaseAuthException error) {
          throw error;
        },
      );

      if (!context.mounted) {
        return;
      }

      if (verificationId == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'OTP failed: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // CURRENT OTP SHEET
  // ==========================================================

  void _openCurrentOtpSheet(
    BuildContext context,
    String verificationId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return OtpBottomSheet(
          title:
              'Verify Current Number',
          subtitle:
              'Enter the OTP sent to your current mobile number.',
          buttonText:
              'Verify OTP',

          onVerify:
              (String otp) async {
            try {
              await ProfileFirebaseService
                  .verifyCurrentPhoneOtp(
                verificationId:
                    verificationId,
                smsCode: otp,
              );

              if (!sheetContext
                  .mounted) {
                return;
              }

              Navigator.pop(
                sheetContext,
              );

              await Future.delayed(
                const Duration(
                  milliseconds: 150,
                ),
              );

              if (!context.mounted) {
                return;
              }

              _openNewPhoneSheet(
                context,
              );
            } catch (e) {
              if (!sheetContext
                  .mounted) {
                return;
              }

              ScaffoldMessenger.of(
                sheetContext,
              ).showSnackBar(
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return NewPhoneBottomSheet(
          onContinue:
              (String newPhone) async {
            Navigator.pop(
              sheetContext,
            );

            await Future.delayed(
              const Duration(
                milliseconds: 150,
              ),
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
  // SEND NEW PHONE OTP
  // ==========================================================

  Future<void> _sendNewPhoneOtp(
    BuildContext context,
    String newPhone,
  ) async {
    try {
      String? verificationId;

      await ProfileFirebaseService
          .sendNewPhoneOtp(
        newPhoneNumber: newPhone,
        onCodeSent:
            (String id) {
          verificationId = id;
        },
        onVerificationFailed:
            (FirebaseAuthException error) {
          throw error;
        },
      );

      if (!context.mounted) {
        return;
      }

      if (verificationId == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send OTP: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // NEW PHONE OTP SHEET
  // ==========================================================

  void _openNewPhoneOtpSheet(
    BuildContext context,
    String verificationId,
    String newPhone,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return OtpBottomSheet(
          title:
              'Verify New Number',
          subtitle:
              'Enter the OTP sent to your new mobile number.',
          buttonText:
              'Save and Continue',

          onVerify:
              (String otp) async {
            try {
              await ProfileFirebaseService
                  .verifyAndUpdateNewPhone(
                verificationId:
                    verificationId,
                smsCode: otp,
                newPhoneNumber:
                    newPhone,
              );

              if (!sheetContext
                  .mounted) {
                return;
              }

              Navigator.pop(
                sheetContext,
              );

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Mobile number updated successfully.',
                  ),
                ),
              );
            } catch (e) {
              if (!sheetContext
                  .mounted) {
                return;
              }

              ScaffoldMessenger.of(
                sheetContext,
              ).showSnackBar(
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
  Widget build(
    BuildContext context,
  ) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor:
            AppColors.scaffoldBackground,
        body: Center(
          child: Text(
            'Login session not found.',
            style: TextStyle(
              color:
                  AppColors.textDark,
            ),
          ),
        ),
      );
    }

    final String walkerUid =
        user.uid;

    return Scaffold(
      backgroundColor:
          AppColors.scaffoldBackground,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // FIRESTORE PROFILE
      // ========================================================

      body: StreamBuilder<
          DocumentSnapshot<
              Map<String, dynamic>>>(
        stream: FirebaseFirestore
            .instance
            .collection('walkers')
            .doc(walkerUid)
            .snapshots(),

        builder:
            (context, snapshot) {
          if (snapshot
                  .connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load profile.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      AppColors.textGrey,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profile information not found.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      AppColors.textGrey,
                ),
              ),
            );
          }

          final Map<String, dynamic>
              data =
              snapshot.data!.data() ??
                  <String, dynamic>{};

          final String name =
              (data['name'] ??
                      'Not available')
                  .toString();

          final String phone =
              (data['phone'] ??
                      user.phoneNumber ??
                      'Not available')
                  .toString();

          final String uid =
              (data['uid'] ??
                      walkerUid)
                  .toString();

          final String dateOfBirth =
              (data['dateOfBirth'] ??
                      'Not available')
                  .toString();

          final String address =
              (data['address'] ??
                      'Not available')
                  .toString();

          final String pinCode =
              (data['pinCode'] ??
                      'Not available')
                  .toString();

          // ----------------------------------------------------
          // AADHAAR
          // ----------------------------------------------------

          final bool aadhaarFrontUploaded =
              data['aadhaar_front_uploaded'] ==
                  true;

          final bool aadhaarBackUploaded =
              data['aadhaar_back_uploaded'] ==
                  true;

          // ====================================================
          // PROFILE UI
          // ====================================================

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // SELFIE / PROFILE IMAGE
                // POSITION AND SIZE KEPT SAME
                // =================================================

                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors.primary,
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons.person,
                      size: 55,
                      color:
                          Colors.white,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // =================================================
                // NAME
                // =================================================

                Center(
                  child: Text(
                    name,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors.textDark,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // =================================================
                // PROFILE INFORMATION
                // =================================================

                const Text(
                  'Profile Information',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                ProfileInfoCard(
                  icon:
                      Icons.person_outline,
                  iconColor:
                      AppColors.primary,
                  label:
                      'Full Name',
                  value:
                      name,
                ),

                // =================================================
                // MOBILE NUMBER + EDIT
                // =================================================

                MobileNumberCard(
                  phone: phone,
                  onEdit: () {
                    _openMobileNumberChange(
                      context,
                      phone,
                    );
                  },
                ),

                ProfileInfoCard(
                  icon:
                      Icons.cake_outlined,
                  iconColor:
                      const Color(
                    0xFFE11D48,
                  ),
                  label:
                      'Date of Birth',
                  value:
                      dateOfBirth,
                ),

                ProfileInfoCard(
                  icon:
                      Icons.location_on_outlined,
                  iconColor:
                      const Color(
                    0xFF2563EB,
                  ),
                  label:
                      'Address',
                  value:
                      address,
                ),

                ProfileInfoCard(
                  icon:
                      Icons.pin_drop_outlined,
                  iconColor:
                      const Color(
                    0xFF0891B2,
                  ),
                  label:
                      'PIN Code',
                  value:
                      pinCode,
                ),

                const SizedBox(
                  height: 10,
                ),

                // =================================================
                // DOCUMENT INFORMATION
                // =================================================

                const Text(
                  'Document Information',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // =================================================
                // AADHAAR NUMBER
                // =================================================

                ProfileInfoCard(
                  icon:
                      Icons.badge_outlined,
                  iconColor:
                      const Color(
                    0xFF7C3AED,
                  ),
                  label:
                      'Aadhaar Number',
                  value:
                      (data['aadhaarNumber'] ??
                              data['aadharNumber'] ??
                              'Not available')
                          .toString(),
                ),

                // =================================================
                // AADHAAR FRONT
                // =================================================

                ProfileDocumentCard(
                  label:
                      'Aadhaar Front',
                  uploaded:
                      aadhaarFrontUploaded,
                  onUpload: () {
                    _openDocumentUpload(
                      context,
                      documentName:
                          'Aadhaar Front',
                      isFront: true,
                    );
                  },
                ),

                // =================================================
                // AADHAAR BACK
                // =================================================

                ProfileDocumentCard(
                  label:
                      'Aadhaar Back',
                  uploaded:
                      aadhaarBackUploaded,
                  onUpload: () {
                    _openDocumentUpload(
                      context,
                      documentName:
                          'Aadhaar Back',
                      isFront: false,
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                // =================================================
                // ACCOUNT INFORMATION
                // =================================================

                const Text(
                  'Account Information',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                ProfileInfoCard(
                  icon:
                      Icons.verified_user_outlined,
                  iconColor:
                      const Color(
                    0xFF16A34A,
                  ),
                  label:
                      'Walker UID',
                  value:
                      uid,
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // FOOTER
                // =================================================

                const Center(
                  child: Text(
                    'Your profile is securely linked to your Walker UID.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      fontSize: 11,
                      color:
                          AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
