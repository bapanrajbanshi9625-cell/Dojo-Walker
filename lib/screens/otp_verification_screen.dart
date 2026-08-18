import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/profile_setup/services/profile_setup_service.dart';
import '../services/auth_service.dart';
import '../services/walker_id_service.dart';
import 'main_navigation_screen.dart';
import '../features/profile_setup/screens/mandatory_profile_setup_screen1.dart';

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

  final AuthService _authService =
      AuthService();

  bool _isLoading = false;

  String? _firebaseError;

  static const Color orange =
      Color(0xFFF4511E);

  static const Color dark =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFF7F8FA);

  // =====================================================
  // VERIFY OTP
  // =====================================================

  Future<void> _verifyOtp() async {
    final String otp =
        _otpController.text.trim();

    if (otp.length != 6) {
      _showMessage(
        'Please enter valid 6-digit OTP.',
      );
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _firebaseError = null;
    });

    try {
      debugPrint(
        '========================================',
      );
      debugPrint('WALKER OTP VERIFICATION');
      debugPrint(
        'Verification ID length: '
        '${widget.verificationId.length}',
      );
      debugPrint(
        'OTP length: ${otp.length}',
      );
      debugPrint(
        '========================================',
      );

      // =================================================
      // 1. VERIFY OTP
      // =================================================

      final bool success =
          await _authService.verifyOTP(
        verificationId:
            widget.verificationId,
        smsCode: otp,
      );

      if (!success) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _firebaseError =
              'Firebase OTP verification failed.\n\n'
              'Please check the OTP and try again.';
        });

        _showMessage(
          'OTP verification failed.',
        );

        return;
      }

      // =================================================
      // 2. FIREBASE SESSION
      // =================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _firebaseError =
              'OTP was accepted, but Firebase '
              'session was not found.';
        });

        _showMessage(
          'Firebase login session was not created.',
        );

        return;
      }

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        throw Exception(
          'Firebase UID is empty.',
        );
      }

      // =================================================
      // 3. VERIFIED PHONE
      // =================================================

      String phoneNumber =
          user.phoneNumber?.trim() ?? '';

      if (phoneNumber.isEmpty) {
        phoneNumber =
            widget.phoneNumber.trim();

        if (!phoneNumber.startsWith('+')) {
          phoneNumber =
              '+91$phoneNumber';
        }
      }

      debugPrint(
        'Firebase UID: $uid',
      );

      debugPrint(
        'Firebase Phone: $phoneNumber',
      );

      // =================================================
      // 4. GET / CREATE WALKER ID
      // =================================================

      debugPrint(
        'Getting Walker ID...',
      );

      final String walkerId =
          await WalkerIdService.instance
              .getOrCreateWalkerId(
        uid: uid,
        phoneNumber: phoneNumber,
      );

      debugPrint(
        'Walker ID: $walkerId',
      );

      // =================================================
      // 5. CHECK WALKER PROFILE
      // =================================================

      debugPrint(
        'Checking Walker profile...',
      );

      final bool profileCompleted =
          await ProfileSetupService
              .isWalkerProfileCompleted(
        authUid: uid,
      );

      debugPrint(
        'Walker profile completed: '
        '$profileCompleted',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // =================================================
      // 6. PROFILE COMPLETE
      // =================================================

      if (profileCompleted) {
        debugPrint(
          'PROFILE COMPLETE → HOME',
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MainNavigationScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // =================================================
      // 7. PROFILE INCOMPLETE
      // =================================================

      debugPrint(
  'PROFILE INCOMPLETE → PROFILE SETUP',
);

Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (context) => const MandatoryProfileSetupScreen1(),
  ),
  (route) => false,
);

    // ==================================================
    // FIREBASE AUTH ERROR
    // ==================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'WALKER OTP FIREBASE ERROR',
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

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _firebaseError =
            'Firebase Error\n\n'
            'Code: ${e.code}\n'
            'Message: '
            '${e.message ?? 'Unknown Firebase error'}';
      });

      _showMessage(
        _firebaseError!,
      );
    }

    // ==================================================
    // GENERAL ERROR
    // ==================================================

    catch (e) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'WALKER OTP ERROR',
      );

      debugPrint('$e');

      debugPrint(
        '========================================',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _firebaseError =
            'Verification Error\n\n$e';
      });

      _showMessage(
        'Verification failed. Please try again.',
      );
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          duration:
              const Duration(seconds: 4),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
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
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: const Text(
          'OTP Verification',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },

          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,

            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),

            child: Column(
              children: [
                // ==================================================
                // HEADER ICON
                // ==================================================

                Container(
                  height: 82,
                  width: 82,
                  decoration:
                      BoxDecoration(
                    color:
                        orange.withOpacity(
                      0.10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),

                  child: Center(
                    child: Container(
                      height: 62,
                      width: 62,
                      decoration:
                          BoxDecoration(
                        color: orange,
                        shape:
                            BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: orange
                                .withOpacity(
                              0.25,
                            ),
                            blurRadius: 18,
                            offset:
                                const Offset(
                              0,
                              7,
                            ),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons
                            .verified_user_rounded,
                        color:
                            Colors.white,
                        size: 31,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Verify your number',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: dark,
                    fontSize: 27,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing:
                        -0.4,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Enter the 6-digit OTP sent to',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                // ==================================================
                // PHONE
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),

                  decoration:
                      BoxDecoration(
                    color: orange
                        .withOpacity(
                      0.08,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),

                  child: Text(
                    _displayPhoneNumber(),
                    style:
                        const TextStyle(
                      color: orange,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 26,
                ),

                // ==================================================
                // OTP CARD
                // ==================================================

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    18,
                    20,
                    18,
                    20,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius
                            .circular(
                      22,
                    ),

                    border: Border.all(
                      color:
                          const Color(
                        0xFFE1E5EA,
                      ),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(
                          0.045,
                        ),
                        blurRadius: 20,
                        offset:
                            const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      // ==================================================
                      // LABEL
                      // ==================================================

                      const Row(
                        children: [
                          Icon(
                            Icons
                                .password_rounded,
                            color: orange,
                            size: 19,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Enter 6-Digit OTP',
                            style:
                                TextStyle(
                              color: dark,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // OTP FIELD
                      // ==================================================

                      TextField(
                        controller:
                            _otpController,

                        enabled:
                            !_isLoading,

                        keyboardType:
                            TextInputType
                                .number,

                        textInputAction:
                            TextInputAction
                                .done,

                        maxLength: 6,

                        textAlign:
                            TextAlign.center,

                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],

                        onSubmitted: (_) {
                          if (!_isLoading) {
                            _verifyOtp();
                          }
                        },

                        style:
                            const TextStyle(
                          color: dark,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 9,
                        ),

                        decoration:
                            InputDecoration(
                          hintText:
                              '••••••',

                          hintStyle:
                              TextStyle(
                            color: Colors.grey
                                .shade300,
                            fontSize: 25,
                            letterSpacing:
                                8,
                          ),

                          counterText: '',

                          filled: true,

                          fillColor:
                              const Color(
                            0xFFF8F9FA,
                          ),

                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 17,
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                            borderSide:
                                BorderSide(
                              color: Colors.grey
                                  .shade200,
                            ),
                          ),

                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                            borderSide:
                                BorderSide(
                              color: Colors.grey
                                  .shade200,
                            ),
                          ),

                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                            borderSide:
                                const BorderSide(
                              color: orange,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // VERIFY BUTTON
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,

                        height: 56,

                        child:
                            ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _verifyOtp,

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                orange,

                            disabledBackgroundColor:
                                orange
                                    .withOpacity(
                              0.55,
                            ),

                            elevation: 2,

                            shadowColor:
                                orange
                                    .withOpacity(
                              0.25,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                            ),
                          ),

                          child:
                              _isLoading
                                  ? const SizedBox(
                                      width: 23,
                                      height: 23,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth:
                                            2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [
                                        Icon(
                                          Icons
                                              .check_circle_outline_rounded,
                                          color:
                                              Colors.white,
                                          size:
                                              22,
                                        ),
                                        SizedBox(
                                          width:
                                              9,
                                        ),
                                        Text(
                                          'Verify & Continue',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white,
                                            fontSize:
                                                16,
                                            fontWeight:
                                                FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // SECURITY CARD
                // ==================================================

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets
                          .all(
                    14,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF1F4F7,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration:
                            const BoxDecoration(
                          color:
                              Colors.white,
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons
                              .lock_outline_rounded,
                          color:
                              Color(
                            0xFF64748B,
                          ),
                          size: 18,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          'Your mobile number is securely '
                          'verified through Firebase. '
                          'Your Firebase UID remains '
                          'protected in the backend.',

                          style: TextStyle(
                            color:
                                Colors.grey
                                    .shade700,
                            fontSize: 11.5,
                            height: 1.45,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                // ==================================================
                // FIREBASE ERROR
                // ==================================================

                if (_firebaseError != null)
                  Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets
                            .all(
                      14,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.red.shade50,

                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),

                      border:
                          Border.all(
                        color:
                            Colors.red
                                .shade200,
                      ),
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Icon(
                          Icons
                              .error_outline_rounded,
                          color:
                              Colors.red
                                  .shade700,
                          size: 20,
                        ),

                        const SizedBox(
                          width: 9,
                        ),

                        Expanded(
                          child: Text(
                            _firebaseError!,
                            style: TextStyle(
                              fontSize:
                                  12,
                              color: Colors
                                  .red
                                  .shade800,
                              fontWeight:
                                  FontWeight.w600,
                              height:
                                  1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // FOOTER
                // ==================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    Icon(
                      Icons
                          .verified_user_outlined,
                      size: 15,
                      color:
                          Colors.grey
                              .shade500,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      'Secure Firebase verification',
                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade500,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DISPLAY PHONE
  // =====================================================

  String _displayPhoneNumber() {
    final String raw =
        widget.phoneNumber.trim();

    final String clean =
        raw.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length == 10) {
      return '+91 '
          '${clean.substring(0, 5)} '
          '${clean.substring(5)}';
    }

    if (clean.length >= 10) {
      final String last10 =
          clean.substring(
        clean.length - 10,
      );

      return '+91 '
          '${last10.substring(0, 5)} '
          '${last10.substring(5)}';
    }

    return raw.isEmpty
        ? 'Mobile number'
        : raw;
  }
}
