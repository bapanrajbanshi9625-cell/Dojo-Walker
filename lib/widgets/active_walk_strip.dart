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

class _ActiveWalkStripState extends State<ActiveWalkStrip> {
  StreamSubscription<ActiveWalkStripState>? _subscription;

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
          'ActiveWalkStrip error: $error',
        );
      },
    );
  }

  void _handleTap() {
    if (!_state.show ||
        _state.walkId.trim().isEmpty) {
      return;
    }

    widget.onTap(_state);
  }

  String get _title {
    return _state.isLive
        ? 'LIVE WALK'
        : 'WALK REQUEST';
  }

  String get _subtitle {
    return _state.isLive
        ? 'Walk is in progress'
        : 'Your walk request is active';
  }

  IconData get _icon {
    return _state.isLive
        ? Icons.location_on_rounded
        : Icons.directions_walk_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (!_state.show) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        8,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _handleTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 72,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(
                  alpha: 0.14,
                ),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                // =================================================
                // STATUS ICON
                // =================================================

                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // =================================================
                // TEXT
                // =================================================

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _state.isLive
                                  ? Colors.red
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // =================================================
                // ACTION
                // =================================================

                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
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
