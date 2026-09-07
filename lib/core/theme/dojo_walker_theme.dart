import 'package:flutter/material.dart';

import 'dojo_walker_colors.dart';
import 'dojo_walker_text.dart';

class DojoWalkerTheme {
  DojoWalkerTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      scaffoldBackgroundColor: DojoWalkerColors.background,

      colorScheme: const ColorScheme.light(
        primary: DojoWalkerColors.primary,
        onPrimary: DojoWalkerColors.white,

        secondary: DojoWalkerColors.dark,
        onSecondary: DojoWalkerColors.white,

        surface: DojoWalkerColors.card,
        onSurface: DojoWalkerColors.textPrimary,

        error: DojoWalkerColors.error,
        onError: DojoWalkerColors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: DojoWalkerColors.primary,
        foregroundColor: DojoWalkerColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: DojoWalkerColors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: DojoWalkerColors.card,
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

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DojoWalkerColors.primary,
          foregroundColor: DojoWalkerColors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: DojoWalkerText.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DojoWalkerColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(
            color: DojoWalkerColors.primary,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: DojoWalkerText.button.copyWith(
            color: DojoWalkerColors.primary,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DojoWalkerColors.primary,
          textStyle: DojoWalkerText.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DojoWalkerColors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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
            width: 1.5,
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
            width: 1.5,
          ),
        ),

        labelStyle: DojoWalkerText.bodyMedium,

        hintStyle: DojoWalkerText.bodyMedium.copyWith(
          color: DojoWalkerColors.textMuted,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DojoWalkerColors.white,
        selectedItemColor: DojoWalkerColors.primary,
        unselectedItemColor: DojoWalkerColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dividerTheme: const DividerThemeData(
        color: DojoWalkerColors.border,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: DojoWalkerColors.textPrimary,
        contentTextStyle: DojoWalkerText.bodyMedium.copyWith(
          color: DojoWalkerColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
