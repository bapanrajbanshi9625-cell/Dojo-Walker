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
    if (!widget.enabled || _completed || _loading) {
      return;
    }

    setState(() {
      _value = value.clamp(0.0, 1.0);
    });
  }

  // ============================================================
  // SLIDER END
  // ============================================================

  void _onChangeEnd(double value) {
    if (!widget.enabled || _completed || _loading) {
      return;
    }

    // ----------------------------------------------------------
    // NOT ENOUGH
    // ----------------------------------------------------------

    if (value < 0.88) {
      _resetSlider();
      return;
    }

    // ----------------------------------------------------------
    // COMPLETE
    // ----------------------------------------------------------

    setState(() {
      _value = 1.0;
      _loading = true;
    });

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
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetSlider() {
    if (!mounted) {
      return;
    }

    setState(() {
      _value = 0.0;
    });
  }

  // ============================================================
  // PUBLIC RESET
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
  // TITLE
  // ============================================================

  String get _title {
    if (_loading) {
      return 'Completing walk...';
    }

    if (_completed) {
      return 'Walk completed';
    }

    return 'Slide to complete walk';
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

    final Color backgroundColor =
        _completed
            ? AppColors.success
            : widget.enabled
                ? AppColors.primary
                : Colors.grey.shade400;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 68,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.30),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 7),
          ),
          const BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // ======================================================
          // PREMIUM PROGRESS FILL
          // ======================================================

          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                width:
                    MediaQuery.sizeOf(context).width * _value,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // SUBTLE INNER HIGHLIGHT
          // ======================================================

          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                height: 1,
                color: Colors.white.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
          ),

          // ======================================================
          // TITLE
          // ======================================================

          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 76,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  child: Text(
                    _title,
                    key: ValueKey<String>(_title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.15,
                    ),
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
                disabledActiveTrackColor:
                    Colors.transparent,
                disabledInactiveTrackColor:
                    Colors.transparent,
                overlayColor: Colors.white.withValues(
                  alpha: 0.10,
                ),
                thumbColor: Colors.white,
                disabledThumbColor: Colors.white,
                thumbShape: const _CompleteThumbShape(),
                overlayShape:
                    const RoundSliderOverlayShape(
                  overlayRadius: 28,
                ),
              ),
              child: Slider(
                min: 0,
                max: 1,
                value: _value,
                onChanged:
                    sliderEnabled ? _onChanged : null,
                onChangeEnd:
                    sliderEnabled ? _onChangeEnd : null,
              ),
            ),
          ),

          // ======================================================
          // LEFT THUMB HINT
          // ======================================================

          Positioned(
            left: 8,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 180,
                ),
                child: _loading
                    ? const SizedBox(
                        key: ValueKey<String>('loading'),
                        width: 52,
                        height: 52,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : _completed
                        ? const _CompleteIcon(
                            key: ValueKey<String>(
                              'completed',
                            ),
                          )
                        : const _ArrowIcon(
                            key: ValueKey<String>(
                              'arrow',
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// PREMIUM THUMB
// ==================================================================

class _CompleteThumbShape
    extends SliderComponentShape {
  const _CompleteThumbShape();

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete,
  ) {
    return const Size(54, 54);
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

    // ------------------------------------------------------------
    // PREMIUM SHADOW
    // ------------------------------------------------------------

    final Paint shadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        5,
      );

    canvas.drawCircle(
      center.translate(0, 2),
      26,
      shadowPaint,
    );

    // ------------------------------------------------------------
    // WHITE THUMB
    // ------------------------------------------------------------

    final Paint thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      26,
      thumbPaint,
    );

    // ------------------------------------------------------------
    // SUBTLE INNER RING
    // ------------------------------------------------------------

    final Paint ringPaint = Paint()
      ..color = AppColors.primary.withValues(
        alpha: 0.10,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      center,
      21.5,
      ringPaint,
    );

    // ------------------------------------------------------------
    // ORANGE ARROW
    // ------------------------------------------------------------

    final Paint arrowPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path arrow = Path()
      ..moveTo(
        center.dx - 8,
        center.dy,
      )
      ..lineTo(
        center.dx + 6,
        center.dy,
      )
      ..moveTo(
        center.dx,
        center.dy - 7,
      )
      ..lineTo(
        center.dx + 7,
        center.dy,
      )
      ..lineTo(
        center.dx,
        center.dy + 7,
      );

    canvas.drawPath(
      arrow,
      arrowPaint,
    );
  }
}

// ==================================================================
// PREMIUM ARROW ICON
// ==================================================================

class _ArrowIcon extends StatelessWidget {
  const _ArrowIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: AppColors.primary,
        size: 27,
      ),
    );
  }
}

// ==================================================================
// COMPLETE ICON
// ==================================================================

class _CompleteIcon extends StatelessWidget {
  const _CompleteIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.success,
        size: 28,
      ),
    );
  }
}
