import 'package:flutter/material.dart';

import 'colors/dojo_walker_colors.dart';

class DojoWalkerTheme {
  DojoWalkerTheme._();

  static ThemeData light() {
    final colors = DojoWalkerColors;

    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      scaffoldBackgroundColor: colors.background,

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

      appBarTheme: const AppBarTheme(
        backgroundColor: DojoWalkerColors.surface,
        foregroundColor: DojoWalkerColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),

      cardTheme: CardThemeData(
        color: colors.surface,
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

      dividerTheme: const DividerThemeData(
        color: DojoWalkerColors.divider,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,

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

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.buttonPrimary,
          foregroundColor: colors.buttonText,

          minimumSize: const Size(double.infinity, 52),

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

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,

          minimumSize: const Size(double.infinity, 52),

          side: const BorderSide(
            color: DojoWalkerColors.primary,
            width: 1.5,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DojoWalkerColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DojoWalkerColors.bottomBar,
        selectedItemColor: DojoWalkerColors.navSelected,
        unselectedItemColor: DojoWalkerColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
