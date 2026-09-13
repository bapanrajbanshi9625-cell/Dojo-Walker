// File:
// lib/screens/walks_screen.dart

import 'package:flutter/material.dart';

import '../core/theme/dojo_walker_colors.dart';
import '../features/insta_walk/widgets/insta_walk_search_panel.dart';
import '../services/walker_availability_service.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({
    super.key,
  });

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen> {
  final WalkerAvailabilityService _availabilityService =
      WalkerAvailabilityService.instance;

  @override
  void initState() {
    super.initState();

    _availabilityService.addListener(
      _onAvailabilityChanged,
    );
  }

  void _onAvailabilityChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _availabilityService.removeListener(
      _onAvailabilityChanged,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline =
        _availabilityService.isOnline;

    final bool isInstaWalkSelected =
        _availabilityService.isInstaWalkSelected;

    final bool searching =
        _availabilityService.isInstaWalkSearching;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: ListView(
        padding: const EdgeInsets.only(
          bottom: 30,
        ),
        children: <Widget>[
          // ========================================================
          // INSTA WALK SEARCH STATUS
          // ========================================================

          if (isOnline && isInstaWalkSelected)
            InstaWalkSearchPanel(
              searching: searching,
            ),

          // ========================================================
          // OFFLINE
          // ========================================================

          if (!isOnline)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                0,
              ),
              child: _SearchInfoCard(
                icon: Icons.power_settings_new_rounded,
                title: 'You are Offline',
                message:
                    'Go Online from the top bar to start receiving Insta Walk requests.',
              ),
            ),

          // ========================================================
          // DAILY WALK
          // ========================================================

          if (isOnline && !isInstaWalkSelected)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                0,
              ),
              child: _SearchInfoCard(
                icon: Icons.swap_horiz_rounded,
                title: 'Daily Walk Mode',
                message:
                    'You are Online for Daily Walks.',
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// SEARCH INFO CARD
// ================================================================

class _SearchInfoCard extends StatelessWidget {
  const _SearchInfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DojoWalkerColors.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: DojoWalkerColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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
