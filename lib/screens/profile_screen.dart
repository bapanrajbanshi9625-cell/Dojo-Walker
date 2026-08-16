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

  static const Color walkerOrange =
      Color(0xFFFF4B16);

  // ==========================================================
  // DOCUMENT UPLOAD SHEET
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
  // PICK AADHAAR
  // ==========================================================

  Future<void> _pickDocument(
    BuildContext context, {
    required ImageSource source,
    required bool isFront,
  }) async {
    bool loadingShown = false;

    try {
      final ImagePicker picker =
          ImagePicker();

      final XFile? picked =
          await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (picked == null ||
          !context.mounted) {
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
  // CURRENT OTP
  // ==========================================================

  Future<void> _sendCurrentOtp(
    BuildContext context,
    String currentPhone,
  ) async {
    try {
      String? verificationId;

      await ProfileFirebaseService
          .sendCurrentPhoneOtp(
        onCodeSent: (String id) {
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
              await ProfileFirebaseService
                  .verifyCurrentPhoneOtp(
                verificationId:
                    verificationId,
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
  // NEW PHONE
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
  // NEW PHONE OTP
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
        onCodeSent: (String id) {
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
              await ProfileFirebaseService
                  .verifyAndUpdateNewPhone(
                verificationId:
                    verificationId,
                smsCode: otp,
                newPhoneNumber:
                    newPhone,
              );

              if (!sheetContext.mounted) {
                return;
              }

              Navigator.pop(sheetContext);

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context)
                  .showSnackBar(
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
  Widget build(BuildContext context) {
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
              color: AppColors.textDark,
            ),
          ),
        ),
      );
    }

    final String walkerUid = user.uid;

    return Scaffold(
      backgroundColor:
          AppColors.scaffoldBackground,

      // ======================================================
      // APP BAR
      // ======================================================

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
      // ======================================================

      body: StreamBuilder<
          DocumentSnapshot<
              Map<String, dynamic>>>(
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
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  'Unable to load profile.\n\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        AppColors.textGrey,
                  ),
                ),
              ),
            );
          }

          // ==================================================
          // NOT FOUND
          // ==================================================

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

          // ==================================================
          // DATA
          // ==================================================

          final Map<String, dynamic> data =
              snapshot.data!.data() ??
                  <String, dynamic>{};

          // ==================================================
          // EXACT FIRESTORE FIELDS
          // ==================================================

          final String name =
              _stringValue(
            data['Full Name'],
          );

          final String phone =
              _stringValue(
            data['Mobile number'],
          ).isNotEmpty
                  ? _stringValue(
                      data['Mobile number'],
                    )
                  : (user.phoneNumber ?? '');

          final String dob =
              _stringValue(
            data['Date Of Birth'],
          );

          final String address =
              _stringValue(
            data['Adress'],
          );

          final String pincode =
              _stringValue(
            data['Pincode'],
          );

          final String aadhaar =
              _stringValue(
            data['Aadhar Number'],
          );

          final String selfie =
              _stringValue(
            data['Profile Selfie'],
          );

          final String uid =
              _stringValue(
            data['Walker Uid'],
          ).isNotEmpty
                  ? _stringValue(
                      data['Walker Uid'],
                    )
                  : walkerUid;

          final bool frontUploaded =
              data[
                      'aadhaar_front_uploaded'] ==
                  true;

          final bool backUploaded =
              data[
                      'aadhaar_back_uploaded'] ==
                  true;

          // ==================================================
          // MAIN UI
          // ==================================================

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // PROFILE SELFIE
                // =================================================

                Center(
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration:
                        const BoxDecoration(
                      color: walkerOrange,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior:
                        Clip.antiAlias,
                    child: selfie.isNotEmpty
                        ? Image.network(
                            selfie,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Icon(
                                Icons.person,
                                size: 58,
                                color:
                                    Colors.white,
                              );
                            },
                            loadingBuilder: (
                              context,
                              child,
                              progress,
                            ) {
                              if (progress ==
                                  null) {
                                return child;
                              }

                              return const Center(
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 58,
                            color: Colors.white,
                          ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // =================================================
                // NAME
                // =================================================

                Center(
                  child: Text(
                    name.isEmpty
                        ? 'Not available'
                        : name,
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
                      walkerOrange,
                  label:
                      'Full Name',
                  value:
                      _display(name),
                ),

                MobileNumberCard(
                  phone:
                      _display(phone),
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
                      _display(dob),
                ),

                ProfileInfoCard(
                  icon: Icons
                      .location_on_outlined,
                  iconColor:
                      const Color(
                    0xFF2563EB,
                  ),
                  label:
                      'Address',
                  value:
                      _display(address),
                ),

                ProfileInfoCard(
                  icon: Icons
                      .pin_drop_outlined,
                  iconColor:
                      const Color(
                    0xFF0891B2,
                  ),
                  label:
                      'PIN Code',
                  value:
                      _display(pincode),
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
                      _display(aadhaar),
                ),

                ProfileDocumentCard(
                  label:
                      'Aadhaar Front',
                  uploaded:
                      frontUploaded,
                  onUpload: () {
                    _openDocumentUpload(
                      context,
                      documentName:
                          'Aadhaar Front',
                      isFront: true,
                    );
                  },
                ),

                ProfileDocumentCard(
                  label:
                      'Aadhaar Back',
                  uploaded:
                      backUploaded,
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
                  icon: Icons
                      .verified_user_outlined,
                  iconColor:
                      const Color(
                    0xFF16A34A,
                  ),
                  label:
                      'Walker UID',
                  value:
                      _display(uid),
                ),

                const SizedBox(
                  height: 20,
                ),

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

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // SAFE STRING
  // ==========================================================

  static String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  // ==========================================================
  // DISPLAY VALUE
  // ==========================================================

  static String _display(
    String value,
  ) {
    return value.isEmpty
        ? 'Not available'
        : value;
  }
}
