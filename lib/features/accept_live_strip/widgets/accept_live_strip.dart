import 'package:flutter/material.dart';

import '../models/accept_live_strip_data.dart';
import '../services/accept_live_strip_trigger.dart';

class AcceptLiveStrip extends StatelessWidget {
  const AcceptLiveStrip({
    super.key,
    required this.onTap,
  });

  final ValueChanged<AcceptLiveStripData> onTap;

  static const Color _acceptedBlue = Color(0xFF1976D2);
  static const Color _readyOrange = Color(0xFFD95F00);
  static const Color _liveOrange = Color(0xFFD95F00);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AcceptLiveStripData>(
      stream: AcceptLiveStripTrigger.instance.watch(),
      initialData: const AcceptLiveStripData.hidden(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? const AcceptLiveStripData.hidden();

        if (data.isHidden) {
          return const SizedBox.shrink();
        }

        final bool isAccepted = data.isAccepted;
        final bool isReady = data.isReady;
        final bool isLive = data.isLive;

        final Color baseColor = isLive
            ? _liveOrange
            : isReady
                ? _readyOrange
                : _acceptedBlue;

        final String title = isLive
            ? 'LIVE WALK'
            : isReady
                ? 'READY TO START'
                : 'WALK ACCEPTED';

        final String subtitle = isLive
            ? 'Tap to open your live walk'
            : isReady
                ? 'Tap to start your walk'
                : 'Tap to continue to pickup';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(data),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    baseColor,
                    Color.alphaBlend(
                      Colors.white.withValues(alpha: 0.08),
                      baseColor,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.24),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _StatusIcon(
                    isAccepted: isAccepted,
                    isReady: isReady,
                    isLive: isLive,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.isAccepted,
    required this.isReady,
    required this.isLive,
  });

  final bool isAccepted;
  final bool isReady;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final IconData icon;

    if (isLive) {
      icon = Icons.directions_walk_rounded;
    } else if (isReady) {
      icon = Icons.play_arrow_rounded;
    } else {
      icon = Icons.navigation_rounded;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 21,
      ),
    );
  }
}
