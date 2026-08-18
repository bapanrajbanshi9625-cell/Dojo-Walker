import 'package:flutter/material.dart';

import '../features/profile_setup/screens/mandatory_profile_setup_screen1.dart';

/// ===============================================================
/// MANDATORY PROFILE SETUP SCREEN
/// ===============================================================
///
/// Entry point for Walker mandatory profile setup.
///
/// Flow:
///
/// Login
///   ↓
/// MandatoryProfileSetupScreen
///   ↓
/// MandatoryProfileSetupScreen1
///   ↓
/// MandatoryProfileSetupScreen2
///   ↓
/// Aadhaar Verification
///   ↓
/// Profile Save
///   ↓
/// Main Navigation / Pending Verification
///
/// IMPORTANT:
/// ---------------------------------------------------------------
/// Screen 1 and Screen 2 are responsible for their own state.
///
/// This file must NOT create:
/// - PageController
/// - TextEditingController
/// - ImagePicker
/// - FirebaseAuth logic
/// - Aadhaar verification logic
/// - Profile save logic
///
/// Keeping this file as a simple entry point prevents:
/// - duplicate controllers
/// - duplicate PageView
/// - duplicate Firebase calls
/// - constructor mismatch errors
/// - state synchronization problems
/// ===============================================================

class MandatoryProfileSetupScreen extends StatelessWidget {
  const MandatoryProfileSetupScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const MandatoryProfileSetupScreen1();
  }
}
