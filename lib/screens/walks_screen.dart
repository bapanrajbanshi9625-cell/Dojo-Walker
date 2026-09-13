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

    _availabilityService.addListener(_onAvailabilityChanged);
  }

  void _onAvailabilityChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _toggleInstaWalkSearch() async {
    if (_availabilityService.isChangingStatus) {
      return;
    }

    if (!_availabilityService.isOnline) {
      _showMessage(
        'Please go Online first.',
      );
      return;
    }

    if (!_availabilityService.isInstaWalkSelected) {
      _showMessage(
        'Please select Insta Walk first.',
      );
      return;
    }

    if (_availabilityService.isActiveWalk) {
      _showMessage(
        'Search is unavailable during an active walk.',
      );
      return;
    }

    if (_availabilityService.isInstaWalkSearching) {
      _availabilityService.stopInstaWalkSearch();
      return;
    }

    final bool started =
        await _availabilityService.startInstaWalkSearch();

    if (!mounted) {
      return;
    }

    if (!started) {
      final String? error = _availabilityService.error;

      _showMessage(
        error != null && error.trim().isNotEmpty
            ? error
            : 'Unable to start Insta Walk search.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    final bool activeWalk =
        _availabilityService.isActiveWalk;

    final bool changing =
        _availabilityService.isChangingStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: ListView(
        padding: const EdgeInsets.only(
          bottom: 30,
        ),
        children: <Widget>[
          // ========================================================
          // SEARCH STATUS
          // ========================================================

          InstaWalkSearchPanel(
            searching: searching,
          ),

          // ========================================================
          // INSTA WALK SEARCH CONTROL
          // ========================================================

          if (isOnline && isInstaWalkSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                0,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: changing || activeWalk
                      ? null
                      : _toggleInstaWalkSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: searching
                        ? const Color(0xFFF3F4F6)
                        : DojoWalkerColors.primary,
                    foregroundColor: searching
                        ? const Color(0xFF171717)
                        : Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFFE5E7EB),
                    disabledForegroundColor:
                        const Color(0xFF9CA3AF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: searching
                          ? const BorderSide(
                              color: Color(0xFFD1D5DB),
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: changing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              DojoWalkerColors.primary,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              searching
                                  ? Icons.stop_circle_outlined
                                  : Icons.flash_on_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              searching
                                  ? 'Stop Insta Walk Search'
                                  : 'Start Insta Walk Search',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

          // ========================================================
          // OFFLINE / DAILY WALK INFORMATION
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
                    'Switch to Insta Walk from the top bar when you want to search for nearby instant walk requests.',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DojoWalkerColors.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
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
