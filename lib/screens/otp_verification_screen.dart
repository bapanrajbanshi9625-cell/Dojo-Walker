import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import 'profile_setup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final TextEditingController _otpController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  String? _firebaseError;

  // =====================================================
  // VERIFY OTP
  // =====================================================

  Future<void> _verifyOtp() async {
    final String otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage(
        'Please enter valid 6-digit OTP.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _firebaseError = null;
    });

    try {
      debugPrint('========================================');
      debugPrint('OTP SCREEN');
      debugPrint(
        'Verification ID length: ${widget.verificationId.length}',
      );
      debugPrint('OTP length: ${otp.length}');
      debugPrint('========================================');

      final bool success = await _authService.verifyOTP(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      // ===================================================
      // OTP FAILED
      // ===================================================

      if (!success) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
          _firebaseError =
              'Firebase OTP verification failed.\n\n'
              'Check the Debug Console for the exact Firebase error.';
        });

        _showMessage(
          'OTP verification failed. Check the error below.',
        );

        return;
      }

      // ===================================================
      // CHECK FIREBASE SESSION
      // ===================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
          _firebaseError =
              'OTP was accepted, but Firebase session was not found.';
        });

        _showMessage(
          'Firebase login session was not created.',
        );

        return;
      }

      // ===================================================
      // SUCCESS
      // ===================================================

      debugPrint('========================================');
      debugPrint('OTP VERIFIED SUCCESSFULLY');
      debugPrint('Firebase UID: ${user.uid}');
      debugPrint('Firebase Phone: ${user.phoneNumber}');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // ===================================================
      // OPEN PROFILE SETUP
      // ===================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MandatoryProfileSetupScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('========================================');
      debugPrint('OTP SCREEN FIREBASE ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _firebaseError =
            'Firebase Error\n\n'
            'Code: ${e.code}\n'
            'Message: ${e.message ?? 'Unknown Firebase error'}';
      });

      _showMessage(
        'Firebase Error: ${e.code}',
      );
    } catch (e) {
      debugPrint('========================================');
      debugPrint('OTP SCREEN GENERAL ERROR');
      debugPrint('$e');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _firebaseError =
            'Verification Error\n\n$e';
      });

      _showMessage(
        'OTP verification failed.',
      );
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'OTP Verification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  // =================================================
                  // ICON
                  // =================================================

                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // TITLE
                  // =================================================

                  const Text(
                    'Verify Your Mobile Number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =================================================
                  // PHONE
                  // =================================================

                  Text(
                    '+91 ${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter the 6-digit OTP sent to your mobile number.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // OTP LABEL
                  // =================================================

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Enter 6-Digit OTP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // =================================================
                  // OTP INPUT
                  // =================================================

                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !_isLoading,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '123456',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD5D9DE),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // VERIFY BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        disabledBackgroundColor:
                            Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _isLoading ? null : _verifyOtp,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Verify OTP & Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // FIREBASE ERROR
                  // =================================================

                  if (_firebaseError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        _firebaseError!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 15),

                  const Text(
                    'Your mobile number will be securely verified with Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
