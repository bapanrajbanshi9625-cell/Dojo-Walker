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

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitReview() async {
    if (_rating == 0 || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    // ----------------------------------------------------------
    // REVIEW BACKEND
    //
    // अभी review Firestore में save नहीं किया जा रहा।
    // बाद में यहाँ review service connect कर सकते हैं।
    // ----------------------------------------------------------

    await Future<void>.delayed(
      const Duration(
        milliseconds: 300,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    Navigator.of(context).pop();

    widget.onBackToHome();
  }

  // ============================================================
  // SKIP
  // ============================================================

  void _skipReview() {
    if (_submitting) {
      return;
    }

    Navigator.of(context).pop();

    widget.onBackToHome();
  }

  @override
  Widget build(BuildContext context) {
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
              // SUCCESS
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
                widget.dogName.trim().isEmpty
                    ? 'Great job! Your walk is complete.'
                    : '${widget.dogName}\'s walk is complete.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // ROUTE
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
              // STATS
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: _stat(
                      value:
                          '${widget.distanceKm.toStringAsFixed(2)} km',
                      title: 'DISTANCE',
                      icon:
                          Icons.route_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _stat(
                      value: widget.duration,
                      title: 'TIME',
                      icon:
                          Icons.timer_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _stat(
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

                    return IconButton(
                      onPressed:
                          _submitting
                              ? null
                              : () {
                                  setState(() {
                                    _rating =
                                        star;
                                  });
                                },
                      splashRadius: 24,
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons
                                .star_border_rounded,
                        size: 37,
                        color:
                            star <= _rating
                                ? AppColors
                                    .primary
                                : AppColors
                                    .border,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // ==================================================
              // REVIEW
              // ==================================================

              TextField(
                controller:
                    _reviewController,
                enabled: !_submitting,
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
                              _submitting
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
                    _submitting
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

  // ============================================================
  // STAT
  // ============================================================

  Widget _stat({
    required String value,
    required String title,
    required IconData icon,
  }) {
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

    final double scaleX =
        (size.width - padding * 2) /
            rangeX;

    final double scaleY =
        (size.height - padding * 2) /
            rangeY;

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

    final Paint routePaint =
        Paint()
          ..color =
              AppColors.primary
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round;

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

    final Paint startPaint =
        Paint()
          ..color =
              AppColors.success;

    final Paint endPaint =
        Paint()
          ..color =
              AppColors.error;

    final Offset start =
        convert(points.first);

    final Offset end =
        convert(points.last);

    canvas.drawCircle(
      start,
      7,
      startPaint,
    );

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
    return oldDelegate.points !=
        points;
  }
}
