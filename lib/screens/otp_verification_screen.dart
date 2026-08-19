// File location:
// lib/screens/otp_verification.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/walker_id_service.dart';
import '../features/profile_setup/services/profile_setup_service.dart';

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
  final AuthService _authService = AuthService();

  final TextEditingController _otpController =
      TextEditingController();

  bool _isLoading = false;

  String _errorMessage = '';

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_isLoading) {
      return;
    }

    final String otp =
        _otpController.text.trim();

    // ==========================================================
    // OTP VALIDATION
    // ==========================================================

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Please enter a valid 6-digit OTP.';
      });

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // ========================================================
      // 1. FIREBASE OTP VERIFICATION
      //
      // IMPORTANT:
      // If OTP is wrong, this throws an exception.
      //
      // Nothing below this point will execute.
      // ========================================================

      final bool success =
          await _authService.verifyOTP(
        verificationId:
            widget.verificationId,
        smsCode: otp,
      );

      if (!success) {
        throw FirebaseAuthException(
          code: 'otp-verification-failed',
          message:
              'OTP verification failed.',
        );
      }

      // ========================================================
      // 2. GET FIREBASE USER
      // ========================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message:
              'Firebase user was not found after OTP verification.',
        );
      }

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        throw FirebaseAuthException(
          code: 'empty-uid',
          message:
              'Firebase UID is empty.',
        );
      }

      debugPrint('========================================');
      debugPrint('OTP VERIFICATION SUCCESS');
      debugPrint('Firebase UID: $uid');
      debugPrint(
        'Phone: ${user.phoneNumber ?? widget.phoneNumber}',
      );
      debugPrint('========================================');

      // ========================================================
      // 3. CREATE / GET WALKER ID
      //
      // This happens ONLY after successful OTP.
      // ========================================================

      final String walkerId =
          await WalkerIdService.instance
              .getOrCreateWalkerId(
        uid: uid,
        phoneNumber:
            user.phoneNumber ??
                widget.phoneNumber,
      );

      debugPrint(
        'Walker ID: $walkerId',
      );

      // ========================================================
      // 4. CHECK PROFILE
      //
      // Do this BEFORE saving local login state.
      // ========================================================

      final bool profileCompleted =
          await ProfileSetupService
              .isWalkerProfileCompleted(
        authUid: uid,
      );

      // ========================================================
      // 5. SAVE LOCAL SESSION
      //
      // Only successful OTP + successful account setup.
      // ========================================================

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'isLoggedIn',
        true,
      );

      await prefs.setString(
        'walkerId',
        walkerId,
      );

      await prefs.setString(
        'authUid',
        uid,
      );

      debugPrint(
        'Local walker session saved.',
      );

      // ========================================================
      // 6. NAVIGATION
      // ========================================================

      if (!mounted) {
        return;
      }

      if (profileCompleted) {
        // ------------------------------------------------------
        // PROFILE COMPLETE
        // ------------------------------------------------------

        debugPrint(
          'Profile complete → Main Navigation',
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      } else {
        // ------------------------------------------------------
        // PROFILE NOT COMPLETE
        // ------------------------------------------------------

        debugPrint(
          'Profile incomplete → Profile Setup',
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/profile-setup',
          (route) => false,
        );
      }
    }

    // ==========================================================
    // OTP / FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint('========================================');
      debugPrint('OTP VERIFICATION FAILED');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('========================================');

      // --------------------------------------------------------
      // IMPORTANT:
      // DO NOT:
      // - create Walker ID
      // - write Firestore
      // - save SharedPreferences
      // - navigate to Profile Setup
      //
      // User stays on OTP screen.
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            _friendlyOtpError(e);
      });
    }

    // ==========================================================
    // FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint('========================================');
      debugPrint('FIRESTORE / FIREBASE ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            e.message ??
            'Unable to complete account setup.';
      });
    }

    // ==========================================================
    // GENERAL ERROR
    // ==========================================================

    catch (e) {
      debugPrint('========================================');
      debugPrint('OTP FLOW ERROR');
      debugPrint('$e');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Unable to complete verification.\n'
            'Please try again.';
      });
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FRIENDLY OTP ERROR
  // ============================================================

  String _friendlyOtpError(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please enter the correct 6-digit OTP.';

      case 'invalid-verification-id':
        return 'This OTP session has expired. Please request a new OTP.';

      case 'session-expired':
        return 'OTP session expired. Please request a new OTP.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'invalid-phone-number':
        return 'Invalid phone number. Please try again.';

      default:
        return e.message ??
            'OTP verification failed. Please try again.';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify OTP',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Enter OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // PHONE
              // ==================================================

              Text(
                'OTP sent to +91 ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // ==================================================
              // OTP FIELD
              // ==================================================

              TextField(
                controller: _otpController,
                keyboardType:
                    TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                obscureText: false,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),

              // ==================================================
              // ERROR
              // ==================================================

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 15),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // INFO
              // ==================================================

              const Text(
                'After successful verification, your Walker ID '
                'will be created automatically if you do not '
                'already have one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
