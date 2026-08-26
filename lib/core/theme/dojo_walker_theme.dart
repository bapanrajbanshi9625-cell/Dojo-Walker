import 'package:flutter/material.dart';

import 'dojo_walker_colors.dart';

class DojoWalkerTheme {
  DojoWalkerTheme._();

  // ==========================================================
  // LIGHT THEME
  // ==========================================================

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: DojoWalkerColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: DojoWalkerColors.primary,
      onPrimary: DojoWalkerColors.white,
      secondary: DojoWalkerColors.cyan,
      onSecondary: DojoWalkerColors.white,
      surface: DojoWalkerColors.surface,
      error: DojoWalkerColors.error,
      onError: DojoWalkerColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          DojoWalkerColors.background,

      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: DojoWalkerColors.white,
        foregroundColor: DojoWalkerColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: DojoWalkerColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: DojoWalkerColors.border,
          ),
        ),
      ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,
        fillColor: DojoWalkerColors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: DojoWalkerColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: DojoWalkerColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: DojoWalkerColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: DojoWalkerColors.error,
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: DojoWalkerColors.error,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          color: DojoWalkerColors.textMuted,
        ),
        hintStyle: const TextStyle(
          color: DojoWalkerColors.textLight,
        ),
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              DojoWalkerColors.primary,
          foregroundColor:
              DojoWalkerColors.white,
          elevation: 0,
          minimumSize: const Size(
            double.infinity,
            52,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),

      textButtonTheme:
          TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              DojoWalkerColors.primary,
        ),
      ),

      dividerTheme:
          const DividerThemeData(
        color: DojoWalkerColors.border,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme:
          SnackBarThemeData(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            DojoWalkerColors.heroDark,
        contentTextStyle:
            const TextStyle(
          color: DojoWalkerColors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: DojoWalkerColors.primary,
      ),

      navigationBarTheme:
          NavigationBarThemeData(
        backgroundColor:
            DojoWalkerColors.white,
        indicatorColor:
            DojoWalkerColors.primarySoft,
        elevation: 0,
        labelTextStyle:
            WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return const TextStyle(
                color:
                    DojoWalkerColors.primary,
                fontWeight:
                    FontWeight.w800,
                fontSize: 11,
              );
            }

            return const TextStyle(
              color:
                  DojoWalkerColors.textMuted,
              fontWeight:
                  FontWeight.w600,
              fontSize: 11,
            );
          },
        ),
        iconTheme:
            WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return const IconThemeData(
                color:
                    DojoWalkerColors.primary,
              );
            }

            return const IconThemeData(
              color:
                  DojoWalkerColors.textMuted,
            );
          },
        ),
      ),
    );
  }
}
