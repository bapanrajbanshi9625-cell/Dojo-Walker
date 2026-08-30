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
    if (_rating == 0 ||
        _submitting ||
        _finished) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    // ----------------------------------------------------------
    // REVIEW BACKEND
    //
    // Intentionally no Firestore write here.
    // Review backend can be connected later.
    // ----------------------------------------------------------

    await Future<void>.delayed(
      const Duration(
        milliseconds: 350,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _finished = true;
    });

    await Future<void>.delayed(
      const Duration(
        milliseconds: 250,
      ),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    widget.onBackToHome();
  }

  // ============================================================
  // SKIP REVIEW
  // ============================================================

  void _skipReview() {
    if (_submitting ||
        _finished) {
      return;
    }

    _finished = true;

    Navigator.of(context).pop();

    widget.onBackToHome();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String cleanDogName =
        widget.dogName.trim();

    final String subtitle =
        cleanDogName.isEmpty
            ? 'Great job! Your walk is complete.'
            : '$cleanDogName\'s walk is complete.';

    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // HANDLE
              // ==================================================

              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // SUCCESS ICON
              // ==================================================

              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color:
                      AppColors.success.withValues(
                    alpha: .10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Walk Completed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // ROUTE PREVIEW
              // ==================================================

              Container(
                width: double.infinity,
                height: 145,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(18),
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

                    if (widget.routePoints.length < 2)
                      const Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.route_rounded,
                              color:
                                  AppColors.primary,
                              size: 32,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Walk route',
                              style: TextStyle(
                                color:
                                    AppColors.secondary,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w800,
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
              // WALK STATS
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      value:
                          '${widget.distanceKm.toStringAsFixed(2)} km',
                      title: 'DISTANCE',
                      icon:
                          Icons.route_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _Stat(
                      value: widget.duration,
                      title: 'TIME',
                      icon:
                          Icons.timer_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _Stat(
                      value:
                          '${widget.steps}',
                      title: 'STEPS',
                      icon:
                          Icons
                              .directions_walk_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // RATING
              // ==================================================

              const Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Rate this walk',
                  style: TextStyle(
                    color:
                        AppColors.secondary,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children:
                    List.generate(
                  5,
                  (int index) {
                    final int star =
                        index + 1;

                    final bool selected =
                        star <= _rating;

                    return IconButton(
                      onPressed:
                          _submitting ||
                                  _finished
                              ? null
                              : () {
                                  setState(() {
                                    _rating =
                                        star;
                                  });
                                },
                      splashRadius: 24,
                      icon: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons
                                .star_border_rounded,
                        size: 37,
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // ==================================================
              // OPTIONAL REVIEW
              // ==================================================

              TextField(
                controller:
                    _reviewController,
                enabled:
                    !_submitting &&
                    !_finished,
                maxLines: 3,
                maxLength: 300,
                textInputAction:
                    TextInputAction.done,
                decoration:
                    InputDecoration(
                  hintText:
                      'Write a review (optional)',
                  hintStyle:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor:
                      AppColors.background,
                  counterStyle:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                  contentPadding:
                      const EdgeInsets
                          .fromLTRB(
                    14,
                    13,
                    14,
                    10,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          AppColors.border,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          AppColors.border,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // SUBMIT
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _rating == 0 ||
                              _submitting ||
                              _finished
                          ? null
                          : _submitReview,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        AppColors.border,
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 5),

              // ==================================================
              // SKIP
              // ==================================================

              TextButton(
                onPressed:
                    _submitting ||
                            _finished
                        ? null
                        : _skipReview,
                child: const Text(
                  'Skip Review',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight:
                        FontWeight.w700,
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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),

          const SizedBox(height: 5),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color:
                  AppColors.secondary,
              fontSize: 13,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 7.5,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: .4,
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
  const _RoutePainter(
    this.points,
  );

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
        maxX - minX == 0
            ? 1
            : maxX - minX;

    final double rangeY =
        maxY - minY == 0
            ? 1
            : maxY - minY;

    const double padding = 20;

    final double availableWidth =
        size.width - padding * 2;

    final double availableHeight =
        size.height - padding * 2;

    final double scaleX =
        availableWidth / rangeX;

    final double scaleY =
        availableHeight / rangeY;

    final double scale =
        scaleX < scaleY
            ? scaleX
            : scaleY;

    Offset convert(
      Offset point,
    ) {
      return Offset(
        padding +
            (point.dx - minX) * scale,
        padding +
            (maxY - point.dy) * scale,
      );
    }

    final Paint routePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();

    final Offset first =
        convert(points.first);

    path.moveTo(
      first.dx,
      first.dy,
    );

    for (int i = 1;
        i < points.length;
        i++) {
      final Offset point =
          convert(points[i]);

      path.lineTo(
        point.dx,
        point.dy,
      );
    }

    canvas.drawPath(
      path,
      routePaint,
    );

    // ----------------------------------------------------------
    // START
    // ----------------------------------------------------------

    final Paint startPaint = Paint()
      ..color = AppColors.success;

    final Offset start =
        convert(points.first);

    canvas.drawCircle(
      start,
      7,
      startPaint,
    );

    // ----------------------------------------------------------
    // END
    // ----------------------------------------------------------

    final Paint endPaint = Paint()
      ..color = AppColors.error;

    final Offset end =
        convert(points.last);

    canvas.drawCircle(
      end,
      7,
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
