// File:
// lib/features/walks/widgets/insta_walk_container.dart

import 'package:flutter/material.dart';

import 'insta_walk_map_radar.dart';

class InstaWalkContainer extends StatelessWidget {
  final VoidCallback? onSearch;

  /// True होने पर Map + Radar दिखाई देगा।
  final bool searching;

  const InstaWalkContainer({
    super.key,
    this.onSearch,
    this.searching = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE45D32),
            Color(0xFFC84A24),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insta Walk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Find a walk right now',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // =====================================================
          // NORMAL DESCRIPTION
          // =====================================================

          if (!searching)
            const Text(
              'Search for available Insta Walk requests within 3.5 kilometre.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),

          // =====================================================
          // MAP + RADAR
          // =====================================================

          if (searching) ...[
            const SizedBox(height: 2),

            const InstaWalkMapRadar(),

            const SizedBox(height: 15),

            const Row(
              children: [
                SizedBox(
                  width: 9,
                  height: 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF62E6A7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Searching for nearby Insta Walk requests...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 15),

          // =====================================================
          // SEARCH / STOP BUTTON
          // =====================================================

          SizedBox(
            width: double.infinity,
            height: 49,
            child: ElevatedButton.icon(
              onPressed: onSearch,
              icon: Icon(
                searching
                    ? Icons.stop_rounded
                    : Icons.search_rounded,
                color: const Color(0xFF238EAE),
              ),
              label: Text(
                searching
                    ? 'Stop Insta Walk Search'
                    : 'Insta Walk Search',
                style: const TextStyle(
                  color: Color(0xFF238EAE),
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
