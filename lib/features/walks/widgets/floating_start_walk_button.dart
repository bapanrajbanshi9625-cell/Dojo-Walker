import 'package:flutter/material.dart';

import '../screens/active_walk_details_screen.dart';

class FloatingStartWalkButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingStartWalkButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: SafeArea(
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
                backgroundColor:
                    const Color(0xFFFF6600),
                foregroundColor: Colors.white,
                elevation: 9,
                shadowColor:
                    const Color(0xFFFF6600)
                        .withOpacity(.32),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
