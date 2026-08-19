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

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
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

    bool verificationSucceeded = false;

    try {
      // ========================================================
      // 1. FIREBASE OTP
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

      verificationSucceeded = true;

      // ========================================================
      // 2. FIREBASE USER
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

      debugPrint(
        '========================================',
      );
      debugPrint(
        'OTP VERIFICATION SUCCESS',
      );
      debugPrint(
        'UID: $uid',
      );
      debugPrint(
        'PHONE: '
        '${user.phoneNumber ?? widget.phoneNumber}',
      );
      debugPrint(
        '========================================',
      );

      // ========================================================
      // 3. WALKER ID
      //
      // ONLY after successful OTP.
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
      // 4. PROFILE CHECK
      // ========================================================

      final bool profileCompleted =
          await ProfileSetupService
              .isWalkerProfileCompleted(
        authUid: uid,
      );

      // ========================================================
      // 5. LOCAL SESSION
      //
      // Only after successful OTP.
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
        'LOCAL SESSION SAVED',
      );

      // ========================================================
      // 6. NAVIGATION
      // ========================================================

      if (!mounted) {
        return;
      }

      if (profileCompleted) {
        debugPrint(
          'Profile complete → Home',
        );

        Navigator.of(context)
            .pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      } else {
        debugPrint(
          'Profile incomplete → Profile Setup',
        );

        Navigator.of(context)
            .pushNamedAndRemoveUntil(
          '/profile-setup',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '========================================',
      );
      debugPrint(
        'OTP VERIFICATION FAILED',
      );
      debugPrint(
        'CODE: ${e.code}',
      );
      debugPrint(
        'MESSAGE: ${e.message}',
      );
      debugPrint(
        '========================================',
      );

      // ========================================================
      // IMPORTANT
      //
      // If OTP fails:
      //
      // NO Walker ID
      // NO local login
      // NO profile navigation
      // Stay on OTP screen.
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            _friendlyOtpError(e);
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'FIREBASE ERROR: ${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            e.message ??
                'Unable to complete verification.';
      });
    } catch (e) {
      debugPrint(
        'OTP FLOW ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Unable to complete verification.\n'
            'Please try again.';
      });
    } finally {
      // IMPORTANT:
      // Do NOT use "return" inside finally.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FRIENDLY ERROR
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

      case 'invalid-otp-format':
        return 'OTP must contain exactly 6 digits.';

      case 'missing-verification-id':
        return 'OTP session is missing. Please request a new OTP.';

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          'Verify OTP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 25),

              const Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor:
                      Color(0xFFFF6600),
                  child: Icon(
                    Icons.sms_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Enter OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'We sent a 6-digit OTP to\n+91 ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // OTP CARD
              // ==================================================

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      offset: Offset(0, 6),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller:
                          _otpController,
                      keyboardType:
                          TextInputType.number,
                      maxLength: 6,
                      textAlign:
                          TextAlign.center,
                      autofocus: true,
                      enabled: !_isLoading,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration:
                          InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        filled: true,
                        fillColor:
                            const Color(
                          0xFFF8F9FA,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(0xFFFF6600),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (_errorMessage
                            .isNotEmpty) {
                          setState(() {
                            _errorMessage = '';
                          });
                        }
                      },
                    ),

                    if (_errorMessage
                        .isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorMessage,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _verifyOtp,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFFFF6600,
                          ),
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
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Verify OTP',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Your Walker ID and profile will be processed only after successful OTP verification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  height: 1.4,
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
