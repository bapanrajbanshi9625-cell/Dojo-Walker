// File location: lib/screens/mobile_login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import 'profile_setup_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  String _verificationId = '';

  Future<void> _handleVerifyPhoneNumber() async {
    setState(() => _isLoading = true);

    await _authService.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!')),
        );
      },
      onError: (error) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: $error')),
        );
      },
    );
  }

  Future<void> _handleVerifyOTP() async {
    setState(() => _isLoading = true);

    bool success = await _authService.verifyOTP(
      verificationId: _verificationId,
      smsCode: _otpController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MandatoryProfileSetupScreen(),
        ),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.pets, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Dojo Walker - Buddy Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Enter your mobile number to continue',
                    style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    prefixText: '+91 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                  ),
                ),
                if (_isOtpSent) ...[
                  const SizedBox(height: 15),
                  const Text(
                    'Enter 6-Digit OTP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '123456',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (!_isOtpSent) {
                              if (_phoneController.text.length == 10) {
                                _handleVerifyPhoneNumber();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid 10-digit mobile number',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (_otpController.text.length == 6) {
                                _handleVerifyOTP();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter valid 6-digit OTP'),
                                  ),
                                );
                              }
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isOtpSent ? 'Verify OTP & Login' : 'Get Mobile OTP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
