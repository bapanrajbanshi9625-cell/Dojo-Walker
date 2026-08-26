import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkReachSlider extends StatefulWidget {
  final bool reached;
  final VoidCallback onReached;

  const ActiveWalkReachSlider({
    super.key,
    required this.reached,
    required this.onReached,
  });

  @override
  State<ActiveWalkReachSlider> createState() =>
      _ActiveWalkReachSliderState();
}

class _ActiveWalkReachSliderState
    extends State<ActiveWalkReachSlider> {
  double _position = 0;

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        const double handleSize = 50;

        final double maxPosition =
            (constraints.maxWidth -
                    handleSize)
                .clamp(
                  0.0,
                  double.infinity,
                );

        if (widget.reached) {
          return Container(
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: AppColors.success.withOpacity(.20),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  'Reached Pickup Point',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.success.withOpacity(.20),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Slide to Reach',
                      style: TextStyle(
                        color:
                            AppColors.success,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color:
                          AppColors.success,
                      size: 19,
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color:
                          AppColors.success.withOpacity(.45),
                      size: 19,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: _position,
                top: 2,
                child: GestureDetector(
                  onHorizontalDragUpdate:
                      (DragUpdateDetails details) {
                    setState(() {
                      _position +=
                          details.delta.dx;

                      _position =
                          _position.clamp(
                        0.0,
                        maxPosition,
                      );
                    });
                  },
                  onHorizontalDragEnd:
                      (DragEndDetails details) {
                    if (_position >=
                        maxPosition * .80) {
                      widget.onReached();
                    } else {
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          AppColors.cardBackground,
                      borderRadius:
                          BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.overlay.withOpacity(.16),
                          blurRadius: 8,
                          offset:
                              const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color:
                          AppColors.success,
                      size: 22,
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
