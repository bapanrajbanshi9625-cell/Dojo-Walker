// File:
// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==========================================================
  // PRIMARY BRAND — ORANGE
  // ==========================================================

  /// Main Dojo brand color
  static const Color primary = Color(0xFFFF5A3B);

  /// Dark orange for pressed / deeper brand states
  static const Color primaryDark = Color(0xFFE6452A);

  /// Light orange for soft brand states
  static const Color primaryLight = Color(0xFFFF8A70);

  /// Compatibility alias
  static const Color orange = primary;

  /// Soft orange background
  static const Color orangeSoft = Color(0xFFFFF1ED);

  /// Orange border
  static const Color orangeBorder = Color(0xFFFFD5CC);

  // ==========================================================
  // SECONDARY BRAND — ELECTRIC CYAN
  // ==========================================================

  /// Electric Cyan
  static const Color secondary = Color(0xFF06B6D4);

  /// Dark cyan
  static const Color secondaryDark = Color(0xFF0891B2);

  /// Light cyan
  static const Color secondaryLight = Color(0xFF67E8F9);

  /// Compatibility alias
  static const Color cyan = secondary;

  /// Soft cyan background
  static const Color cyanSoft = Color(0xFFE6F9FC);

  // ==========================================================
  // HERO / DARK BRAND
  // ==========================================================

  /// Obsidian Slate
  static const Color hero = Color(0xFF0F172A);

  /// Midnight Slate
  static const Color heroDark = Color(0xFF020617);

  /// Slate banner secondary
  static const Color heroLight = Color(0xFF1E293B);

  /// Compatibility aliases
  static const Color obsidian = hero;

  static const Color midnight = heroDark;

  static const Color darkSlate = heroLight;

  // ==========================================================
  // CTA — EMERALD GREEN
  // ==========================================================

  /// Main CTA / Search / Next
  static const Color buttonPrimary = Color(0xFF10B981);

  /// Pressed CTA
  static const Color buttonPrimaryPressed = Color(0xFF059669);

  /// Soft CTA background
  static const Color buttonPrimarySoft = Color(0xFFECFDF5);

  /// Secondary CTA
  static const Color buttonSecondary = secondary;

  /// Secondary CTA pressed
  static const Color buttonSecondaryPressed = secondaryDark;

  /// Text on colored buttons
  static const Color buttonText = Colors.white;

  /// Compatibility aliases
  static const Color green = buttonPrimary;

  static const Color greenDark = buttonPrimaryPressed;

  static const Color greenSoft = buttonPrimarySoft;

  // ==========================================================
  // BACKGROUND
  // ==========================================================

  /// Ice White
  static const Color background = Color(0xFFF8FAFC);

  /// Main scaffold background
  static const Color scaffoldBackground = background;

  /// White cards
  static const Color surface = Color(0xFFFFFFFF);

  static const Color cardBackground = surface;

  /// Slightly darker soft surface
  static const Color surfaceSoft = Color(0xFFF1F5F9);

  /// Very soft surface
  static const Color surfaceMuted = Color(0xFFEFF3F7);

  // ==========================================================
  // TEXT
  // ==========================================================

  /// Main text
  static const Color textPrimary = Color(0xFF0F172A);

  /// Compatibility alias
  static const Color textDark = textPrimary;

  /// Secondary text
  static const Color textSecondary = Color(0xFF475569);

  /// Compatibility alias
  static const Color textGrey = textSecondary;

  /// Muted text
  static const Color textMuted = Color(0xFF94A3B8);

  /// Compatibility alias
  static const Color muted = textMuted;

  /// Text on dark hero
  static const Color textOnDark = Color(0xFFF8FAFC);

  /// Text on primary brand color
  static const Color textOnPrimary = Colors.white;

  /// Compatibility alias used by existing screens
  static const Color onPrimary = Colors.white;

  // ==========================================================
  // BORDERS / DIVIDERS
  // ==========================================================

  static const Color border = Color(0xFFE2E8F0);

  static const Color borderStrong = Color(0xFFCBD5E1);

  static const Color borderLight = Color(0xFFF1F5F9);

  static const Color divider = Color(0xFFE2E8F0);

  // ==========================================================
  // ICONS
  // ==========================================================

  static const Color iconPrimary = Color(0xFF0F172A);

  static const Color iconSecondary = Color(0xFF475569);

  static const Color iconMuted = Color(0xFF94A3B8);

  static const Color iconOnPrimary = Colors.white;

  /// Brand icon
  static const Color iconBrand = primary;

  /// Active icon
  static const Color iconActive = secondary;

  // ==========================================================
  // STATUS — SUCCESS
  // ==========================================================

  static const Color success = Color(0xFF10B981);

  static const Color successDark = Color(0xFF047857);

  static const Color successSoft = Color(0xFFECFDF5);

  // ==========================================================
  // STATUS — WARNING
  // ==========================================================

  static const Color warning = Color(0xFFF59E0B);

  static const Color warningDark = Color(0xFFD97706);

  static const Color warningSoft = Color(0xFFFFFBEB);

  // ==========================================================
  // STATUS — ERROR
  // ==========================================================

  static const Color error = Color(0xFFEF4444);

  static const Color errorDark = Color(0xFFDC2626);

  static const Color errorSoft = Color(0xFFFEF2F2);

  /// Compatibility alias
  static const Color red = error;

  static const Color redSoft = errorSoft;

  // ==========================================================
  // STATUS — INFO
  // ==========================================================

  static const Color info = Color(0xFF06B6D4);

  static const Color infoDark = Color(0xFF0891B2);

  static const Color infoSoft = Color(0xFFECFEFF);

  /// Compatibility aliases
  static const Color blue = info;

  static const Color blueDark = infoDark;

  static const Color blueSoft = infoSoft;

  // ==========================================================
  // SPECIAL PET / WALK COLORS
  // ==========================================================

  /// Insta Walk active glow
  static const Color instaWalk = Color(0xFF06B6D4);

  static const Color instaWalkSoft = Color(0xFFE6F9FC);

  /// Live walk
  static const Color liveWalk = Color(0xFF10B981);

  static const Color liveWalkSoft = Color(0xFFECFDF5);

  /// Location
  static const Color location = Color(0xFF06B6D4);

  /// Dog / pet accent
  static const Color pet = Color(0xFFFF5A3B);

  static const Color petSoft = Color(0xFFFFF1ED);

  /// Verification
  static const Color verification = Color(0xFF10B981);

  /// Pending
  static const Color pending = Color(0xFFF59E0B);

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  static const Color bottomBar = Colors.white;

  static const Color bottomBarBorder = Color(0xFFE2E8F0);

  /// Selected bottom navigation item
  static const Color navSelected = primary;

  /// Unselected bottom navigation item
  static const Color navUnselected = Color(0xFF94A3B8);

  // ==========================================================
  // OVERLAY
  // ==========================================================

  static const Color overlay = Color(0x660F172A);

  static const Color overlayLight = Color(0x330F172A);

  // ==========================================================
  // DARK CARD GRADIENT
  // ==========================================================

  /// Premium dark hero gradient start
  static const Color gradientStart = Color(0xFF0F172A);

  /// Premium dark hero gradient end
  static const Color gradientEnd = Color(0xFF1E293B);

  // ==========================================================
  // GLOW
  // ==========================================================

  /// Insta Walk / active cyan glow
  static const Color glowCyan = Color(0xFF06B6D4);

  /// Brand orange glow
  static const Color glowOrange = Color(0xFFFF5A3B);

  /// CTA green glow
  static const Color glowGreen = Color(0xFF10B981);

  // ==========================================================
  // RAINBOW
  // ==========================================================

  static const Color rainbowRed = Color(0xFFEF4444);

  static const Color rainbowOrange = Color(0xFFFF5A3B);

  static const Color rainbowYellow = Color(0xFFF59E0B);

  static const Color rainbowGreen = Color(0xFF10B981);

  static const Color rainbowBlue = Color(0xFF06B6D4);

  static const Color rainbowPurple = Color(0xFF8B5CF6);

  static const Color rainbowPink = Color(0xFFEC4899);

  static const List<Color> rainbow = <Color>[
    rainbowRed,
    rainbowOrange,
    rainbowYellow,
    rainbowGreen,
    rainbowBlue,
    rainbowPurple,
    rainbowPink,
  ];

  // ==========================================================
  // COMMON GRADIENTS
  // ==========================================================

  /// Premium dark hero gradient
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      hero,
      heroLight,
    ],
  );

  /// Orange brand gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      primary,
      primaryDark,
    ],
  );

  /// Insta Walk cyan gradient
  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      secondary,
      secondaryDark,
    ],
  );

  /// CTA green gradient
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      buttonPrimary,
      buttonPrimaryPressed,
    ],
  );
}
