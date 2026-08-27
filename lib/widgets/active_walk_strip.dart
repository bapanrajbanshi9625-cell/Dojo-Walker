import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/app_state_service.dart';

class ActiveWalkStrip extends StatefulWidget {
  const ActiveWalkStrip({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<ActiveWalkStrip> createState() =>
      _ActiveWalkStripState();
}

class _ActiveWalkStripState
    extends State<ActiveWalkStrip> {

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStateService state =
        AppStateService.instance;

    if (!state.hasActiveWalk) {
      return const SizedBox.shrink();
    }

    final String sessionStatus =
        _readStatus(
      state.activeSessionData?['status'],
    );

    final String walkStatus =
        _readStatus(
      state.activeWalkData?['status'],
    );

    final bool isLive =
        sessionStatus == 'LIVE' ||
        sessionStatus == 'ACTIVE' ||
        walkStatus == 'LIVE' ||
        walkStatus == 'ACTIVE';

    if (!isLive) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 48,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: Colors.white,
                size: 22,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  isLive
                      ? 'LIVE WALK'
                      : 'ACTIVE WALK',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _readStatus(dynamic value) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .toUpperCase();
  }
}
