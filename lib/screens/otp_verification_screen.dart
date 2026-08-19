import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/walker_id_service.dart';
import '../features/profile_setup/services/profile_setup_service.dart';

import 'main_navigation_screen.dart';
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
  final AuthService _authService =
      AuthService.instance;

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

    if (!RegExp(r'^[0-9]{6}$')
        .hasMatch(otp)) {
      if (!mounted) return;

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
      // STEP 1 - OTP
      // ========================================================

      debugPrint(
        'STEP 1: VERIFY OTP',
      );

      await _authService.verifyOTP(
        verificationId:
            widget.verificationId,
        smsCode: otp,
      );

      // ========================================================
      // STEP 2 - USER
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

      final String phone =
          (user.phoneNumber ??
                  widget.phoneNumber)
              .trim();

      debugPrint(
        'STEP 2 SUCCESS: UID=$uid',
      );

      // ========================================================
      // STEP 3 - WALKER ID
      // ========================================================

      debugPrint(
        'STEP 3: GET / CREATE WALKER ID',
      );

      final String walkerId =
          await WalkerIdService.instance
              .getOrCreateWalkerId(
        uid: uid,
        phoneNumber: phone,
      );

      if (walkerId.trim().isEmpty) {
        throw Exception(
          'Walker ID is empty.',
        );
      }

      debugPrint(
        'STEP 3 SUCCESS: $walkerId',
      );

      // ========================================================
      // STEP 4 - PROFILE
      // ========================================================

      final bool profileCompleted =
          await ProfileSetupService
              .isWalkerProfileCompleted(
        authUid: uid,
      );

      debugPrint(
        'STEP 4: profileCompleted=$profileCompleted',
      );

      // ========================================================
      // STEP 5 - LOCAL SESSION
      // ========================================================

      final SharedPreferences prefs =
          await SharedPreferences
              .getInstance();

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
        'STEP 5 SUCCESS: SESSION SAVED',
      );

      // ========================================================
      // STEP 6 - NAVIGATION
      // ========================================================

      if (!mounted) {
        return;
      }

      if (profileCompleted) {
        debugPrint(
          'OTP → PROFILE COMPLETE → HOME',
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                const MainNavigationScreen(),
          ),
          (route) => false,
        );
      } else {
        debugPrint(
          'OTP → PROFILE INCOMPLETE → MANDATORY PROFILE',
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                const MandatoryProfileSetupScreen(),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AUTH ERROR: ${e.code}',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage =
            _friendlyOtpError(e);
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'FIREBASE ERROR: ${e.code}',
      );

            if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Account setup failed.\n\n'
            'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _friendlyOtpError(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please enter the correct 6-digit OTP.';

      case 'invalid-verification-id':
      case 'session-expired':
        return 'OTP session expired. Please request a new OTP.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'invalid-phone-number':
        return 'Invalid phone number. Please try again.';

      case 'missing-verification-id':
        return 'OTP session is missing. Please request a new OTP.';

      case 'invalid-otp-format':
        return 'Please enter a valid 6-digit OTP.';

      case 'user-not-found':
        return 'Firebase login succeeded, but the user session was not found.';

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

              const Text(
                'Enter OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'OTP sent to +91 ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _otpController,
                keyboardType:
                    TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
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

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 15),

                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

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

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
