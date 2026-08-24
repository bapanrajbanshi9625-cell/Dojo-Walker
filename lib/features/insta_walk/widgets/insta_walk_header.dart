import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../walks/constants/walks_constants.dart';

class InstaWalkHeader extends StatelessWidget {
  final bool searching;

  const InstaWalkHeader({
    super.key,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B2025),
            Color(0xFF414850),
            Color(0xFF16191D),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(.13),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insta Walk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Find a walk request nearby',
                  style: TextStyle(
                    color: Color(0xFFD5D9DD),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (searching)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: WalksConstants.radarGreen.withOpacity(.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: WalksConstants.radarGreen.withOpacity(.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: WalksConstants.radarGreen,
                    size: 8,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
