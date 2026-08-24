import 'package:flutter/material.dart';

class DojoWalkerColors {
  DojoWalkerColors._();

  // ==========================================================
  // BRAND — 30%
  // ==========================================================

  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFE95720);
  static const Color primaryLight = Color(0xFFFF8A5B);

  // ==========================================================
  // SECONDARY — 20%
  // ==========================================================

  static const Color secondary = Color(0xFF58D6B0);
  static const Color secondaryDark = Color(0xFF32B993);
  static const Color secondaryLight = Color(0xFF8AE7CD);

  // ==========================================================
  // SUPPORTING — 30%
  // ==========================================================

  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFB);

  static const Color textPrimary = Color(0xFF17212B);
  static const Color textSecondary = Color(0xFF68727D);
  static const Color textMuted = Color(0xFF9AA3AC);

  static const Color border = Color(0xFFE1E6EA);
  static const Color borderStrong = Color(0xFFCBD2D8);
  static const Color divider = Color(0xFFE8ECEF);

  // ==========================================================
  // RAINBOW ACCENTS — 70% VISUAL ACCENT SYSTEM
  // ==========================================================

  static const Color rainbowRed = Color(0xFFFF4D6D);
  static const Color rainbowOrange = Color(0xFFFF8A34);
  static const Color rainbowYellow = Color(0xFFFFC857);
  static const Color rainbowGreen = Color(0xFF42C98A);
  static const Color rainbowBlue = Color(0xFF4D9DE0);
  static const Color rainbowPurple = Color(0xFF9B6DFF);
  static const Color rainbowPink = Color(0xFFFF6FB5);

  static const List<Color> rainbow = [
    rainbowRed,
    rainbowOrange,
    rainbowYellow,
    rainbowGreen,
    rainbowBlue,
    rainbowPurple,
    rainbowPink,
  ];

  // ==========================================================
  // STATUS
  // ==========================================================

  static const Color success = Color(0xFF20B26B);
  static const Color successSoft = Color(0xFFE8F8F0);

  static const Color warning = Color(0xFFF5A623);
  static const Color warningSoft = Color(0xFFFFF5E2);

  static const Color error = Color(0xFFE94B5F);
  static const Color errorSoft = Color(0xFFFFEBEE);

  static const Color info = Color(0xFF4385E5);
  static const Color infoSoft = Color(0xFFEAF2FF);

  // ==========================================================
  // ICONS
  // ==========================================================

  static const Color iconPrimary = textPrimary;
  static const Color iconSecondary = textSecondary;
  static const Color iconMuted = textMuted;
  static const Color iconOnPrimary = Colors.white;

  // ==========================================================
  // BUTTONS — STRONGER COLORS
  // ==========================================================

  static const Color buttonPrimary = primary;
  static const Color buttonPrimaryPressed = primaryDark;
  static const Color buttonSecondary = secondary;
  static const Color buttonSecondaryPressed = secondaryDark;

  static const Color buttonText = Colors.white;

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  static const Color bottomBar = Colors.white;
  static const Color bottomBarBorder = border;

  static const Color navSelected = primary;
  static const Color navUnselected = textMuted;

  // ==========================================================
  // OVERLAY
  // ==========================================================

  static const Color overlay = Color(0x66000000);
}
