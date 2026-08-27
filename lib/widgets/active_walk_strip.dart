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
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
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
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStateService state =
        AppStateService.instance;

    final Map<String, dynamic>? walkData =
        state.activeWalkData;

    final Map<String, dynamic>? sessionData =
        state.activeSessionData;

    if (!state.hasActiveWalk ||
        walkData == null ||
        walkData.isEmpty) {
      return const SizedBox.shrink();
    }

    final String walkStatus =
        _status(walkData['status']);

    final String sessionStatus =
        _status(sessionData?['status']);

    final bool isVisible =
        walkStatus == 'ACCEPTED' ||
        walkStatus == 'ACTIVE' ||
        sessionStatus == 'ACTIVE' ||
        sessionStatus == 'LIVE' ||
        sessionStatus == 'STARTED';

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final bool isLive =
        sessionStatus == 'LIVE' ||
        sessionStatus == 'STARTED';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 46,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLive
                    ? Icons
                        .location_on_rounded
                    : Icons
                        .directions_walk_rounded,
                color: Colors.white,
                size: 21,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  isLive
                      ? 'LIVE WALK'
                      : 'ACTIVE WALK',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),

              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                color: Colors.white,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _status(dynamic value) {
    return value
            ?.toString()
            .trim()
            .toUpperCase() ??
        '';
  }
}
