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
/// Pending Verification
///
/// This screen is only an entry point.
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
