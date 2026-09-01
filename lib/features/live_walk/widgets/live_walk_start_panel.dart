import 'package:flutter/material.dart';

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
    final bool canStart = enabled && !starting;

    return Positioned(
      left: 14,
      right: 14,
      bottom: 90,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LiveWalkStartSlider(
            enabled: canStart,
            onStarted: onStarted,
          ),
        ),
      ),
    );
  }
}
