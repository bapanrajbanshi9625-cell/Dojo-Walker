import 'package:flutter/material.dart';

import 'colors/dojo_walker_colors.dart';

class DojoWalkerTheme {
  DojoWalkerTheme._();

  // ==========================================================
  // LIGHT THEME
  // ==========================================================

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      // ========================================================
      // COLOR SCHEME
      // ========================================================

      colorScheme: const ColorScheme.light(
        primary: DojoWalkerColors.primary,
        onPrimary: DojoWalkerColors.textOnPrimary,
        primaryContainer: DojoWalkerColors.primaryLight,
        onPrimaryContainer: DojoWalkerColors.textPrimary,

        secondary: DojoWalkerColors.secondary,
        onSecondary: DojoWalkerColors.textOnPrimary,
        secondaryContainer: DojoWalkerColors.secondaryLight,
        onSecondaryContainer: DojoWalkerColors.textPrimary,

        surface: DojoWalkerColors.surface,
        onSurface: DojoWalkerColors.textPrimary,

        error: DojoWalkerColors.error,
        onError: Colors.white,
        errorContainer: DojoWalkerColors.errorSoft,
        onErrorContainer: DojoWalkerColors.errorDark,
      ),

      // ========================================================
      // SCAFFOLD
      // ========================================================

      scaffoldBackgroundColor:
          DojoWalkerColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme: const AppBarTheme(
        backgroundColor: DojoWalkerColors.surface,
        foregroundColor: DojoWalkerColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: DojoWalkerColors.iconPrimary,
        ),
        titleTextStyle: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ========================================================
      // CARD
      // ========================================================

      cardTheme: const CardThemeData(
        color: DojoWalkerColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
          side: BorderSide(
            color: DojoWalkerColors.cardBorder,
          ),
        ),
      ),

      // ========================================================
      // DIVIDER
      // ========================================================

      dividerTheme: const DividerThemeData(
        color: DojoWalkerColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ========================================================
      // INPUT
      // ========================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DojoWalkerColors.inputBackground,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        hintStyle: const TextStyle(
          color: DojoWalkerColors.inputHint,
          fontSize: 14,
        ),

        labelStyle: const TextStyle(
          color: DojoWalkerColors.textSecondary,
          fontSize: 14,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DojoWalkerColors.inputBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DojoWalkerColors.inputFocusedBorder,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DojoWalkerColors.inputErrorBorder,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DojoWalkerColors.inputErrorBorder,
            width: 2,
          ),
        ),
      ),

      // ========================================================
      // ELEVATED BUTTON
      // ========================================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DojoWalkerColors.buttonPrimary,
          foregroundColor: DojoWalkerColors.buttonText,

          elevation: 0,

          minimumSize: const Size(
            double.infinity,
            52,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DojoWalkerColors.primary,

          minimumSize: const Size(
            double.infinity,
            52,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),

          side: const BorderSide(
            color: DojoWalkerColors.primary,
            width: 1.2,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DojoWalkerColors.primary,

          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),

          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // ICON
      // ========================================================

      iconTheme: const IconThemeData(
        color: DojoWalkerColors.iconPrimary,
        size: 24,
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(
        backgroundColor: DojoWalkerColors.bottomBar,

        selectedItemColor:
            DojoWalkerColors.navSelected,

        unselectedItemColor:
            DojoWalkerColors.navUnselected,

        elevation: 8,

        type: BottomNavigationBarType.fixed,

        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),

        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ========================================================
      // NAVIGATION BAR - MATERIAL 3
      // ========================================================

      navigationBarTheme:
          const NavigationBarThemeData(
        backgroundColor:
            DojoWalkerColors.bottomBar,

        surfaceTintColor:
            Colors.transparent,

        indicatorColor:
            DojoWalkerColors.primaryLight,

        elevation: 8,

        selectedIconTheme:
            IconThemeData(
          color: DojoWalkerColors.navSelected,
        ),

        unselectedIconTheme:
            IconThemeData(
          color: DojoWalkerColors.navUnselected,
        ),

        selectedLabelTextStyle:
            TextStyle(
          color: DojoWalkerColors.navSelected,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),

        unselectedLabelTextStyle:
            TextStyle(
          color: DojoWalkerColors.navUnselected,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ========================================================
      // CHIP
      // ========================================================

      chipTheme: ChipThemeData(
        backgroundColor:
            DojoWalkerColors.surfaceSoft,

        selectedColor:
            DojoWalkerColors.primaryLight,

        disabledColor:
            DojoWalkerColors.disabled,

        side: const BorderSide(
          color: DojoWalkerColors.border,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),

        labelStyle: const TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),

        secondaryLabelStyle:
            const TextStyle(
          color: DojoWalkerColors.textSecondary,
          fontSize: 13,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
      ),

      // ========================================================
      // PROGRESS INDICATOR
      // ========================================================

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: DojoWalkerColors.primary,
        linearTrackColor:
            DojoWalkerColors.primaryLight,
        circularTrackColor:
            DojoWalkerColors.borderLight,
      ),

      // ========================================================
      // SWITCH
      // ========================================================

      switchTheme: SwitchThemeData(
        thumbColor:
            WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return DojoWalkerColors.primary;
            }

            return DojoWalkerColors.textMuted;
          },
        ),

        trackColor:
            WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return DojoWalkerColors.primaryLight;
            }

            return DojoWalkerColors.disabled;
          },
        ),
      ),

      // ========================================================
      // CHECKBOX
      // ========================================================

      checkboxTheme: CheckboxThemeData(
        fillColor:
            WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return DojoWalkerColors.primary;
            }

            return Colors.transparent;
          },
        ),

        checkColor:
            const WidgetStatePropertyAll<Color>(
          Colors.white,
        ),

        side: const BorderSide(
          color: DojoWalkerColors.borderStrong,
          width: 1.5,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),

      // ========================================================
      // RADIO
      // ========================================================

      radioTheme: RadioThemeData(
        fillColor:
            WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return DojoWalkerColors.primary;
            }

            return DojoWalkerColors.borderStrong;
          },
        ),
      ),

      // ========================================================
      // SNACKBAR
      // ========================================================

      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            DojoWalkerColors.slate,

        contentTextStyle:
            const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),

        behavior:
            SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        insetPadding:
            const EdgeInsets.all(16),
      ),

      // ========================================================
      // DIALOG
      // ========================================================

      dialogTheme: DialogThemeData(
        backgroundColor:
            DojoWalkerColors.surface,

        surfaceTintColor:
            Colors.transparent,

        elevation: 8,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        titleTextStyle:
            const TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),

        contentTextStyle:
            const TextStyle(
          color: DojoWalkerColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ========================================================
      // TOOLTIP
      // ========================================================

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: DojoWalkerColors.slate,
          borderRadius: BorderRadius.circular(8),
        ),

        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),

      // ========================================================
      // TEXT THEME
      // ========================================================

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),

        displayMedium: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),

        displaySmall: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),

        headlineLarge: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),

        headlineMedium: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),

        headlineSmall: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),

        titleLarge: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),

        titleMedium: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),

        titleSmall: TextStyle(
          color: DojoWalkerColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),

        bodyLarge: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 16,
          height: 1.5,
        ),

        bodyMedium: TextStyle(
          color: DojoWalkerColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),

        bodySmall: TextStyle(
          color: DojoWalkerColors.textMuted,
          fontSize: 12,
          height: 1.4,
        ),

        labelLarge: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),

        labelMedium: TextStyle(
          color: DojoWalkerColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),

        labelSmall: TextStyle(
          color: DojoWalkerColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================
  // DARK THEME
  // ==========================================================

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,

      colorScheme: const ColorScheme.dark(
        primary: DojoWalkerColors.primary,
        onPrimary: Colors.white,

        secondary: DojoWalkerColors.secondary,
        onSecondary: Colors.white,

        surface: DojoWalkerColors.slate,
        onSurface: DojoWalkerColors.textOnDark,

        error: DojoWalkerColors.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor:
          DojoWalkerColors.obsidian,

      appBarTheme: const AppBarTheme(
        backgroundColor:
            DojoWalkerColors.hero,

        foregroundColor:
            DojoWalkerColors.textOnDark,

        elevation: 0,

        surfaceTintColor:
            Colors.transparent,

        titleTextStyle: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: const CardThemeData(
        color: DojoWalkerColors.cardDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
          side: BorderSide(
            color: DojoWalkerColors.cardDarkSecondary,
          ),
        ),
      ),

      iconTheme: const IconThemeData(
        color: DojoWalkerColors.textOnDark,
      ),
    );
  }
}
