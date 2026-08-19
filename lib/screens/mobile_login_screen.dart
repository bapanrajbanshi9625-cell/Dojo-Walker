// File location:
// lib/screens/mobile_login_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() =>
      _MobileLoginScreenState();
}

class _MobileLoginScreenState
    extends State<MobileLoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  String _errorMessage = '';

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
    if (_isLoading) {
      return;
    }

    final String phone =
        _phoneController.text.trim();

    // ==========================================================
    // VALIDATE PHONE
    // ==========================================================

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      setState(() {
        _errorMessage =
            'Please enter a valid 10-digit mobile number.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // ==========================================================
    // FIREBASE SEND OTP
    // ==========================================================

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phone,

        // ========================================================
        // OTP SENT
        // ========================================================

        onCodeSent: (
          String verificationId,
        ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isLoading = false;
            _errorMessage = '';
          });

          // ======================================================
          // OPEN OTP SCREEN
          //
          // IMPORTANT:
          // OTP screen is opened ONLY after Firebase confirms
          // that the verification code was sent.
          // ======================================================

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  OtpVerificationScreen(
                verificationId:
                    verificationId,
                phoneNumber: phone,
              ),
            ),
          );
        },

        // ========================================================
        // OTP SEND FAILED
        // ========================================================

        onError: (
          String error,
        ) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString();
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.scaffoldBackground,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // ==================================================
                // LOGO
                // ==================================================

                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset:
                              const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Dojo Walker - Buddy Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Enter your mobile number to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        AppColors.textGrey,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // ==================================================
                // LOGIN CARD
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset:
                            const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      // ============================================
                      // LABEL
                      // ============================================

                      const Text(
                        'Mobile Number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              AppColors.textDark,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ============================================
                      // PHONE FIELD
                      // ============================================

                      TextField(
                        controller:
                            _phoneController,
                        enabled: !_isLoading,
                        keyboardType:
                            TextInputType.phone,
                        textInputAction:
                            TextInputAction.done,
                        maxLength: 10,

                        onChanged: (_) {
                          if (_errorMessage
                              .isNotEmpty) {
                            setState(() {
                              _errorMessage =
                                  '';
                            });
                          }
                        },

                        onSubmitted: (_) {
                          if (!_isLoading) {
                            _sendOtp();
                          }
                        },

                        decoration:
                            InputDecoration(
                          counterText: '',
                          hintText:
                              'Enter mobile number',
                          hintStyle:
                              const TextStyle(
                            color:
                                AppColors.textGrey,
                            fontSize: 14,
                          ),

                          prefixIcon:
                              Container(
                            width: 70,
                            alignment:
                                Alignment.center,
                            child:
                                const Text(
                              '+91',
                              style:
                                  TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    AppColors.textDark,
                              ),
                            ),
                          ),

                          filled: true,
                          fillColor:
                              const Color(
                            0xFFF8FAFC,
                          ),

                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color: Color(
                                0xFFD5D9DE,
                              ),
                            ),
                          ),

                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color: Color(
                                0xFFD5D9DE,
                              ),
                            ),
                          ),

                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  AppColors
                                      .primary,
                              width: 1.5,
                            ),
                          ),

                          disabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color: Color(
                                0xFFE2E5E9,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ============================================
                      // ERROR
                      // ============================================

                      if (_errorMessage
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 12,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.red
                                    .withValues(
                              alpha: 0.07,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Icon(
                                Icons
                                    .error_outline_rounded,
                                color:
                                    Colors.red,
                                size: 19,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.red,
                                    fontSize:
                                        13,
                                    height:
                                        1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ============================================
                      // GET OTP BUTTON
                      // ============================================

                      SizedBox(
                        height: 52,
                        child:
                            ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _sendOtp,

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                AppColors
                                    .primary,
                            disabledBackgroundColor:
                                Colors.grey
                                    .shade400,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
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
                                  : const Text(
                                      'Get Mobile OTP',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // INFORMATION
                // ==================================================

                const Text(
                  'A 6-digit verification code will be sent '
                  'to your mobile number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color:
                        AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
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
    _phoneController.dispose();
    super.dispose();
  }
}
