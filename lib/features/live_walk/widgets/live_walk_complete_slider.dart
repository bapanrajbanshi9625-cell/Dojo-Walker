import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class LiveWalkCompleteSlider extends StatefulWidget {
  const LiveWalkCompleteSlider({
    super.key,
    required this.enabled,
    required this.onCompleted,
  });

  final bool enabled;
  final VoidCallback onCompleted;

  @override
  State<LiveWalkCompleteSlider> createState() =>
      _LiveWalkCompleteSliderState();
}

class _LiveWalkCompleteSliderState
    extends State<LiveWalkCompleteSlider> {
  double _value = 0.0;

  bool _completed = false;
  bool _loading = false;

  // ============================================================
  // SLIDER CHANGE
  // ============================================================

  void _onChanged(double value) {
    if (!widget.enabled ||
        _completed ||
        _loading) {
      return;
    }

    setState(() {
      _value = value;
    });
  }

  // ============================================================
  // SLIDER END
  // ============================================================

  void _onChangeEnd(double value) {
    if (!widget.enabled ||
        _completed ||
        _loading) {
      return;
    }

    // ----------------------------------------------------------
    // NOT FULLY SLID
    // ----------------------------------------------------------

    if (value < 0.90) {
      setState(() {
        _value = 0.0;
      });

      return;
    }

    // ----------------------------------------------------------
    // COMPLETE
    // ----------------------------------------------------------

    setState(() {
      _value = 1.0;
      _loading = true;
    });

    // Give the UI one frame to show the completed state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      try {
        widget.onCompleted();

        if (!mounted) {
          return;
        }

        setState(() {
          _completed = true;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _value = 0.0;
          _loading = false;
          _completed = false;
        });
      }
    });
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    if (!mounted) {
      return;
    }

    setState(() {
      _value = 0.0;
      _completed = false;
      _loading = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool sliderEnabled =
        widget.enabled &&
        !_completed &&
        !_loading;

    final String title;

    if (_loading) {
      title = 'Completing Walk...';
    } else if (_completed) {
      title = 'Walk Completed';
    } else {
      title = 'Slide to Complete Walk';
    }

    return Container(
      height: 66,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ======================================================
          // TITLE
          // ======================================================

          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 68,
                right: 20,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 180,
                ),
                child: Text(
                  title,
                  key: ValueKey<String>(title),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // SLIDER
          // ======================================================

          Positioned.fill(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 0,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: Colors.white,
                overlayColor:
                    Colors.white.withValues(alpha: .12),
                thumbShape:
                    const _CompleteThumbShape(),
                overlayShape:
                    const RoundSliderOverlayShape(
                  overlayRadius: 24,
                ),
              ),
              child: Slider(
                min: 0.0,
                max: 1.0,
                value: _value,
                onChanged:
                    sliderEnabled
                        ? _onChanged
                        : null,
                onChangeEnd:
                    sliderEnabled
                        ? _onChangeEnd
                        : null,
              ),
            ),
          ),

          // ======================================================
          // LEFT ICON
          // ======================================================

          Positioned(
            left: 18,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 180,
                ),
                child: _loading
                    ? const SizedBox(
                        key: ValueKey<String>(
                          'loading',
                        ),
                        width: 28,
                        height: 28,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<
                                  Color>(
                            AppColors.error,
                          ),
                        ),
                      )
                    : _completed
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey<String>(
                              'completed',
                            ),
                            color: AppColors.success,
                            size: 28,
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                            key: ValueKey<String>(
                              'arrow',
                            ),
                            color: AppColors.error,
                            size: 28,
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CUSTOM THUMB
// ============================================================

class _CompleteThumbShape
    extends SliderComponentShape {
  const _CompleteThumbShape();

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete,
  ) {
    return const Size(52, 52);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // ----------------------------------------------------------
    // WHITE THUMB
    // ----------------------------------------------------------

    final Paint thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      26,
      thumbPaint,
    );

    // ----------------------------------------------------------
    // ARROW
    // ----------------------------------------------------------

    final Paint iconPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.fill;

    final double centerY = center.dy;
    final double arrowX = center.dx - 6;

    final Path arrowPath = Path()
      ..moveTo(
        arrowX,
        centerY - 7,
      )
      ..lineTo(
        arrowX + 8,
        centerY,
      )
      ..lineTo(
        arrowX,
        centerY + 7,
      )
      ..close();

    canvas.drawPath(
      arrowPath,
      iconPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        arrowX - 8,
        centerY - 2,
        10,
        4,
      ),
      iconPaint,
    );
  }
}
