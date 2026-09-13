import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class InstaWalkSearchPanel extends StatefulWidget {
  const InstaWalkSearchPanel({
    super.key,
    required this.searching,
  });

  final bool searching;

  @override
  State<InstaWalkSearchPanel> createState() => _InstaWalkSearchPanelState();
}

class _InstaWalkSearchPanelState extends State<InstaWalkSearchPanel>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.searching) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    if (!_pulseController.isAnimating) {
      _pulseController.repeat();
    }

    if (!_shimmerController.isAnimating) {
      _shimmerController.repeat();
    }
  }

  void _stopAnimations() {
    _pulseController.stop();
    _shimmerController.stop();

    _pulseController.value = 0;
    _shimmerController.value = 0;
  }

  @override
  void didUpdateWidget(covariant InstaWalkSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.searching && !oldWidget.searching) {
      _startAnimations();
    } else if (!widget.searching && oldWidget.searching) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: widget.searching
          ? _SearchingStrip(
              pulseAnimation: _pulseController,
              shimmerAnimation: _shimmerController,
            )
          : const SizedBox.shrink(),
    );
  }
}

class _SearchingStrip extends StatelessWidget {
  const _SearchingStrip({
    required this.pulseAnimation,
    required this.shimmerAnimation,
  });

  final Animation<double> pulseAnimation;
  final Animation<double> shimmerAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 66,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
      ),
      child: Stack(
        children: <Widget>[
          // ========================================================
          // SOFT MOVING LIGHT
          // ========================================================

          AnimatedBuilder(
            animation: shimmerAnimation,
            builder: (context, child) {
              final double position =
                  -0.35 + (shimmerAnimation.value * 1.7);

              return FractionalTranslation(
                translation: Offset(position, 0),
                child: Transform.rotate(
                  angle: -0.18,
                  child: Container(
                    width: 110,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.07),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ========================================================
          // CONTENT
          // ========================================================

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: <Widget>[
                // --------------------------------------------------
                // LIVE SEARCH INDICATOR
                // --------------------------------------------------

                SizedBox(
                  width: 30,
                  height: 30,
                  child: AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (context, child) {
                      final double value = pulseAnimation.value;

                      return Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Container(
                            width: 28 + (value * 2),
                            height: 28 + (value * 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(
                                alpha: 0.08 * (1 - value),
                              ),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.white.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // --------------------------------------------------
                // TEXT
                // --------------------------------------------------

                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Searching for Insta Walk',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.05,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Looking for nearby walk requests',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // --------------------------------------------------
                // SEARCHING DOTS
                // --------------------------------------------------

                _SearchingDots(
                  animation: pulseAnimation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchingDots extends StatelessWidget {
  const _SearchingDots({
    required this.animation,
  });

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double phase = animation.value * 3;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            3,
            (int index) {
              final double distance =
                  (phase - index).abs();

              final double opacity =
                  (1.0 - (distance.clamp(0.0, 1.0) * 0.65))
                      .clamp(0.25, 1.0);

              final double scale =
                  0.75 +
                  ((1.0 - distance.clamp(0.0, 1.0)) * 0.25);

              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: const SizedBox(
                      width: 4,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
