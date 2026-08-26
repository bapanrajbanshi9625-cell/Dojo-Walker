import 'package:flutter/material.dart';

import '../dojo_walker_colors.dart';

class DojoCard extends StatelessWidget {
  const DojoCard({
    super.key,
    required this.child,
    this.padding =
        const EdgeInsets.all(18),
    this.radius = 20,
    this.backgroundColor,
    this.borderColor,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            DojoWalkerColors.white,
        borderRadius:
            BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ??
              DojoWalkerColors.border,
        ),
        boxShadow: shadow
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
