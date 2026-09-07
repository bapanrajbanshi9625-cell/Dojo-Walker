import 'package:flutter/material.dart';

import 'dojo_walker_colors.dart';

class DojoWalkerText {
  DojoWalkerText._();

  // ============================================================
  // DISPLAY
  // ============================================================

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: DojoWalkerColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: DojoWalkerColors.textPrimary,
    height: 1.2,
  );

  // ============================================================
  // HEADINGS
  // ============================================================

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: DojoWalkerColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: DojoWalkerColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: DojoWalkerColors.textPrimary,
    height: 1.3,
  );

  // ============================================================
  // BODY
  // ============================================================

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: DojoWalkerColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: DojoWalkerColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: DojoWalkerColors.textSecondary,
    height: 1.4,
  );

  // ============================================================
  // LABELS
  // ============================================================

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DojoWalkerColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: DojoWalkerColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: DojoWalkerColors.textMuted,
    height: 1.3,
  );

  // ============================================================
  // BUTTON
  // ============================================================

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: DojoWalkerColors.white,
    height: 1.2,
  );

  // ============================================================
  // BRAND
  // ============================================================

  static const TextStyle brand = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: DojoWalkerColors.primary,
    letterSpacing: -0.3,
  );

  // ============================================================
  // SPECIAL
  // ============================================================

  static const TextStyle success = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: DojoWalkerColors.success,
  );

  static const TextStyle error = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: DojoWalkerColors.error,
  );
}
