import 'package:flutter/material.dart';

import 'dojo_walker_colors.dart';

class DojoWalkerGradients {
  DojoWalkerGradients._();

  /// Main Dojo Walker brand gradient.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DojoWalkerColors.primary,
      DojoWalkerColors.dark,
    ],
  );

  /// Deep premium gradient.
  static const LinearGradient deep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DojoWalkerColors.deep,
      DojoWalkerColors.dark,
    ],
  );

  /// Soft orange gradient for cards.
  static const LinearGradient soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DojoWalkerColors.light,
      DojoWalkerColors.soft,
    ],
  );

  /// Clean surface gradient.
  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      DojoWalkerColors.white,
      DojoWalkerColors.light,
    ],
  );
}
