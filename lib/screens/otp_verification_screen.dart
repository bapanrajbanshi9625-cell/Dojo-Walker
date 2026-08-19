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
  // ============================================================
  // SERVICES
  // ============================================================

  final AuthService _authService = AuthService.instance;

  final TextEditingController _otpController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;

  String _errorMessage = '';

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_isLoading) {
      return;
    }

    final String otp = _otpController.text.trim();

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
      // STEP 1
      // FIREBASE OTP VERIFICATION
      // ========================================================

      debugPrint('========================================');
      debugPrint('STEP 1: VERIFYING FIREBASE OTP');
      debugPrint('========================================');

      await _authService.verifyOTP(
        verificationId: widget.verificationId.trim(),
        smsCode: otp,
      );

      debugPrint('========================================');
      debugPrint('STEP 1 SUCCESS: FIREBASE OTP VERIFIED');
      debugPrint('========================================');

      // ========================================================
      // STEP 2
      // GET CURRENT FIREBASE USER
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

      final String uid = user.uid.trim();

      if (uid.isEmpty) {
        throw FirebaseAuthException(
          code: 'empty-uid',
          message: 'Firebase UID is empty.',
        );
      }

      final String phone =
          (user.phoneNumber ?? widget.phoneNumber).trim();

      debugPrint('========================================');
      debugPrint('STEP 2 SUCCESS: FIREBASE USER FOUND');
      debugPrint('FIREBASE UID: $uid');
      debugPrint('PHONE: $phone');
      debugPrint('========================================');

      // ========================================================
      // STEP 3
      // CREATE / GET WALKER ID
      //
      // ONLY after successful OTP.
      // ========================================================

      debugPrint('========================================');
      debugPrint('STEP 3: GET / CREATE WALKER ID');
      debugPrint('========================================');

      final String walkerId =
          await WalkerIdService.instance.getOrCreateWalkerId(
        uid: uid,
        phoneNumber: phone,
      );

      if (walkerId.trim().isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'empty-walker-id',
          message: 'Walker ID could not be created.',
        );
      }

      debugPrint('========================================');
      debugPrint(
        'STEP 3 SUCCESS: WALKER ID = $walkerId',
      );
      debugPrint('========================================');

      // ========================================================
      // STEP 4
      // CHECK WALKER PROFILE
      // ========================================================

      debugPrint('========================================');
      debugPrint('STEP 4: CHECK WALKER PROFILE');
      debugPrint('UID: $uid');
      debugPrint('========================================');

      final bool profileCompleted =
          await ProfileSetupService.isWalkerProfileCompleted(
        authUid: uid,
      );

      debugPrint('========================================');
      debugPrint(
        'STEP 4 SUCCESS: PROFILE COMPLETED = '
        '$profileCompleted',
      );
      debugPrint('========================================');

      // ========================================================
      // STEP 5
      // SAVE LOCAL SESSION
      // ========================================================

      debugPrint('========================================');
      debugPrint('STEP 5: SAVING LOCAL SESSION');
      debugPrint('========================================');

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      final bool loginSaved =
          await prefs.setBool(
        'isLoggedIn',
        true,
      );

      final bool walkerIdSaved =
          await prefs.setString(
        'walkerId',
        walkerId,
      );

      final bool uidSaved =
          await prefs.setString(
        'authUid',
        uid,
      );

      if (!loginSaved ||
          !walkerIdSaved ||
          !uidSaved) {
        throw Exception(
          'Unable to save local walker session.',
        );
      }

      debugPrint('========================================');
      debugPrint('STEP 5 SUCCESS: LOCAL SESSION SAVED');
      debugPrint('========================================');

      // ========================================================
      // STEP 6
      // NAVIGATION
      // ========================================================

      if (!mounted) {
        return;
      }

      debugPrint('========================================');
      debugPrint('STEP 6: NAVIGATION');
      debugPrint(
        'PROFILE COMPLETED: $profileCompleted',
      );
      debugPrint('========================================');

      if (profileCompleted) {
        // ------------------------------------------------------
        // PROFILE COMPLETE → HOME
        // ------------------------------------------------------

        debugPrint(
          'PROFILE COMPLETE → HOME',
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      } else {
        // ------------------------------------------------------
        // PROFILE INCOMPLETE → PROFILE SETUP
        // ------------------------------------------------------

        debugPrint(
          'PROFILE INCOMPLETE → PROFILE SETUP',
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/profile-setup',
          (route) => false,
        );
      }
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint('========================================');
      debugPrint('FIREBASE AUTH ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _friendlyOtpError(e);
      });
    }

    // ==========================================================
    // FIREBASE / FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint('========================================');
      debugPrint('FIREBASE / FIRESTORE ERROR');
      debugPrint('PLUGIN: ${e.plugin}');
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

    catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('OTP FLOW ERROR');
      debugPrint('ERROR TYPE: ${e.runtimeType}');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE:');
      debugPrint('$stackTrace');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Verification succeeded, but account setup '
            'could not be completed.\n\n'
            '$e';
      });
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                keyboardType: TextInputType.number,
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
                Container(
                  padding: const EdgeInsets.all(12),
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
                            color: Colors.white,
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
