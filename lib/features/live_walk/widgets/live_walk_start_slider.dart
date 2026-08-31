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
  double _position = 0.0;

  bool _started = false;

  static const double _height = 60.0;
  static const double _handleSize = 50.0;
  static const double _horizontalPadding = 5.0;

  // ============================================================
  // RESET
  // ============================================================

  void _reset() {
    if (!mounted) {
      return;
    }

    setState(() {
      _position = 0.0;
    });
  }

  // ============================================================
  // DRAG UPDATE
  // ============================================================

  void _onDragUpdate(
    DragUpdateDetails details,
    double maxPosition,
  ) {
    if (!widget.enabled || _started) {
      return;
    }

    setState(() {
      _position += details.delta.dx;

      _position = _position.clamp(
        0.0,
        maxPosition,
      );
    });
  }

  // ============================================================
  // DRAG END
  // ============================================================

  void _onDragEnd(
    DragEndDetails details,
    double maxPosition,
  ) {
    if (!widget.enabled || _started) {
      return;
    }

    final double threshold =
        maxPosition * 0.82;

    if (_position >= threshold) {
      setState(() {
        _position = maxPosition;
        _started = true;
      });

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          widget.onStarted();
        },
      );
    } else {
      _reset();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final double width =
            constraints.maxWidth;

        final double maxPosition =
            (width -
                    (_horizontalPadding * 2) -
                    _handleSize)
                .clamp(
          0.0,
          double.infinity,
        );

        final bool enabled =
            widget.enabled && !_started;

        final double progress =
            maxPosition <= 0
                ? 0.0
                : (_position / maxPosition)
                    .clamp(0.0, 1.0);

        return AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: _height,
          width: double.infinity,
          padding: const EdgeInsets.all(
            _horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primary.withValues(
                    alpha: 0.08,
                  )
                : Colors.grey.withValues(
                    alpha: 0.08,
                  ),
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withValues(
                      alpha: 0.16,
                    )
                  : Colors.grey.withValues(
                      alpha: 0.14,
                    ),
            ),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // ==================================================
                // PROGRESS FILL
                // ==================================================

                Positioned.fill(
                  child: Align(
                    alignment:
                        Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration:
                            BoxDecoration(
                          color: AppColors.primary
                              .withValues(
                            alpha: 0.14,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // CENTER TEXT
                // ==================================================

                Center(
                  child: IgnorePointer(
                    child: AnimatedSwitcher(
                      duration:
                          const Duration(
                        milliseconds: 160,
                      ),
                      child: Text(
                        _started
                            ? 'Walk Started'
                            : 'Slide to Start Walk',
                        key: ValueKey<String>(
                          _started
                              ? 'started'
                              : 'start',
                        ),
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: enabled
                              ? AppColors.primary
                              : Colors.grey,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // RIGHT CHEVRONS
                // ==================================================

                if (!_started)
                  Positioned(
                    right: 14,
                    child: IgnorePointer(
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .chevron_right_rounded,
                            size: 19,
                            color: enabled
                                ? AppColors.primary
                                    .withValues(
                                    alpha: 0.32,
                                  )
                                : Colors.grey
                                    .withValues(
                                    alpha: 0.25,
                                  ),
                          ),
                          Icon(
                            Icons
                                .chevron_right_rounded,
                            size: 19,
                            color: enabled
                                ? AppColors.primary
                                    .withValues(
                                    alpha: 0.58,
                                  )
                                : Colors.grey
                                    .withValues(
                                    alpha: 0.35,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ==================================================
                // SLIDE HANDLE
                // ==================================================

                AnimatedPositioned(
                  duration:
                      const Duration(
                    milliseconds: 70,
                  ),
                  curve: Curves.easeOut,
                  left: _position,
                  top: 0,
                  child: GestureDetector(
                    behavior:
                        HitTestBehavior.opaque,
                    onHorizontalDragUpdate:
                        enabled
                            ? (
                                DragUpdateDetails
                                    details,
                              ) {
                                _onDragUpdate(
                                  details,
                                  maxPosition,
                                );
                              }
                            : null,
                    onHorizontalDragEnd:
                        enabled
                            ? (
                                DragEndDetails
                                    details,
                              ) {
                                _onDragEnd(
                                  details,
                                  maxPosition,
                                );
                              }
                            : null,
                    child: AnimatedContainer(
                      duration:
                          const Duration(
                        milliseconds: 160,
                      ),
                      width: _handleSize,
                      height: _handleSize,
                      decoration:
                          BoxDecoration(
                        color: enabled
                            ? Colors.white
                            : const Color(
                                0xFFE5E5E5,
                              ),
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(
                              alpha: 0.12,
                            ),
                            blurRadius: 10,
                            offset:
                                const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration:
                            const Duration(
                          milliseconds: 160,
                        ),
                        child: Icon(
                          _started
                              ? Icons.check_rounded
                              : Icons
                                  .arrow_forward_rounded,
                          key: ValueKey<bool>(
                            _started,
                          ),
                          color: enabled
                              ? AppColors.primary
                              : Colors.grey,
                          size: 25,
                        ),
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
