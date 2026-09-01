import 'package:flutter/material.dart';

import 'dojo_walker_colors.dart';

class DojoWalkerTheme {
  DojoWalkerTheme._();

  // ==========================================================
  // LIGHT THEME
  // ==========================================================

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

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

      scaffoldBackgroundColor: DojoWalkerColors.background,

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

      dividerTheme: const DividerThemeData(
        color: DojoWalkerColors.divider,
        thickness: 1,
        space: 1,
      ),

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

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DojoWalkerColors.buttonPrimary,
          foregroundColor: DojoWalkerColors.buttonText,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
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

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DojoWalkerColors.primary,
          minimumSize: const Size(double.infinity, 52),
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

      iconTheme: const IconThemeData(
        color: DojoWalkerColors.iconPrimary,
        size: 24,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DojoWalkerColors.bottomBar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: DojoWalkerColors.primaryLight,
        elevation: 8,
        height: 72,
        iconTheme:
            WidgetStateProperty.resolveWith<IconThemeData?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: DojoWalkerColors.navSelected,
              );
            }

            return const IconThemeData(
              color: DojoWalkerColors.navUnselected,
            );
          },
        ),
        labelTextStyle:
            WidgetStateProperty.resolveWith<TextStyle?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: DojoWalkerColors.navSelected,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              );
            }

            return const TextStyle(
              color: DojoWalkerColors.navUnselected,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          },
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: DojoWalkerColors.surfaceSoft,
        selectedColor: DojoWalkerColors.primaryLight,
        disabledColor: DojoWalkerColors.disabled,
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
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: DojoWalkerColors.primary,
        linearTrackColor: DojoWalkerColors.primaryLight,
        circularTrackColor: DojoWalkerColors.borderLight,
      ),

      switchTheme: SwitchThemeData(
        thumbColor:
            WidgetStateProperty.resolveWith<Color?>(
          (states) {
            return states.contains(WidgetState.selected)
                ? DojoWalkerColors.primary
                : DojoWalkerColors.textMuted;
          },
        ),
        trackColor:
            WidgetStateProperty.resolveWith<Color?>(
          (states) {
            return states.contains(WidgetState.selected)
                ? DojoWalkerColors.primaryLight
                : DojoWalkerColors.disabled;
          },
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor:
            WidgetStateProperty.resolveWith<Color?>(
          (states) {
            return states.contains(WidgetState.selected)
                ? DojoWalkerColors.primary
                : Colors.transparent;
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

      radioTheme: RadioThemeData(
        fillColor:
            WidgetStateProperty.resolveWith<Color?>(
          (states) {
            return states.contains(WidgetState.selected)
                ? DojoWalkerColors.primary
                : DojoWalkerColors.borderStrong;
          },
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: DojoWalkerColors.slate,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: DojoWalkerColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        titleTextStyle: TextStyle(
          color: DojoWalkerColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: DojoWalkerColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

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

      scaffoldBackgroundColor: DojoWalkerColors.obsidian,

      appBarTheme: const AppBarTheme(
        backgroundColor: DojoWalkerColors.hero,
        foregroundColor: DojoWalkerColors.textOnDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: DojoWalkerColors.textOnDark,
        ),
        titleTextStyle: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: const CardThemeData(
        color: DojoWalkerColors.cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
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

      dividerTheme: const DividerThemeData(
        color: DojoWalkerColors.cardDarkSecondary,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: DojoWalkerColors.textOnDark,
        size: 24,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DojoWalkerColors.cardDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: DojoWalkerColors.primaryDark,
        elevation: 8,
        height: 72,
        iconTheme:
            WidgetStateProperty.resolveWith<IconThemeData?>(
          (states) {
            return states.contains(WidgetState.selected)
                ? const IconThemeData(
                    color: DojoWalkerColors.primary,
                  )
                : const IconThemeData(
                    color: DojoWalkerColors.textMuted,
                  );
          },
        ),
        labelTextStyle:
            WidgetStateProperty.resolveWith<TextStyle?>(
          (states) {
            return states.contains(WidgetState.selected)
                ? const TextStyle(
                    color: DojoWalkerColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  )
                : const TextStyle(
                    color: DojoWalkerColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  );
          },
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DojoWalkerColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: DojoWalkerColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: DojoWalkerColors.textLight,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DojoWalkerColors.cardDarkSecondary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DojoWalkerColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: DojoWalkerColors.error,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DojoWalkerColors.buttonPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
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

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DojoWalkerColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(
            color: DojoWalkerColors.primary,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: DojoWalkerColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: DojoWalkerColors.textLight,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: DojoWalkerColors.midnight,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: DojoWalkerColors.midnight,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        displaySmall: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: DojoWalkerColors.textLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: DojoWalkerColors.textLight,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: DojoWalkerColors.textMuted,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: DojoWalkerColors.textOnDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: DojoWalkerColors.textLight,
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
}
