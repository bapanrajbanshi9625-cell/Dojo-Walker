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

  static const double _handleSize = 50.0;

  void _reset() {
    if (!mounted) {
      return;
    }

    setState(() {
      _position = 0.0;
    });
  }

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
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: 0.20,
              ),
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // ------------------------------------------------
              // TEXT
              // ------------------------------------------------

              Center(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Slide to Start Walk',
                      style: TextStyle(
                        color: widget.enabled
                            ? AppColors.primary
                            : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.enabled
                          ? AppColors.primary
                          : Colors.grey,
                      size: 20,
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.enabled
                          ? AppColors.primary
                              .withValues(alpha: 0.55)
                          : Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------
              // SLIDER HANDLE
              // ------------------------------------------------

              Positioned(
                left: _position,
                top: 3,
                child: GestureDetector(
                  onHorizontalDragUpdate:
                      widget.enabled
                          ? (DragUpdateDetails details) {
                              setState(() {
                                _position +=
                                    details.delta.dx;

                                _position =
                                    _position.clamp(
                                  0.0,
                                  maxPosition,
                                );
                              });
                            }
                          : null,
                  onHorizontalDragEnd:
                      widget.enabled
                          ? (DragEndDetails details) {
                              if (_position >=
                                  maxPosition * 0.80) {
                                setState(() {
                                  _position =
                                      maxPosition;
                                });

                                widget.onStarted();
                              } else {
                                _reset();
                              }
                            }
                          : null,
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? Colors.white
                          : const Color(0xFFE0E0E0),
                      borderRadius:
                          BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: widget.enabled
                          ? AppColors.primary
                          : Colors.grey,
                      size: 25,
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
