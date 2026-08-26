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

  void _submit() {
    if (_rating == 0 || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    // ==========================================================
    // REVIEW BACKEND
    //
    // अभी review backend connect नहीं किया गया है।
    // बाद में Firestore में rating/review save कर सकते हैं।
    // ==========================================================

    Future<void>.delayed(
      const Duration(
        milliseconds: 350,
      ),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _submitting = false;
        });

        Navigator.of(context).pop();

        widget.onBackToHome();
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          18,
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
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                widget.dogName.trim().isEmpty
                    ? 'Your walk is complete.'
                    : '${widget.dogName.trim()}\'s walk is complete.',
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
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: _RoutePainter(
                    widget.routePoints,
                  ),
                  child:
                      widget.routePoints.length < 2
                          ? const Center(
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
                                  SizedBox(height: 6),
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
                            )
                          : null,
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
                      '${widget.distanceKm.toStringAsFixed(2)} km',
                      'DISTANCE',
                      Icons.route_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _stat(
                      widget.duration,
                      'TIME',
                      Icons.timer_rounded,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _stat(
                      '${widget.steps}',
                      'STEPS',
                      Icons.directions_walk_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // RATING
              // ==================================================

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rate this walk',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: List.generate(
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
                        size: 36,
                        color:
                            star <= _rating
                                ? AppColors.primary
                                : AppColors.border,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 4),

              // ==================================================
              // REVIEW
              // ==================================================

              TextField(
                controller:
                    _reviewController,
                enabled:
                    !_submitting,
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
              // SUBMIT REVIEW
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child:
                    ElevatedButton(
                  onPressed:
                      _rating == 0 ||
                              _submitting
                          ? null
                          : _submit,
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
                  child:
                      _submitting
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
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 4),

              // ==================================================
              // SKIP
              // ==================================================

              TextButton(
                onPressed:
                    _submitting
                        ? null
                        : () {
                            Navigator.of(
                              context,
                            ).pop();

                            widget
                                .onBackToHome();
                          },
                child:
                    const Text(
                  'Skip Review',
                  style:
                      TextStyle(
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

  Widget _stat(
    String value,
    String title,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(14),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Column(
        children: [

          Icon(
            icon,
            color:
                AppColors.primary,
            size: 22,
          ),

          const SizedBox(height: 5),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
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
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 7.5,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: .3,
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

class _RoutePainter
    extends CustomPainter {
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

    double minX =
        points.first.dx;
    double maxX =
        points.first.dx;
    double minY =
        points.first.dy;
    double maxY =
        points.first.dy;

    for (final Offset point
        in points) {
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

    final double width =
        (maxX - minX) == 0
            ? 1
            : maxX - minX;

    final double height =
        (maxY - minY) == 0
            ? 1
            : maxY - minY;

    final double scaleX =
        (size.width - 40) / width;

    final double scaleY =
        (size.height - 40) / height;

    final double scale =
        scaleX < scaleY
            ? scaleX
            : scaleY;

    Offset convert(
      Offset point,
    ) {
      return Offset(
        20 +
            (point.dx - minX) *
                scale,
        20 +
            (maxY - point.dy) *
                scale,
      );
    }

    final Paint linePaint =
        Paint()
          ..color =
              AppColors.primary
          ..strokeWidth = 5
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round
          ..style =
              PaintingStyle.stroke;

    final Path path =
        Path();

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
      linePaint,
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
