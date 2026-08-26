import 'package:flutter/material.dart';

import '../dojo_walker_colors.dart';

class DojoRainbowBar extends StatelessWidget {
  const DojoRainbowBar({
    super.key,
    this.height = 4,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            DojoWalkerColors.primary,
            DojoWalkerColors.cyan,
            DojoWalkerColors.success,
          ],
        ),
      ),
    );
  }
}
