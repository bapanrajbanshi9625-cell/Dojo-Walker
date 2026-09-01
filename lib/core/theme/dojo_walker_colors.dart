import 'package:flutter/material.dart';

/// ===============================================================
/// DOJO WALKER COLOR SYSTEM
/// ===============================================================
///
/// Central color system for Dojo Walker.
///
/// IMPORTANT:
/// Existing screens may use either:
///   DojoWalkerColors
///   DojoColors
///
/// DojoColors is kept as a compatibility alias so old screens
/// continue to compile while the new design system uses
/// DojoWalkerColors.
///

class DojoWalkerColors {
  DojoWalkerColors._();

  // ===============================================================
  // BRAND
  // ===============================================================

  static const Color primary = Color(0xFFFF7A00);
  static const Color primaryDark = Color(0xFFE85D00);
  static const Color primaryLight = Color(0xFFFFB067);
  static const Color primarySoft = Color(0xFFFFE8D2);

  static const Color secondary = Color(0xFF0E7490);
  static const Color secondaryDark = Color(0xFF0A5C70);
  static const Color secondaryLight = Color(0xFF38BDF8);

  // ===============================================================
  // BASIC
  // ===============================================================

  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // ===============================================================
  // DARK / HERO
  // ===============================================================

  static const Color hero = Color(0xFF0A252C);
  static const Color heroDark = hero;
  static const Color slate = Color(0xFF0F172A);
  static const Color midnight = Color(0xFF1E293B);
  static const Color obsidian = Color(0xFF08141A);

  // ===============================================================
  // ACTIVE / GLOW
  // ===============================================================

  static const Color active = Color(0xFF2DD4BF);
  static const Color glow = Color(0xFF06B6D4);
  static const Color cyan = glow;
  static const Color aqua = Color(0xFF38BDF8);

  static const Color activeSoft = Color(0xFFE6FFFB);
  static const Color glowSoft = Color(0xFFE6F9FC);

  // ===============================================================
  // SUCCESS / GREEN
  // ===============================================================

  static const Color green = Color(0xFF15803D);
  static const Color greenDark = Color(0xFF166534);
  static const Color greenLight = Color(0xFFDCFCE7);
  static const Color greenSoft = Color(0xFFDCFCE7);

  static const Color success = green;
  static const Color successDark = greenDark;
  static const Color successSoft = greenLight;

  // ===============================================================
  // CTA
  // ===============================================================

  static const Color buttonPrimary = Color(0xFF15803D);
  static const Color buttonPrimaryPressed = Color(0xFF166534);

  static const Color buttonSecondary = Color(0xFF0E7490);
  static const Color buttonSecondaryPressed = Color(0xFF155E75);

  static const Color buttonText = Colors.white;

  // ===============================================================
  // WARNING
  // ===============================================================

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  // ===============================================================
  // ERROR
  // ===============================================================

  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  // ===============================================================
  // INFO / BLUE
  // ===============================================================

  static const Color info = Color(0xFF06B6D4);
  static const Color infoSoft = Color(0xFFCFFAFE);
  static const Color infoDark = Color(0xFF0E7490);

  static const Color blue = Color(0xFF0E7490);
  static const Color blueLight = Color(0xFFCFFAFE);
  static const Color blueSoft = Color(0xFFCFFAFE);

  // ===============================================================
  // BACKGROUND
  // ===============================================================

  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFC);
  static const Color surfaceWarm = Color(0xFFFAF9F6);

  // ===============================================================
  // TEXT
  // ===============================================================

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFCBD5E1);

  static const Color textOnDark = Color(0xFFF8FAFC);
  static const Color textOnPrimary = Colors.white;

  // ===============================================================
  // BORDER
  // ===============================================================

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color borderMedium = borderStrong;
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // ===============================================================
  // ICONS
  // ===============================================================

  static const Color iconPrimary = Color(0xFF0F172A);
  static const Color iconSecondary = Color(0xFF475569);
  static const Color iconMuted = Color(0xFF94A3B8);
  static const Color iconOnPrimary = Colors.white;
  static const Color iconOrange = Color(0xFFFF7A00);
  static const Color iconGreen = Color(0xFF15803D);
  static const Color iconBlue = Color(0xFF06B6D4);

  // ===============================================================
  // NAVIGATION
  // ===============================================================

  static const Color bottomBar = Colors.white;
  static const Color bottomBarBorder = Color(0xFFE2E8F0);
  static const Color navSelected = Color(0xFFFF7A00);
  static const Color navUnselected = Color(0xFF94A3B8);

  // ===============================================================
  // CARDS
  // ===============================================================

  static const Color card = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  static const Color cardDark = Color(0xFF0F172A);
  static const Color cardDarkSecondary = Color(0xFF1E293B);

  static const Color cardOrange = Color(0xFFFF7A00);
  static const Color cardGreen = Color(0xFF15803D);
  static const Color cardBlue = Color(0xFF0E7490);

  // ===============================================================
  // INPUT
  // ===============================================================

  static const Color inputBackground = Colors.white;
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFocusedBorder = Color(0xFFFF7A00);
  static const Color inputErrorBorder = Color(0xFFDC2626);
  static const Color inputHint = Color(0xFF94A3B8);

  // ===============================================================
  // OVERLAY
  // ===============================================================

  static const Color overlay = Color(0x66000000);
  static const Color darkOverlay = Color(0x99000000);

  // ===============================================================
  // DISABLED
  // ===============================================================

  static const Color disabled = Color(0xFFE2E8F0);
  static const Color disabledText = Color(0xFF94A3B8);

  // ===============================================================
  // RAINBOW
  // ===============================================================

  static const Color rainbowRed = Color(0xFFEF4444);
  static const Color rainbowOrange = Color(0xFFFF7A00);
  static const Color rainbowYellow = Color(0xFFFACC15);
  static const Color rainbowGreen = Color(0xFF22C55E);
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

  // ===============================================================
  // GRADIENTS
  // ===============================================================

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF0F172A),
      Color(0xFF1E293B),
    ],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFF7A00),
      Color(0xFFE85D00),
    ],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF06B6D4),
      Color(0xFF2DD4BF),
    ],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF15803D),
      Color(0xFF166534),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF0F172A),
      Color(0xFF08141A),
    ],
  );

  // ===============================================================
  // SHADOWS
  // ===============================================================

  static const Color shadow = Color(0x240F172A);
  static const Color orangeShadow = Color(0x40FF7A00);
  static const Color cyanShadow = Color(0x4006B6D4);
  static const Color greenShadow = Color(0x4015803D);
}


/// ===============================================================
/// DOJO COLORS — COMPATIBILITY ALIAS
/// ===============================================================
///
/// Existing Walker screens use:
///
///   DojoColors.orange
///   DojoColors.green
///   DojoColors.greenLight
///   DojoColors.background
///   DojoColors.textPrimary
///
/// Keep this class so existing files do not need to be rewritten
/// immediately.
///

class DojoColors {
  DojoColors._();

  // ===============================================================
  // BRAND
  // ===============================================================

  static const Color orange = DojoWalkerColors.primary;
  static const Color orangeDark = DojoWalkerColors.primaryDark;
  static const Color orangeLight = DojoWalkerColors.primaryLight;
  static const Color orangeSoft = DojoWalkerColors.primarySoft;

  static const Color primary = DojoWalkerColors.primary;
  static const Color primaryDark = DojoWalkerColors.primaryDark;
  static const Color primaryLight = DojoWalkerColors.primaryLight;
  static const Color primarySoft = DojoWalkerColors.primarySoft;

  static const Color secondary = DojoWalkerColors.secondary;
  static const Color secondaryDark = DojoWalkerColors.secondaryDark;
  static const Color secondaryLight = DojoWalkerColors.secondaryLight;

  // ===============================================================
  // BASIC
  // ===============================================================

  static const Color white = DojoWalkerColors.white;
  static const Color black = DojoWalkerColors.black;

  // ===============================================================
  // DARK
  // ===============================================================

  static const Color dark = DojoWalkerColors.slate;
  static const Color hero = DojoWalkerColors.hero;
  static const Color heroDark = DojoWalkerColors.heroDark;
  static const Color slate = DojoWalkerColors.slate;
  static const Color midnight = DojoWalkerColors.midnight;
  static const Color obsidian = DojoWalkerColors.obsidian;

  // ===============================================================
  // ACTIVE / GLOW
  // ===============================================================

  static const Color active = DojoWalkerColors.active;
  static const Color glow = DojoWalkerColors.glow;
  static const Color cyan = DojoWalkerColors.cyan;
  static const Color aqua = DojoWalkerColors.aqua;

  static const Color activeSoft = DojoWalkerColors.activeSoft;
  static const Color glowSoft = DojoWalkerColors.glowSoft;

  // ===============================================================
  // GREEN / SUCCESS
  // ===============================================================

  static const Color green = DojoWalkerColors.green;
  static const Color greenDark = DojoWalkerColors.greenDark;
  static const Color greenLight = DojoWalkerColors.greenLight;
  static const Color greenSoft = DojoWalkerColors.greenSoft;

  static const Color success = DojoWalkerColors.success;
  static const Color successDark = DojoWalkerColors.successDark;
  static const Color successSoft = DojoWalkerColors.successSoft;

  // ===============================================================
  // WARNING
  // ===============================================================

  static const Color warning = DojoWalkerColors.warning;
  static const Color warningSoft = DojoWalkerColors.warningSoft;
  static const Color warningDark = DojoWalkerColors.warningDark;

  // ===============================================================
  // ERROR
  // ===============================================================

  static const Color error = DojoWalkerColors.error;
  static const Color errorSoft = DojoWalkerColors.errorSoft;
  static const Color errorDark = DojoWalkerColors.errorDark;

  // ===============================================================
  // INFO / BLUE
  // ===============================================================

  static const Color info = DojoWalkerColors.info;
  static const Color infoSoft = DojoWalkerColors.infoSoft;
  static const Color infoDark = DojoWalkerColors.infoDark;

  static const Color blue = DojoWalkerColors.blue;
  static const Color blueLight = DojoWalkerColors.blueLight;
  static const Color blueSoft = DojoWalkerColors.blueSoft;

  // ===============================================================
  // CTA
  // ===============================================================

  static const Color buttonPrimary = DojoWalkerColors.buttonPrimary;
  static const Color buttonPrimaryPressed =
      DojoWalkerColors.buttonPrimaryPressed;

  static const Color buttonSecondary =
      DojoWalkerColors.buttonSecondary;

  static const Color buttonSecondaryPressed =
      DojoWalkerColors.buttonSecondaryPressed;

  static const Color buttonText = DojoWalkerColors.buttonText;

  // ===============================================================
  // BACKGROUND
  // ===============================================================

  static const Color background = DojoWalkerColors.background;
  static const Color surface = DojoWalkerColors.surface;
  static const Color surfaceSoft = DojoWalkerColors.surfaceSoft;
  static const Color surfaceWarm = DojoWalkerColors.surfaceWarm;

  // ===============================================================
  // TEXT
  // ===============================================================

  static const Color textPrimary = DojoWalkerColors.textPrimary;
  static const Color textSecondary = DojoWalkerColors.textSecondary;
  static const Color textMuted = DojoWalkerColors.textMuted;
  static const Color textLight = DojoWalkerColors.textLight;

  static const Color textOnDark = DojoWalkerColors.textOnDark;
  static const Color textOnPrimary =
      DojoWalkerColors.textOnPrimary;

  // ===============================================================
  // BORDER
  // ===============================================================

  static const Color border = DojoWalkerColors.border;
  static const Color borderStrong = DojoWalkerColors.borderStrong;
  static const Color borderMedium = DojoWalkerColors.borderMedium;
  static const Color borderLight = DojoWalkerColors.borderLight;
  static const Color divider = DojoWalkerColors.divider;

  // ===============================================================
  // ICONS
  // ===============================================================

  static const Color iconPrimary =
      DojoWalkerColors.iconPrimary;

  static const Color iconSecondary =
      DojoWalkerColors.iconSecondary;

  static const Color iconMuted =
      DojoWalkerColors.iconMuted;

  static const Color iconOnPrimary =
      DojoWalkerColors.iconOnPrimary;

  static const Color iconOrange =
      DojoWalkerColors.iconOrange;

  static const Color iconGreen =
      DojoWalkerColors.iconGreen;

  static const Color iconBlue =
      DojoWalkerColors.iconBlue;

  // ===============================================================
  // NAVIGATION
  // ===============================================================

  static const Color bottomBar =
      DojoWalkerColors.bottomBar;

  static const Color bottomBarBorder =
      DojoWalkerColors.bottomBarBorder;

  static const Color navSelected =
      DojoWalkerColors.navSelected;

  static const Color navUnselected =
      DojoWalkerColors.navUnselected;

  // ===============================================================
  // CARDS
  // ===============================================================

  static const Color card = DojoWalkerColors.card;
  static const Color cardBorder =
      DojoWalkerColors.cardBorder;

  static const Color cardDark =
      DojoWalkerColors.cardDark;

  static const Color cardDarkSecondary =
      DojoWalkerColors.cardDarkSecondary;

  static const Color cardOrange =
      DojoWalkerColors.cardOrange;

  static const Color cardGreen =
      DojoWalkerColors.cardGreen;

  static const Color cardBlue =
      DojoWalkerColors.cardBlue;

  // ===============================================================
  // INPUT
  // ===============================================================

  static const Color inputBackground =
      DojoWalkerColors.inputBackground;

  static const Color inputBorder =
      DojoWalkerColors.inputBorder;

  static const Color inputFocusedBorder =
      DojoWalkerColors.inputFocusedBorder;

  static const Color inputErrorBorder =
      DojoWalkerColors.inputErrorBorder;

  static const Color inputHint =
      DojoWalkerColors.inputHint;

  // ===============================================================
  // OVERLAY
  // ===============================================================

  static const Color overlay =
      DojoWalkerColors.overlay;

  static const Color darkOverlay =
      DojoWalkerColors.darkOverlay;

  // ===============================================================
  // DISABLED
  // ===============================================================

  static const Color disabled =
      DojoWalkerColors.disabled;

  static const Color disabledText =
      DojoWalkerColors.disabledText;

  // ===============================================================
  // RAINBOW
  // ===============================================================

  static const List<Color> rainbow =
      DojoWalkerColors.rainbow;

  // ===============================================================
  // GRADIENTS
  // ===============================================================

  static const LinearGradient heroGradient =
      DojoWalkerColors.heroGradient;

  static const LinearGradient orangeGradient =
      DojoWalkerColors.orangeGradient;

  static const LinearGradient cyanGradient =
      DojoWalkerColors.cyanGradient;

  static const LinearGradient greenGradient =
      DojoWalkerColors.greenGradient;

  static const LinearGradient darkGradient =
      DojoWalkerColors.darkGradient;

  // ===============================================================
  // SHADOWS
  // ===============================================================

  static const Color shadow =
      DojoWalkerColors.shadow;

  static const Color orangeShadow =
      DojoWalkerColors.orangeShadow;

  static const Color cyanShadow =
      DojoWalkerColors.cyanShadow;

  static const Color greenShadow =
      DojoWalkerColors.greenShadow;
}
