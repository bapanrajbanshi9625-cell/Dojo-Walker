import 'package:flutter/material.dart';

class DojoWalkerShadows {
  DojoWalkerShadows._();

  /// Standard card shadow.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Soft premium shadow.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Brand button shadow.
  static const List<BoxShadow> primary = [
    BoxShadow(
      color: Color(0x33E86100),
      blurRadius: 12,
      offset: Offset(0, 5),
    ),
  ];

  /// Floating element shadow.
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// No shadow.
  static const List<BoxShadow> none = [];
}
