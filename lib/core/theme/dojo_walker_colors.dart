// File location:
// lib/core/theme/colors/dojo_walker_colors.dart

import 'package:flutter/material.dart';

class DojoWalkerColors {
  DojoWalkerColors._();

  // ==========================================================
  // BRAND
  // ==========================================================

  /// Primary Dojo orange
  static const Color primary =
      Color(0xFFFF7A00);

  /// Darker orange for pressed / deep brand states
  static const Color primaryDark =
      Color(0xFFE85D00);

  /// Soft orange for light backgrounds / highlights
  static const Color primaryLight =
      Color(0xFFFFB067);

  /// Compatibility alias for soft primary
  static const Color primarySoft =
      primaryLight;

  /// Secondary brand color
  static const Color secondary =
      Color(0xFF0E7490);

  static const Color secondaryDark =
      Color(0xFF0A5C70);

  static const Color secondaryLight =
      Color(0xFF38BDF8);

  // ==========================================================
  // BASIC
  // ==========================================================

  /// Pure white
  static const Color white =
      Colors.white;

  /// Pure black
  static const Color black =
      Colors.black;

  // ==========================================================
  // HERO / DARK BRAND
  // ==========================================================

  /// Premium dark hero background
  static const Color hero =
      Color(0xFF0A252C);

  /// Compatibility alias for dark hero
  static const Color heroDark =
      hero;

  /// Dark slate
  static const Color slate =
      Color(0xFF0F172A);

  /// Midnight slate
  static const Color midnight =
      Color(0xFF1E293B);

  /// Deepest dark
  static const Color obsidian =
      Color(0xFF08141A);

  // ==========================================================
  // ACTIVE / GLOW
  // ==========================================================

  /// Neon mint / active state
  static const Color active =
      Color(0xFF2DD4BF);

  /// Aqua glow
  static const Color glow =
      Color(0xFF06B6D4);

  /// Compatibility alias for cyan
  static const Color cyan =
      glow;

  /// Soft sky aqua
  static const Color aqua =
      Color(0xFF38BDF8);

  /// Light active background
  static const Color activeSoft =
      Color(0xFFE6FFFB);

  /// Cyan soft background
  static const Color glowSoft =
      Color(0xFFE6F9FC);

  // ==========================================================
  // CTA / ACTION
  // ==========================================================

  /// Main CTA green
  static const Color buttonPrimary =
      Color(0xFF15803D);

  /// Pressed CTA green
  static const Color buttonPrimaryPressed =
      Color(0xFF166534);

  /// Secondary CTA
  static const Color buttonSecondary =
      Color(0xFF0E7490);

  /// Secondary pressed state
  static const Color buttonSecondaryPressed =
      Color(0xFF155E75);

  /// Text displayed on CTA buttons
  static const Color buttonText =
      Colors.white;

  // ==========================================================
  // SUCCESS
  // ==========================================================

  static const Color success =
      Color(0xFF15803D);

  static const Color successSoft =
      Color(0xFFDCFCE7);

  static const Color successDark =
      Color(0xFF166534);

  // ==========================================================
  // WARNING
  // ==========================================================

  static const Color warning =
      Color(0xFFF59E0B);

  static const Color warningSoft =
      Color(0xFFFEF3C7);

  static const Color warningDark =
      Color(0xFFB45309);

  // ==========================================================
  // ERROR
  // ==========================================================

  static const Color error =
      Color(0xFFDC2626);

  static const Color errorSoft =
      Color(0xFFFEE2E2);

  static const Color errorDark =
      Color(0xFFB91C1C);

  // ==========================================================
  // INFO
  // ==========================================================

  static const Color info =
      Color(0xFF06B6D4);

  static const Color infoSoft =
      Color(0xFFCFFAFE);

  static const Color infoDark =
      Color(0xFF0E7490);

  // ==========================================================
  // BACKGROUND
  // ==========================================================

  /// Main app background
  static const Color background =
      Color(0xFFF1F5F9);

  /// Premium white surface
  static const Color surface =
      Color(0xFFFFFFFF);

  /// Slightly softer surface
  static const Color surfaceSoft =
      Color(0xFFF8FAFC);

  /// Warm white for premium sections
  static const Color surfaceWarm =
      Color(0xFFFAF9F6);

  // ==========================================================
  // TEXT
  // ==========================================================

  /// Main heading / important text
  static const Color textPrimary =
      Color(0xFF0F172A);

  /// Normal body text
  static const Color textSecondary =
      Color(0xFF475569);

  /// Muted / helper text
  static const Color textMuted =
      Color(0xFF94A3B8);

  /// Very light text
  static const Color textLight =
      Color(0xFFCBD5E1);

  /// Text on dark hero cards
  static const Color textOnDark =
      Color(0xFFF8FAFC);

  /// Text on orange / colored surfaces
  static const Color textOnPrimary =
      Colors.white;

  // ==========================================================
  // BORDER
  // ==========================================================

  static const Color border =
      Color(0xFFE2E8F0);

  static const Color borderStrong =
      Color(0xFFCBD5E1);

  /// Compatibility alias for medium border
  static const Color borderMedium =
      borderStrong;

  static const Color borderLight =
      Color(0xFFF1F5F9);

  static const Color divider =
      Color(0xFFE2E8F0);

  // ==========================================================
  // ICONS
  // ==========================================================

  static const Color iconPrimary =
      Color(0xFF0F172A);

  static const Color iconSecondary =
      Color(0xFF475569);

  static const Color iconMuted =
      Color(0xFF94A3B8);

  static const Color iconOnPrimary =
      Colors.white;

  static const Color iconOrange =
      Color(0xFFFF7A00);

  static const Color iconGreen =
      Color(0xFF15803D);

  static const Color iconBlue =
      Color(0xFF06B6D4);

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  static const Color bottomBar =
      Colors.white;

  static const Color bottomBarBorder =
      Color(0xFFE2E8F0);

  static const Color navSelected =
      Color(0xFFFF7A00);

  static const Color navUnselected =
      Color(0xFF94A3B8);

  // ==========================================================
  // CARDS
  // ==========================================================

  static const Color card =
      Colors.white;

  static const Color cardBorder =
      Color(0xFFE2E8F0);

  static const Color cardDark =
      Color(0xFF0F172A);

  static const Color cardDarkSecondary =
      Color(0xFF1E293B);

  static const Color cardOrange =
      Color(0xFFFF7A00);

  static const Color cardGreen =
      Color(0xFF15803D);

  static const Color cardBlue =
      Color(0xFF0E7490);

  // ==========================================================
  // INPUT FIELDS
  // ==========================================================

  static const Color inputBackground =
      Colors.white;

  static const Color inputBorder =
      Color(0xFFE2E8F0);

  static const Color inputFocusedBorder =
      Color(0xFFFF7A00);

  static const Color inputErrorBorder =
      Color(0xFFDC2626);

  static const Color inputHint =
      Color(0xFF94A3B8);

  // ==========================================================
  // OVERLAY
  // ==========================================================

  static const Color overlay =
      Color(0x66000000);

  static const Color darkOverlay =
      Color(0x99000000);

  // ==========================================================
  // DISABLED
  // ==========================================================

  static const Color disabled =
      Color(0xFFE2E8F0);

  static const Color disabledText =
      Color(0xFF94A3B8);

  // ==========================================================
  // RAINBOW
  // ==========================================================

  static const Color rainbowRed =
      Color(0xFFEF4444);

  static const Color rainbowOrange =
      Color(0xFFFF7A00);

  static const Color rainbowYellow =
      Color(0xFFFACC15);

  static const Color rainbowGreen =
      Color(0xFF22C55E);

  static const Color rainbowBlue =
      Color(0xFF06B6D4);

  static const Color rainbowPurple =
      Color(0xFF8B5CF6);

  static const Color rainbowPink =
      Color(0xFFEC4899);

  static const List<Color> rainbow =
      <Color>[
    rainbowRed,
    rainbowOrange,
    rainbowYellow,
    rainbowGreen,
    rainbowBlue,
    rainbowPurple,
    rainbowPink,
  ];

  // ==========================================================
  // GRADIENTS
  // ==========================================================

  /// Premium hero gradient
  static const LinearGradient heroGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF0F172A),
      Color(0xFF1E293B),
    ],
  );

  /// Orange brand gradient
  static const LinearGradient orangeGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFF7A00),
      Color(0xFFE85D00),
    ],
  );

  /// Active cyan gradient
  static const LinearGradient cyanGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF06B6D4),
      Color(0xFF2DD4BF),
    ],
  );

  /// CTA green gradient
  static const LinearGradient greenGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF15803D),
      Color(0xFF166534),
    ],
  );

  /// Premium dark-to-black gradient
  static const LinearGradient darkGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF0F172A),
      Color(0xFF08141A),
    ],
  );

  // ==========================================================
  // SHADOW COLORS
  // ==========================================================

  static const Color shadow =
      Color(0x240F172A);

  static const Color orangeShadow =
      Color(0x40FF7A00);

  static const Color cyanShadow =
      Color(0x4006B6D4);

  static const Color greenShadow =
      Color(0x4015803D);
}
