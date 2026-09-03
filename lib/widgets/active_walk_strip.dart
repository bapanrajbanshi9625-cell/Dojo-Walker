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

class _ActiveWalkStripState extends State<ActiveWalkStrip>
    with SingleTickerProviderStateMixin {
  StreamSubscription<ActiveWalkStripState>? _subscription;

  late final AnimationController _pulseController;

  ActiveWalkStripState _state =
      const ActiveWalkStripState.hidden();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1600,
      ),
    )..repeat(reverse: true);

    _startListening();
  }

  void _startListening() {
    _subscription =
        ActiveWalkStripService.instance.watch().listen(
      (
        ActiveWalkStripState state,
      ) {
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
        : 'WALK ACCEPTED';
  }

  String get _subtitle {
    return _state.isLive
        ? 'Your walk is in progress'
        : 'Tap to open your live walk';
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
          borderRadius: BorderRadius.circular(20),
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (
              BuildContext context,
              Widget? child,
            ) {
              final double pulse =
                  _state.isLive
                      ? _pulseController.value * 0.035
                      : 0.0;

              return Container(
                constraints: const BoxConstraints(
                  minHeight: 78,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        AppColors.primary.withValues(
                      alpha: 0.16 + pulse,
                    ),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(
                        alpha: 0.08 + pulse,
                      ),
                      blurRadius: 18,
                      spreadRadius: 0,
                      offset: const Offset(0, 7),
                    ),
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.045,
                      ),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    // =================================================
                    // ICON
                    // =================================================

                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppColors.primary.withValues(
                              alpha: 0.16,
                            ),
                            AppColors.primary.withValues(
                              alpha: 0.07,
                            ),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          if (_state.isLive)
                            Container(
                              width: 34,
                              height: 34,
                              decoration:
                                  BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red
                                      .withValues(
                                    alpha: 0.18,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          Icon(
                            _icon,
                            color: _state.isLive
                                ? Colors.red
                                : AppColors.primary,
                            size: 25,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // =================================================
                    // TEXT
                    // =================================================

                    Expanded(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 7,
                                height: 7,
                                decoration:
                                    BoxDecoration(
                                  color: _state.isLive
                                      ? Colors.red
                                      : AppColors.primary,
                                  shape:
                                      BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _title,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w800,
                                    letterSpacing: 0.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _subtitle,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight.w500,
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // =================================================
                    // OPEN BUTTON
                    // =================================================

                    Container(
                      height: 38,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 11,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primary.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _state.isLive
                                ? 'OPEN'
                                : 'VIEW',
                            style: const TextStyle(
                              color:
                                  AppColors.primary,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            color:
                                AppColors.primary,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
