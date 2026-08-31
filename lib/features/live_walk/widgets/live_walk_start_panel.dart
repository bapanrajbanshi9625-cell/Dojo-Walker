import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'live_walk_start_slider.dart';

class LiveWalkStartPanel extends StatelessWidget {
  const LiveWalkStartPanel({
    super.key,
    required this.enabled,
    required this.starting,
    required this.onStarted,
  });

  final bool enabled;
  final bool starting;
  final VoidCallback onStarted;

  @override
  Widget build(BuildContext context) {
    final bool canStart =
        enabled && !starting;

    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            10,
            10,
            10,
            10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.97,
            ),
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.75,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.14,
                ),
                blurRadius: 22,
                offset: const Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  5,
                  1,
                  5,
                  9,
                ),
                child: Row(
                  children: [
                    // --------------------------------------------
                    // GPS STATUS
                    // --------------------------------------------

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration:
                          BoxDecoration(
                        color: AppColors.success
                            .withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        border: Border.all(
                          color: AppColors.success
                              .withValues(
                            alpha: 0.14,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .gps_fixed_rounded,
                            color:
                                AppColors.success,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'GPS READY',
                            style:
                                TextStyle(
                              color: AppColors
                                  .secondary,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing:
                                  0.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // --------------------------------------------
                    // STARTING STATUS
                    // --------------------------------------------

                    AnimatedSwitcher(
                      duration:
                          const Duration(
                        milliseconds: 180,
                      ),
                      child: starting
                          ? const Row(
                              key: ValueKey(
                                'starting',
                              ),
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 15,
                                  height: 15,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                      AppColors
                                          .primary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  'Starting...',
                                  style:
                                      TextStyle(
                                    color:
                                        AppColors
                                            .secondary,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              canStart
                                  ? 'READY TO GO'
                                  : 'WAITING',
                              key: ValueKey<
                                  String>(
                                canStart
                                    ? 'ready'
                                    : 'waiting',
                              ),
                              style:
                                  TextStyle(
                                color: canStart
                                    ? AppColors
                                        .success
                                    : Colors.grey,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w900,
                                letterSpacing:
                                    0.4,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // START SLIDER
              // ==================================================

              LiveWalkStartSlider(
                enabled: canStart,
                onStarted: onStarted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
