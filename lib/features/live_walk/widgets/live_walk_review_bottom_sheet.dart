import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class LiveWalkReviewBottomSheet extends StatefulWidget {
  const LiveWalkReviewBottomSheet({
    super.key,
    required this.routePoints,
    required this.distanceKm,
    required this.duration,
    required this.steps,
    required this.walkId,
    required this.ownerUid,
    required this.dogName,
    required this.onBackToHome,
  });

  final List<Offset> routePoints;
  final double distanceKm;
  final String duration;
  final int steps;

  final String walkId;
  final String ownerUid;
  final String dogName;

  final VoidCallback onBackToHome;

  @override
  State<LiveWalkReviewBottomSheet> createState() =>
      _LiveWalkReviewBottomSheetState();
}

class _LiveWalkReviewBottomSheetState
    extends State<LiveWalkReviewBottomSheet> {
  int _rating = 0;

  final TextEditingController _reviewController =
      TextEditingController();

  bool _submitting = false;
  bool _finished = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // ============================================================
  // SUBMIT REVIEW
  // ============================================================

  Future<void> _submitReview() async {
    if (_rating == 0 || _submitting || _finished) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    // Review backend can be connected here later.
    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _finished = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    widget.onBackToHome();
  }

  // ============================================================
  // SKIP
  // ============================================================

  void _skipReview() {
    if (_submitting || _finished) {
      return;
    }

    setState(() {
      _finished = true;
    });

    Navigator.of(context).pop();
    widget.onBackToHome();
  }

  // ============================================================
  // RATING LABEL
  // ============================================================

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Needs improvement';
      case 2:
        return 'Could be better';
      case 3:
        return 'Good experience';
      case 4:
        return 'Great experience';
      case 5:
        return 'Excellent walk!';
      default:
        return 'Tap a star to rate your experience';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String dogName = widget.dogName.trim();

    final String subtitle = dogName.isEmpty
        ? 'Your walk has been completed successfully.'
        : '$dogName\'s walk has been completed successfully.';

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HANDLE
              // ==================================================

              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SUCCESS HEADER
              // ==================================================

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(
                          alpha: .10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(
                            alpha: .14,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 38,
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    const Text(
                      'Walk completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // ROUTE CARD
              // ==================================================

              Container(
                width: double.infinity,
                height: 158,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RoutePainter(
                          widget.routePoints,
                        ),
                      ),
                    ),

                    // MAP LABEL
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _MapLabel(
                        icon: Icons.route_rounded,
                        label: 'WALK ROUTE',
                      ),
                    ),

                    if (widget.routePoints.length < 2)
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.route_rounded,
                              color: AppColors.primary,
                              size: 30,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Route preview unavailable',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // WALK SUMMARY
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      icon: Icons.route_rounded,
                      value:
                          '${widget.distanceKm.toStringAsFixed(2)} km',
                      title: 'DISTANCE',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      icon: Icons.schedule_rounded,
                      value: widget.duration,
                      title: 'DURATION',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      icon: Icons.directions_walk_rounded,
                      value: '${widget.steps}',
                      title: 'STEPS',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ==================================================
              // REVIEW CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  15,
                  16,
                  15,
                  15,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How was your walk?',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _ratingLabel,
                      style: TextStyle(
                        color: _rating == 0
                            ? Colors.grey.shade600
                            : AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // STARS
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (int index) {
                          final int star = index + 1;
                          final bool selected =
                              star <= _rating;

                          return Expanded(
                            child: GestureDetector(
                              onTap: _submitting || _finished
                                  ? null
                                  : () {
                                      setState(() {
                                        _rating = star;
                                      });
                                    },
                              child: AnimatedScale(
                                scale: selected ? 1.05 : 1.0,
                                duration:
                                    const Duration(
                                  milliseconds: 140,
                                ),
                                child: Icon(
                                  selected
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 39,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // COMMENT
                    // ==================================================

                    TextField(
                      controller: _reviewController,
                      enabled:
                          !_submitting && !_finished,
                      maxLines: 3,
                      maxLength: 300,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            'Tell us about your experience (optional)',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor:
                            AppColors.cardBackground,
                        counterStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 9,
                        ),
                        contentPadding:
                            const EdgeInsets.fromLTRB(
                          14,
                          13,
                          14,
                          10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                          borderSide:
                              const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // SUBMIT
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _rating == 0 ||
                              _submitting ||
                              _finished
                          ? null
                          : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.border,
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 180),
                    child: _submitting
                        ? const SizedBox(
                            key: ValueKey<String>(
                              'loading',
                            ),
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : _finished
                            ? const Row(
                                key: ValueKey<String>(
                                  'finished',
                                ),
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 21,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'Review submitted',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                  ),
                ),
              ),

              const SizedBox(height: 3),

              // ==================================================
              // SKIP
              // ==================================================

              Center(
                child: TextButton(
                  onPressed:
                      _submitting || _finished
                          ? null
                          : _skipReview,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Colors.grey.shade600,
                  ),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAP LABEL
// ============================================================

class _MapLabel extends StatelessWidget {
  const _MapLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STAT
// ============================================================

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.title,
    required this.icon,
  });

  final String value;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 88,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: .09,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 17,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .45,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ROUTE PAINTER
// ============================================================

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.points);

  final List<Offset> points;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (points.length < 2) {
      return;
    }

    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final Offset point in points) {
      if (point.dx < minX) {
        minX = point.dx;
      }

      if (point.dx > maxX) {
        maxX = point.dx;
      }

      if (point.dy < minY) {
        minY = point.dy;
      }

      if (point.dy > maxY) {
        maxY = point.dy;
      }
    }

    final double rangeX =
        maxX - minX == 0 ? 1 : maxX - minX;

    final double rangeY =
        maxY - minY == 0 ? 1 : maxY - minY;

    const double padding = 24;

    final double availableWidth =
        size.width - padding * 2;

    final double availableHeight =
        size.height - padding * 2;

    final double scaleX =
        availableWidth / rangeX;

    final double scaleY =
        availableHeight / rangeY;

    final double scale =
        scaleX < scaleY ? scaleX : scaleY;

    Offset convert(Offset point) {
      return Offset(
        padding +
            (point.dx - minX) * scale,
        padding +
            (maxY - point.dy) * scale,
      );
    }

    final Path path = Path();

    final Offset first =
        convert(points.first);

    path.moveTo(
      first.dx,
      first.dy,
    );

    for (int i = 1; i < points.length; i++) {
      final Offset point =
          convert(points[i]);

      path.lineTo(
        point.dx,
        point.dy,
      );
    }

    // ==========================================================
    // ROUTE SHADOW
    // ==========================================================

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      path,
      shadowPaint,
    );

    // ==========================================================
    // ROUTE
    // ==========================================================

    final Paint routePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      path,
      routePaint,
    );

    // ==========================================================
    // START
    // ==========================================================

    final Offset start =
        convert(points.first);

    final Paint startOuter = Paint()
      ..color = Colors.white;

    canvas.drawCircle(
      start,
      8,
      startOuter,
    );

    final Paint startPaint = Paint()
      ..color = AppColors.success;

    canvas.drawCircle(
      start,
      5,
      startPaint,
    );

    // ==========================================================
    // END
    // ==========================================================

    final Offset end =
        convert(points.last);

    final Paint endOuter = Paint()
      ..color = Colors.white;

    canvas.drawCircle(
      end,
      8,
      endOuter,
    );

    final Paint endPaint = Paint()
      ..color = AppColors.error;

    canvas.drawCircle(
      end,
      5,
      endPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _RoutePainter oldDelegate,
  ) {
    return oldDelegate.points != points;
  }
}
