import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/active_walk_strip_service.dart';

class ActiveWalkStrip extends StatefulWidget {
  const ActiveWalkStrip({
    super.key,
    required this.onTap,
  });

  final ValueChanged<ActiveWalkStripState> onTap;

  @override
  State<ActiveWalkStrip> createState() =>
      _ActiveWalkStripState();
}

class _ActiveWalkStripState
    extends State<ActiveWalkStrip> {
  StreamSubscription<ActiveWalkStripState>?
      _subscription;

  ActiveWalkStripState _state =
      const ActiveWalkStripState.hidden();

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription =
        ActiveWalkStripService.instance.watch().listen(
      (ActiveWalkStripState state) {
        if (!mounted) {
          return;
        }

        setState(() {
          _state = state;
        });
      },
      onError: (Object error) {
        debugPrint(
          'ActiveWalkStrip service error: $error',
        );
      },
    );
  }

  // ============================================================
  // TAP
  // ============================================================

  void _handleTap() {
    if (!_state.show) {
      return;
    }

    debugPrint(
      'ActiveWalkStrip tapped: '
      'isLive=${_state.isLive}, '
      'walkId=${_state.walkId}',
    );

    widget.onTap(_state);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!_state.show) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        child: Container(
          width: double.infinity,
          height: 60,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.18,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _state.isLive
                      ? Icons.location_on_rounded
                      : Icons.directions_walk_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _state.isLive
                          ? 'LIVE WALK'
                          : 'ACTIVE WALK',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _state.isLive
                          ? 'Tap anywhere to open live walk'
                          : 'Tap anywhere to open active walk',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
