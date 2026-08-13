import 'package:flutter/material.dart';

class WalkerLocationMarker extends StatelessWidget {
  const WalkerLocationMarker({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4B16)
                .withOpacity(.15),
            shape: BoxShape.circle,
          ),
        ),

        Container(
          width: 47,
          height: 47,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4B16),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }
}
