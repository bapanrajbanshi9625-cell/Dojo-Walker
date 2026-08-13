import 'package:flutter/material.dart';

import '../walker_home_features.dart';

class WalkerSectionTitle extends StatelessWidget {
  final String title;
  final bool live;

  const WalkerSectionTitle({
    super.key,
    required this.title,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            color: WalkerHomeFeatures.orange,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            color: WalkerHomeFeatures.dark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),

        if (live) ...[
          const SizedBox(width: 9),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: Colors.green,
                ),
                SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
