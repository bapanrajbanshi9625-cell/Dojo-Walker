import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class WelcomeContainer extends StatefulWidget {
  const WelcomeContainer({
    super.key,
  });

  @override
  State<WelcomeContainer> createState() =>
      _WelcomeContainerState();
}

class _WelcomeContainerState
    extends State<WelcomeContainer> {
  final List<_WelcomeMessage> _messages = const [
    _WelcomeMessage(
      title: 'Welcome back 👋',
      subtitle: 'You and Buddy are ready to walk.',
    ),
    _WelcomeMessage(
      title: 'Keep moving 🐾',
      subtitle: 'Every walk makes a happy dog.',
    ),
    _WelcomeMessage(
      title: 'Ready for today? ✨',
      subtitle: 'Let’s make today’s walks great.',
    ),
  ];

  int _currentIndex = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _currentIndex =
              (_currentIndex + 1) % _messages.length;
        });
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
    final _WelcomeMessage message =
        _messages[_currentIndex];

    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: DojoColors.dark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: .07,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ======================================================
          // PAW ICON
          // ======================================================

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DojoColors.orange.withValues(
                alpha: .14,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DojoColors.orange.withValues(
                  alpha: .40,
                ),
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: DojoColors.orange,
              size: 32,
            ),
          ),

          const SizedBox(width: 13),

          // ======================================================
          // RIGHT → LEFT MESSAGE
          // ======================================================

          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 750),
                reverseDuration:
                    const Duration(milliseconds: 750),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder:
                    (child, animation) {
                  final bool isNewMessage =
                      child.key ==
                          ValueKey<int>(
                            _currentIndex,
                          );

                  final Animation<Offset>
                      slideAnimation =
                      Tween<Offset>(
                    begin: isNewMessage
                        ? const Offset(1, 0)
                        : const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );

                  return SlideTransition(
                    position: slideAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey<int>(
                    _currentIndex,
                  ),
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      message.subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// WELCOME MESSAGE
// ================================================================

class _WelcomeMessage {
  final String title;
  final String subtitle;

  const _WelcomeMessage({
    required this.title,
    required this.subtitle,
  });
}
