import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkReachSlider extends StatefulWidget {
  final bool starting;
  final VoidCallback onReached;

  const ActiveWalkReachSlider({
    super.key,
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
              // ====================================================
              // SLIDER PROGRESS
              // ====================================================

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
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              // ====================================================
              // CENTER TEXT
              // ====================================================

              IgnorePointer(
                child: Center(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.starting
                            ? 'Reaching Owner...'
                            : 'Slide to Reach',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (!widget.starting)
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.success,
                          size: 19,
                        ),
                      if (!widget.starting)
                        Icon(
                          Icons.chevron_right_rounded,
                          color:
                              AppColors.success.withValues(
                            alpha: 0.40,
                          ),
                          size: 19,
                        ),
                    ],
                  ),
                ),
              ),

              // ====================================================
              // HANDLE
              // ====================================================

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

                                _position =
                                    _position.clamp(
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
                                  maxPosition * 0.80) {
                                setState(() {
                                  _position =
                                      maxPosition;
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
                      borderRadius:
                          BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.overlay.withValues(
                            alpha: 0.18,
                          ),
                          blurRadius: 9,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: widget.starting
                        ? const Center(
                            child: SizedBox(
                              width: 19,
                              height: 19,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  AppColors.buttonText,
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
