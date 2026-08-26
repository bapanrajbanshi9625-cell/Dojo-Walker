import 'package:flutter/material.dart';

import '../dojo_walker_colors.dart';

enum DojoButtonType {
  primary,
  success,
  cyan,
  dark,
  outline,
}

class DojoButton extends StatelessWidget {
  const DojoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = DojoButtonType.primary,
    this.loading = false,
    this.height = 54,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DojoButtonType type;
  final bool loading;
  final double height;
  final double? width;

  Color get backgroundColor {
    switch (type) {
      case DojoButtonType.primary:
        return DojoWalkerColors.primary;

      case DojoButtonType.success:
        return DojoWalkerColors.success;

      case DojoButtonType.cyan:
        return DojoWalkerColors.cyan;

      case DojoButtonType.dark:
        return DojoWalkerColors.heroDark;

      case DojoButtonType.outline:
        return Colors.transparent;
    }
  }

  Color get foregroundColor {
    switch (type) {
      case DojoButtonType.outline:
        return DojoWalkerColors.primary;

      default:
        return DojoWalkerColors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled =
        onPressed == null || loading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: disabled
            ? null
            : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor,
          foregroundColor:
              foregroundColor,
          disabledBackgroundColor:
              DojoWalkerColors.borderMedium,
          disabledForegroundColor:
              DojoWalkerColors.textLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(17),
            side: type ==
                    DojoButtonType.outline
                ? const BorderSide(
                    color:
                        DojoWalkerColors.primary,
                  )
                : BorderSide.none,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:
                      DojoWalkerColors.white,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 21,
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                  ],
                  Text(
                    label,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: .2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
