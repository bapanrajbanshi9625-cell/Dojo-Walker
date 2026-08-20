import 'package:flutter/material.dart';

class FloatingStartWalkButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingStartWalkButton({
    super.key,
    required this.onPressed,
  });

  static const Color orange = Color(0xFFFF6600);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: SizedBox(
          width: 170,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(
              Icons.directions_walk_rounded,
              size: 20,
            ),
            label: const Text(
              'Start Walk',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              elevation: 9,
              shadowColor: orange,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
