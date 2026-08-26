import 'package:flutter/material.dart';

/// ============================================================
/// DOJO WALK - COMPLETE COLOR SYSTEM
/// ============================================================
///
/// Centralized color palette for the complete Dojo Walk app.
/// Do not add random colors inside screens.
/// Use DojoWalkerColors or AppColors compatibility aliases.
///

class DojoWalkerColors {
  DojoWalkerColors._();

  // ==========================================================
  // BRAND
  // ==========================================================

  static const Color primary = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color primaryLight = Color(0xFFFB923C);
  static const Color primarySoft = Color(0xFFFFEDD5);
  static const Color primaryUltraSoft = Color(0xFFFFF7ED);

  // ==========================================================
  // HERO / DARK
  // ==========================================================

  static const Color heroDark = Color(0xFF0F172A);
  static const Color heroMid = Color(0xFF1E293B);
  static const Color heroLight = Color(0xFF334155);
  static const Color heroSoft = Color(0xFF475569);

  // ==========================================================
  // LIVE / ACTIVE / CYAN
  // ==========================================================

  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanDark = Color(0xFF0891B2);
  static const Color cyanLight = Color(0xFF22D3EE);
  static const Color cyanSoft = Color(0xFFECFEFF);

  static const Color sky = Color(0xFF38BDF8);
  static const Color skyDark = Color(0xFF0284C7);
  static const Color skySoft = Color(0xFFE0F2FE);

  // ==========================================================
  // SUCCESS / CTA / GREEN
  // ==========================================================

  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color forest = Color(0xFF15803D);
  static const Color successLight = Color(0xFF34D399);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color successUltraSoft = Color(0xFFECFDF5);

  // ==========================================================
  // ERROR
  // ==========================================================

  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color errorUltraSoft = Color(0xFFFEF2F2);

  // ==========================================================
  // WARNING
  // ==========================================================

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color warningUltraSoft = Color(0xFFFFFBEB);

  // ==========================================================
  // BACKGROUND
  // ==========================================================

  static const Color background = Color(0xFFF8FAFC);
  static const Color warmBackground = Color(0xFFFAF9F6);

  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF1F5F9);
  static const Color surfaceDark = Color(0xFFE2E8F0);

  // ==========================================================
  // TEXT
  // ==========================================================

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textBody = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // ==========================================================
  // BORDER
  // ==========================================================

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color borderDark = Color(0xFF94A3B8);

  static const Color orangeBorder = Color(0xFFFDBA74);
  static const Color greenBorder = Color(0xFF6EE7B7);
  static const Color cyanBorder = Color(0xFF67E8F9);
  static const Color errorBorder = Color(0xFFFCA5A5);

  // ==========================================================
  // PET CARE
  // ==========================================================

  static const Color peach = Color(0xFFFDBA74);
  static const Color softPeach = Color(0xFFFFEDD5);
  static const Color cream = Color(0xFFFEF3C7);
  static const Color pawBeige = Color(0xFFFDE68A);
  static const Color warmSand = Color(0xFFF5E6D3);

  // ==========================================================
  // RATING
  // ==========================================================

  static const Color rating = Color(0xFFF59E0B);
  static const Color ratingLight = Color(0xFFFBBF24);
  static const Color ratingSoft = Color(0xFFFEF3C7);

  // ==========================================================
  // MAP
  // ==========================================================

  static const Color mapLocation = Color(0xFF2563EB);
  static const Color mapRoute = Color(0xFF10B981);
  static const Color mapPickup = Color(0xFFF97316);
  static const Color mapDestination = Color(0xFFEF4444);
  static const Color mapSurface = Color(0xFFF8FAFC);

  // ==========================================================
  // STATUS
  // ==========================================================

  static const Color online = success;
  static const Color offline = textLight;
  static const Color searching = cyan;
  static const Color active = success;
  static const Color pending = warning;
  static const Color approved = success;
  static const Color rejected = error;
  static const Color completed = forest;
  static const Color cancelled = textMuted;

  // ==========================================================
  // SPECIAL
  // ==========================================================

  static const Color black = Color(0xFF000000);

  // ==========================================================
  // GRADIENTS
  // ==========================================================

  static const LinearGradient heroGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      heroDark,
      heroMid,
    ],
  );

  static const LinearGradient orangeGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      primary,
      primaryDark,
    ],
  );

  static const LinearGradient greenGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      success,
      successDark,
    ],
  );

  static const LinearGradient cyanGradient =
      LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      cyan,
      skyDark,
    ],
  );

  // ==========================================================
  // GLOW
  // ==========================================================

  static List<BoxShadow> cyanGlow({
    double opacity = .22,
    double blur = 16,
    double spread = 2,
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: cyan.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> orangeGlow({
    double opacity = .16,
    double blur = 16,
    double spread = 1,
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: primary.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static List<BoxShadow> greenGlow({
    double opacity = .16,
    double blur = 16,
    double spread = 1,
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: success.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }
}
