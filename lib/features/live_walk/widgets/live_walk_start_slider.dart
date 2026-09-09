import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class LiveWalkStartSlider extends StatefulWidget {
  const LiveWalkStartSlider({
    super.key,
    required this.onStarted,
    this.enabled = true,
  });

  final VoidCallback onStarted;
  final bool enabled;

  @override
  State<LiveWalkStartSlider> createState() =>
      _LiveWalkStartSliderState();
}

class _LiveWalkStartSliderState
    extends State<LiveWalkStartSlider> {
  double _dragValue = 0.0;
  bool _completed = false;

  static const double _horizontalPadding = 5.0;
  static const double _thumbSize = 54.0;

  void _reset() {
    if (!mounted) {
      return;
    }

    setState(() {
      _dragValue = 0.0;
      _completed = false;
    });
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    double availableWidth,
  ) {
    if (!widget.enabled || _completed) {
      return;
    }

    final double maxDrag =
        availableWidth - _thumbSize - (_horizontalPadding * 2);

    if (maxDrag <= 0) {
      return;
    }

    final double newValue =
        (_dragValue + details.delta.dx / maxDrag)
            .clamp(0.0, 1.0);

    setState(() {
      _dragValue = newValue;
    });

    if (_dragValue >= 0.90) {
      _completeSlider();
    }
  }

  void _handleDragEnd(
    DragEndDetails details,
    double availableWidth,
  ) {
    if (!widget.enabled || _completed) {
      return;
    }

    if (_dragValue >= 0.90) {
      _completeSlider();
      return;
    }

    _reset();
  }

  void _completeSlider() {
    if (!widget.enabled || _completed) {
      return;
    }

    setState(() {
      _dragValue = 1.0;
      _completed = true;
    });

    // IMPORTANT:
    // This widget does NOT start GPS.
    // This widget does NOT write to Firestore.
    // This widget does NOT start the walk directly.
    //
    // LiveWalkStartScreen receives this callback and calls:
    //   await _controller.startWalk();
    //
    // After the real walk starts, LiveWalkStartScreen
    // navigates to LiveWalkScreen.
    widget.onStarted();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final double width = constraints.maxWidth;

        final double maxDrag =
            width - _thumbSize - (_horizontalPadding * 2);

        final double thumbLeft =
            _horizontalPadding +
            (maxDrag > 0
                ? maxDrag * _dragValue
                : 0);

        final bool disabled = !widget.enabled;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: disabled ? 0.55 : 1.0,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: .10,
              ),
              borderRadius:
                  BorderRadius.circular(34),
              border: Border.all(
                color: AppColors.primary.withValues(
                  alpha: .22,
                ),
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // ==================================================
                // SLIDER TEXT
                // ==================================================

                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 62,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child: Text(
                          _completed
                              ? 'Starting...'
                              : 'Slide to Start Walk',
                          key: ValueKey<bool>(
                            _completed,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // THUMB
                // ==================================================

                AnimatedPositioned(
                  duration: _completed
                      ? const Duration(milliseconds: 160)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  left: thumbLeft,
                  top: _horizontalPadding,
                  child: GestureDetector(
                    behavior:
                        HitTestBehavior.opaque,
                    onHorizontalDragUpdate:
                        disabled
                            ? null
                            : (details) {
                                _handleDragUpdate(
                                  details,
                                  width,
                                );
                              },
                    onHorizontalDragEnd:
                        disabled
                            ? null
                            : (details) {
                                _handleDragEnd(
                                  details,
                                  width,
                                );
                              },
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: disabled
                            ? Colors.grey
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _completed
                            ? Icons.check_rounded
                            : Icons
                                .arrow_forward_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
