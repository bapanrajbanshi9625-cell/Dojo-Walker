import 'package:flutter/material.dart';

import 'colors/dojo_walker_colors.dart';

class DojoWalkerTheme {
  DojoWalkerTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ==========================================================
      // GLOBAL
      // ==========================================================

      scaffoldBackgroundColor:
          DojoWalkerColors.background,

      colorScheme: const ColorScheme.light(
        primary: DojoWalkerColors.primary,
        onPrimary: Colors.white,
        secondary: DojoWalkerColors.secondary,
        onSecondary: Colors.white,
        surface: DojoWalkerColors.surface,
        onSurface: DojoWalkerColors.textPrimary,
        error: DojoWalkerColors.error,
        onError: Colors.white,
      ),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBarTheme: const AppBarTheme(
        backgroundColor: DojoWalkerColors.surface,
        foregroundColor: DojoWalkerColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),

      // ==========================================================
      // CARD
      // ==========================================================

      cardTheme: CardThemeData(
        color: DojoWalkerColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: DojoWalkerColors.border,
            width: 1,
          ),
        ),
      ),

      // ==========================================================
      // DIVIDER
      // ==========================================================

      dividerTheme: const DividerThemeData(
        color: DojoWalkerColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ==========================================================
      // INPUT
      // ==========================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DojoWalkerColors.surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: DojoWalkerColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: DojoWalkerColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: DojoWalkerColors.primary,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: DojoWalkerColors.error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: DojoWalkerColors.error,
            width: 2,
          ),
        ),
      ),

      // ==========================================================
      // ELEVATED BUTTON
      // ==========================================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              DojoWalkerColors.buttonPrimary,

          foregroundColor:
              DojoWalkerColors.buttonText,

          minimumSize:
              const Size(double.infinity, 52),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ==========================================================
      // OUTLINED BUTTON
      // ==========================================================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              DojoWalkerColors.primary,

          minimumSize:
              const Size(double.infinity, 52),

          side: const BorderSide(
            color: DojoWalkerColors.primary,
            width: 1.5,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ==========================================================
      // TEXT BUTTON
      // ==========================================================

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              DojoWalkerColors.primary,

          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ==========================================================
      // FAB
      // ==========================================================

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor:
            DojoWalkerColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor:
            DojoWalkerColors.bottomBar,
        selectedItemColor:
            DojoWalkerColors.navSelected,
        unselectedItemColor:
            DojoWalkerColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ==========================================================
      // SNACKBAR
      // ==========================================================

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,

        backgroundColor:
            DojoWalkerColors.textPrimary,

        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ==========================================================
      // DIALOG
      // ==========================================================

      dialogTheme: DialogThemeData(
        backgroundColor:
            DojoWalkerColors.surface,

        surfaceTintColor:
            Colors.transparent,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
