import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../services/profile_firebase_service.dart';
import '../widgets/mobile_number_card.dart';
import '../widgets/profile_bottom_sheets.dart';
import '../widgets/profile_document_card.dart';
import '../widgets/profile_info_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color walkerOrange = Color(0xFFFF4B16);

  // ==========================================================
  // DOCUMENT VIEWER
  // ==========================================================

  void _openDocumentViewer(
    BuildContext context, {
    required String title,
    required String imageUrl,
  }) {
    final String cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document is not available.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _DocumentViewerSheet(
          title: title,
          imageUrl: cleanUrl,
          onDownload: () async {
            await _downloadDocument(
              sheetContext,
              title: title,
              imageUrl: cleanUrl,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // DOWNLOAD DOCUMENT
  // ==========================================================

  Future<void> _downloadDocument(
    BuildContext context, {
    required String title,
    required String imageUrl,
  }) async {
    final String cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document URL is not available.',
          ),
        ),
      );

      return;
    }

    bool loadingShown = false;

    try {
      // --------------------------------------------------------
      // SHOW LOADING
      // --------------------------------------------------------

      showDialog<void>(
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

      // --------------------------------------------------------
      // DOWNLOAD
      // --------------------------------------------------------

      final http.Response response =
          await http.get(
        Uri.parse(cleanUrl),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Unable to download document. '
          'HTTP ${response.statusCode}',
        );
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception(
          'Downloaded document is empty.',
        );
      }

      // --------------------------------------------------------
      // APP DOCUMENT DIRECTORY
      // --------------------------------------------------------

      final Directory directory =
          await getApplicationDocumentsDirectory();

      // --------------------------------------------------------
      // SAFE FILE NAME
      // --------------------------------------------------------

      final String safeTitle =
          title
              .toLowerCase()
              .replaceAll(
                RegExp(r'[^a-z0-9]+'),
                '_',
              )
              .replaceAll(
                RegExp(r'_+'),
                '_',
              )
              .replaceAll(
                RegExp(r'^_|_$'),
                '',
              );

      final String fileName =
          '${safeTitle.isEmpty ? 'document' : safeTitle}.jpg';

      final File file = File(
        '${directory.path}/$fileName',
      );

      // --------------------------------------------------------
      // SAVE
      // --------------------------------------------------------

      await file.writeAsBytes(
        response.bodyBytes,
        flush: true,
      );

      // --------------------------------------------------------
      // CLOSE LOADING
      // --------------------------------------------------------

      if (context.mounted && loadingShown) {
        Navigator.of(context).pop();
        loadingShown = false;
      }

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: walkerOrange,
          content: Text(
            '$title downloaded successfully.',
          ),
        ),
      );
    } catch (e) {
      // --------------------------------------------------------
      // CLOSE LOADING
      // --------------------------------------------------------

      if (context.mounted && loadingShown) {
        Navigator.of(context).pop();
        loadingShown = false;
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Download failed: $e',
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
    showModalBottomSheet<void>(
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
  // CURRENT OTP SHEET
  // ==========================================================

  void _openCurrentOtpSheet(
    BuildContext context,
    String verificationId,
  ) {
    showModalBottomSheet<void>(
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

              ScaffoldMessenger.of(sheetContext)
                  .showSnackBar(
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
    showModalBottomSheet<void>(
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
  // SEND NEW PHONE OTP
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
  // NEW PHONE OTP SHEET
  // ==========================================================

  void _openNewPhoneOtpSheet(
    BuildContext context,
    String verificationId,
    String newPhone,
  ) {
    showModalBottomSheet<void>(
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

              ScaffoldMessenger.of(sheetContext)
                  .showSnackBar(
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

    // ========================================================
    // LOGIN CHECK
    // ========================================================

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

    // ========================================================
    // AUTH UID
    // ========================================================

    final String walkerUid =
        user.uid.trim();

    // ========================================================
    // PROFILE
    // ========================================================

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
      // WALKER DOCUMENT
      // walkers/{AUTH UID}
      // ======================================================

      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
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
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 50,
                      color:
                          AppColors.textGrey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load profile.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ==================================================
          // DOCUMENT
          // ==================================================

          final DocumentSnapshot<
                  Map<String, dynamic>>?
              document =
              snapshot.data;

          if (document == null ||
              !document.exists) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_search_outlined,
                      size: 50,
                      color:
                          AppColors.textGrey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Profile information not found.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Walker UID:\n$walkerUid',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ==================================================
          // DATA
          // ==================================================

          final Map<String, dynamic> data =
              document.data() ??
                  <String, dynamic>{};

          // ==================================================
          // BASIC PROFILE
          // ==================================================

          final String name =
              _firstString(
            data,
            <String>[
              'Full Name',
              'fullName',
              'name',
            ],
          );

          final String firestorePhone =
              _firstString(
            data,
            <String>[
              'Mobile number',
              'mobileNumber',
              'phoneNumber',
              'phone',
            ],
          );

          final String phone =
              firestorePhone.isNotEmpty
                  ? firestorePhone
                  : _stringValue(
                      user.phoneNumber,
                    );

          final String dob =
              _firstString(
            data,
            <String>[
              'Date Of Birth',
              'dateOfBirth',
              'dateofbirth',
            ],
          );

          final String address =
              _firstString(
            data,
            <String>[
              'Adress',
              'Address',
              'address',
            ],
          );

          final String pincode =
              _firstString(
            data,
            <String>[
              'Pincode',
              'pincode',
              'pinCode',
            ],
          );

          // ==================================================
          // AADHAAR NUMBER
          // ==================================================

          final String aadhaar =
              _firstString(
            data,
            <String>[
              'Aadhar Number',
              'Aadhaar Number',
              'aadhaarNumber',
            ],
          );

          // ==================================================
          // SELFIE
          // ==================================================

          final String selfie =
              _firstString(
            data,
            <String>[
              'selfieUrl',
              'selfie',
              'Profile Selfie',
              'profileSelfie',
              'profileImageUrl',
              'profileImage',
            ],
          );

          // ==================================================
          // AADHAAR FRONT
          // ==================================================

          final String aadhaarFront =
              _firstString(
            data,
            <String>[
              'aadhaarFrontUrl',
              'aadhaarFront',
              'aadhaarfront',
              'aadhaar_front',
              'Aadhaar Front',
            ],
          );

          // ==================================================
          // AADHAAR BACK
          // ==================================================

          final String aadhaarBack =
              _firstString(
            data,
            <String>[
              'aadhaarBackUrl',
              'aadhaarBack',
              'aadhaarback',
              'aadhaar_back',
              'Aadhaar Back',
            ],
          );

          // ==================================================
          // PAN
          // ==================================================

          final String panCard =
              _firstString(
            data,
            <String>[
              'panCardUrl',
              'panCard',
              'pan_card',
              'pan_card_url',
              'PAN Card',
              'PAN Card URL',
            ],
          );

          // ==================================================
          // UPLOAD FLAGS
          // ==================================================

          final bool frontUploaded =
              aadhaarFront.isNotEmpty ||
                  data['aadhaar_front_uploaded'] ==
                      true ||
                  data['aadhaarFrontUploaded'] ==
                      true;

          final bool backUploaded =
              aadhaarBack.isNotEmpty ||
                  data['aadhaar_back_uploaded'] ==
                      true ||
                  data['aadhaarBackUploaded'] ==
                      true;

          final bool panUploaded =
              panCard.isNotEmpty ||
                  data['pan_card_uploaded'] ==
                      true ||
                  data['panCardUploaded'] ==
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
                // PROFILE PHOTO
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
                                color: Colors.white,
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

                const SizedBox(height: 14),

                // =================================================
                // NAME
                // =================================================

                Center(
                  child: Text(
                    _display(name),
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

                const SizedBox(height: 28),

                // =================================================
                // PROFILE INFORMATION
                // =================================================

                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                ProfileInfoCard(
                  icon:
                      Icons.person_outline,
                  iconColor:
                      walkerOrange,
                  label: 'Full Name',
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
                      const Color(0xFFE11D48),
                  label: 'Date of Birth',
                  value:
                      _display(dob),
                ),

                ProfileInfoCard(
                  icon:
                      Icons.location_on_outlined,
                  iconColor:
                      const Color(0xFF2563EB),
                  label: 'Address',
                  value:
                      _display(address),
                ),

                ProfileInfoCard(
                  icon:
                      Icons.pin_drop_outlined,
                  iconColor:
                      const Color(0xFF0891B2),
                  label: 'PIN Code',
                  value:
                      _display(pincode),
                ),

                const SizedBox(height: 10),

                // =================================================
                // DOCUMENT INFORMATION
                // =================================================

                const Text(
                  'Document Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                ProfileInfoCard(
                  icon:
                      Icons.badge_outlined,
                  iconColor:
                      const Color(0xFF7C3AED),
                  label:
                      'Aadhaar Number',
                  value:
                      _display(aadhaar),
                ),

                // =================================================
                // AADHAAR FRONT
                // =================================================

                ProfileDocumentCard(
                  label:
                      'Aadhaar Front',
                  uploaded:
                      frontUploaded,
                  onView:
                      aadhaarFront.isEmpty
                          ? null
                          : () {
                              _openDocumentViewer(
                                context,
                                title:
                                    'Aadhaar Front',
                                imageUrl:
                                    aadhaarFront,
                              );
                            },
                  onDownload:
                      aadhaarFront.isEmpty
                          ? null
                          : () {
                              _downloadDocument(
                                context,
                                title:
                                    'Aadhaar Front',
                                imageUrl:
                                    aadhaarFront,
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
                      backUploaded,
                  onView:
                      aadhaarBack.isEmpty
                          ? null
                          : () {
                              _openDocumentViewer(
                                context,
                                title:
                                    'Aadhaar Back',
                                imageUrl:
                                    aadhaarBack,
                              );
                            },
                  onDownload:
                      aadhaarBack.isEmpty
                          ? null
                          : () {
                              _downloadDocument(
                                context,
                                title:
                                    'Aadhaar Back',
                                imageUrl:
                                    aadhaarBack,
                              );
                            },
                ),

                // =================================================
                // PAN
                // =================================================

                ProfileDocumentCard(
                  label:
                      'PAN Card',
                  uploaded:
                      panUploaded,
                  onView:
                      panCard.isEmpty
                          ? null
                          : () {
                              _openDocumentViewer(
                                context,
                                title:
                                    'PAN Card',
                                imageUrl:
                                    panCard,
                              );
                            },
                  onDownload:
                      panCard.isEmpty
                          ? null
                          : () {
                              _downloadDocument(
                                context,
                                title:
                                    'PAN Card',
                                imageUrl:
                                    panCard,
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
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                ProfileInfoCard(
                  icon:
                      Icons.verified_user_outlined,
                  iconColor:
                      const Color(0xFF16A34A),
                  label:
                      'Walker UID',
                  value:
                      walkerUid,
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Your profile is securely linked to your Walker UID.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          AppColors.textGrey,
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

  // ==========================================================
  // READ FIRST AVAILABLE STRING
  // ==========================================================

  static String _firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String value =
          _stringValue(data[key]);

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
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

    return value.toString().trim();
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

// ============================================================
// DOCUMENT VIEWER SHEET
// ============================================================

class _DocumentViewerSheet extends StatelessWidget {
  const _DocumentViewerSheet({
    required this.title,
    required this.imageUrl,
    required this.onDownload,
  });

  final String title;
  final String imageUrl;
  final Future<void> Function() onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ======================================================
          // HANDLE
          // ======================================================

          const SizedBox(height: 10),

          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 14),

          // ======================================================
          // HEADER
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors.textDark,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ======================================================
          // IMAGE
          // ======================================================

          Expanded(
            child: Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF5F5F5,
                ),
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color:
                      AppColors.border,
                ),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (
                    context,
                    child,
                    progress,
                  ) {
                    if (progress == null) {
                      return child;
                    }

                    return const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            ProfileScreen
                                .walkerOrange,
                      ),
                    );
                  },
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Center(
                      child: Padding(
                        padding:
                            EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons
                                  .broken_image_outlined,
                              size: 56,
                              color:
                                  AppColors
                                      .textGrey,
                            ),
                            SizedBox(
                              height: 12,
                            ),
                            Text(
                              'Unable to display this document.',
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  TextStyle(
                                color:
                                    AppColors
                                        .textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ======================================================
          // DOWNLOAD
          // ======================================================

          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await onDownload();
                  },
                  icon: const Icon(
                    Icons.download_outlined,
                  ),
                  label: const Text(
                    'Download Document',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        ProfileScreen
                            .walkerOrange,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
