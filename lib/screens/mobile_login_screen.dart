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

  final AuthService _authService =
      AuthService.instance;

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

    await _authService.verifyPhoneNumber(
      phoneNumber: phone,

      // ========================================================
      // OTP SENT
      // ========================================================

      onCodeSent: (String verificationId) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                OtpVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phone,
            ),
          ),
        );
      },

      // ========================================================
      // ERROR
      // ========================================================

      onError: (String error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Verification failed.\n$error';
        });
      },
    );
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // ==================================================
                // LOGO
                // ==================================================

                const Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor:
                        AppColors.primary,
                    child: Icon(
                      Icons.pets_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Welcome to Dojo Walker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Verify your mobile number to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textGrey,
                  ),
                ),

                const SizedBox(height: 40),

                // ==================================================
                // CARD
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
                        spreadRadius: 1,
                        offset: Offset(0, 6),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Mobile Number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppColors.textGrey,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // PHONE
                      // ==================================================

                      TextField(
                        controller:
                            _phoneController,
                        keyboardType:
                            TextInputType.phone,
                        maxLength: 10,
                        enabled: !_isLoading,
                        onChanged: (_) {
                          if (_errorMessage
                              .isNotEmpty) {
                            setState(() {
                              _errorMessage = '';
                            });
                          }
                        },
                        decoration:
                            InputDecoration(
                          counterText: '',
                          hintText:
                              'Enter 10-digit number',
                          prefixText: '+91  ',
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
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(0xFFD9DDE2),
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
                                  AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // ==================================================
                      // ERROR
                      // ==================================================

                      if (_errorMessage
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ==================================================
                      // GET OTP
                      // ==================================================

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _sendOtp,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.primary,
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

                const SizedBox(height: 20),

                const Text(
                  'A verification code will be sent to your mobile number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
