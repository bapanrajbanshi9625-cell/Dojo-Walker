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
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.searching) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant InstaWalkSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.searching && !oldWidget.searching) {
      _pulseController.repeat();
    } else if (!widget.searching && oldWidget.searching) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: widget.searching
          ? _SearchingStrip(
              pulseAnimation: _pulseController,
            )
          : const SizedBox.shrink(),
    );
  }
}

class _SearchingStrip extends StatelessWidget {
  const _SearchingStrip({
    required this.pulseAnimation,
  });

  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46,
      margin: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        color: DojoWalkerColors.primary,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              final double value = pulseAnimation.value;

              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 18 + (value * 8),
                    height: 18 + (value * 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DojoWalkerColors.white.withValues(
                        alpha: 0.14 * (1 - value),
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: DojoWalkerColors.white,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Searching for Insta Walk',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: DojoWalkerColors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
          _SearchingDots(animation: pulseAnimation),
          const SizedBox(width: 16),
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
          children: List<Widget>.generate(3, (int index) {
            final double distance = (phase - index).abs();
            final double opacity =
                (1.0 - distance.clamp(0.0, 1.0) * 0.55).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Opacity(
                opacity: opacity,
                child: const SizedBox(
                  width: 3,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DojoWalkerColors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
