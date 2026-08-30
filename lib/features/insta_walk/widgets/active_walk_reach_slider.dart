import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkReachSlider extends StatefulWidget {
  final bool reached;
  final bool starting;
  final VoidCallback onReached;

  const ActiveWalkReachSlider({
    super.key,
    required this.reached,
    required this.starting,
    required this.onReached,
  });

  @override
  State<ActiveWalkReachSlider> createState() =>
      _ActiveWalkReachSliderState();
}

class _ActiveWalkReachSliderState
    extends State<ActiveWalkReachSlider> {
  double _position = 0;

  static const double _handleSize = 50;
  static const double _containerHeight = 56;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final double maxPosition =
            (constraints.maxWidth - _handleSize)
                .clamp(0.0, double.infinity);

        // ============================================================
        // REACHED STATE
        // ============================================================

        if (widget.reached) {
          return Container(
            height: _containerHeight,
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: AppColors.success.withValues(
                  alpha: .28,
                ),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: .12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Reached Pickup Point',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .1,
                  ),
                ),
              ],
            ),
          );
        }

        // ============================================================
        // SLIDER
        // ============================================================

        return Container(
          height: _containerHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.border,
              width: 1.1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // ======================================================
              // PROGRESS BACKGROUND
              // ======================================================

              Positioned(
                left: 3,
                top: 3,
                bottom: 3,
                child: Container(
                  width: _position + _handleSize,
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth - 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: .10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              // ======================================================
              // CENTER TEXT
              // ======================================================

              IgnorePointer(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Slide to Reach',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.success,
                        size: 19,
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.success.withValues(
                          alpha: .40,
                        ),
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),

              // ======================================================
              // SLIDER HANDLE
              // ======================================================

              Positioned(
                left: _position,
                top: 3,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate:
                      widget.starting
                          ? null
                          : (DragUpdateDetails details) {
                              setState(() {
                                _position += details.delta.dx;

                                _position = _position.clamp(
                                  0.0,
                                  maxPosition,
                                );
                              });
                            },
                  onHorizontalDragEnd:
                      widget.starting
                          ? null
                          : (DragEndDetails details) {
                              if (_position >=
                                  maxPosition * .80) {
                                setState(() {
                                  _position = maxPosition;
                                });

                                widget.onReached();
                              } else {
                                setState(() {
                                  _position = 0;
                                });
                              }
                            },
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.overlay.withValues(
                            alpha: .18,
                          ),
                          blurRadius: 9,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: widget.starting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    AppColors.buttonText,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.buttonText,
                            size: 23,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
