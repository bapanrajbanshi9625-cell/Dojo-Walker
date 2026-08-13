// File location: lib/screens/mobile_login_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  // =====================================================
  // SEND OTP
  // =====================================================

  Future<void> _sendOtp() async {
    final String phone =
        _phoneController.text.trim();

    if (phone.length != 10) {
      _showMessage(
        'Please enter a valid 10-digit mobile number.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _authService.verifyPhoneNumber(
      phoneNumber: phone,

      // =================================================
      // OTP SENT
      // =================================================

      onCodeSent: (String verificationId) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        // =================================================
        // OPEN OTP VERIFICATION SCREEN
        // =================================================

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OtpVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phone,
            ),
          ),
        );
      },

      // =================================================
      // ERROR
      // =================================================

      onError: (String error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        _showMessage(
          'Verification Failed: $error',
        );
      },
    );
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
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.scaffoldBackground,

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // LOGO
                  // =================================================

                  const Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          AppColors.primary,
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // TITLE
                  // =================================================

                  const Center(
                    child: Text(
                      'Dojo Walker - Buddy Login',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Center(
                    child: Text(
                      'Enter your mobile number to continue',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            AppColors.textGrey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // MOBILE NUMBER LABEL
                  // =================================================

                  const Text(
                    'Mobile Number',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                      color:
                          AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // =================================================
                  // MOBILE NUMBER
                  // =================================================

                  TextField(
                    controller:
                        _phoneController,
                    keyboardType:
                        TextInputType.phone,
                    maxLength: 10,
                    enabled:
                        !_isLoading,
                    decoration:
                        InputDecoration(
                      prefixText: '+91 ',
                      hintText:
                          'Enter mobile number',
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
                              Color(0xFFD5D9DE),
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
                      filled: true,
                      fillColor:
                          Colors.white,
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // GET OTP BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child:
                        ElevatedButton(
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
                      onPressed:
                          _isLoading
                              ? null
                              : _sendOtp,
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
                                fontWeight:
                                    FontWeight.bold,
                                fontSize:
                                    16,
                              ),
                            ),
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
