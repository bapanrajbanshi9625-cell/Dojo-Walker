import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/presentation/profile_setup_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;

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
                    onPressed: () {
                      if (!_isOtpSent) {
                        if (_phoneController.text.length == 10) {
                          setState(() => _isOtpSent = true);
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MandatoryProfileSetupScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter valid 6-digit OTP'),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
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
