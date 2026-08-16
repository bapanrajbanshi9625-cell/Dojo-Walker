// File location:
// lib/screens/walks_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/walker_home/containers/walker_home_header.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          // ======================================================
          // SAME COMMON HEADER AS HOME
          // ======================================================

          const WalkerHomeHeader(),

          // ======================================================
          // WALKS CONTENT
          // ======================================================

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                24,
              ),
              itemCount: 3,
              itemBuilder: (context, index) {
                return _WalkCard(
                  walkNumber: index + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// WALK CARD
// ================================================================

class _WalkCard extends StatelessWidget {
  final int walkNumber;

  const _WalkCard({
    required this.walkNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Walk Session #$walkNumber',
                  style: const TextStyle(
                    color: Color(0xFF27394A),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                const Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '45 mins',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 14),
                    Icon(
                      Icons.route_rounded,
                      size: 15,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '3.2 km',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9CA3AF),
            size: 24,
          ),
        ],
      ),
    );
  }
}
