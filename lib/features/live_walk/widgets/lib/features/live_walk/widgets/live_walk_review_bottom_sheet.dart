import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class LiveWalkReviewBottomSheet extends StatefulWidget {
  const LiveWalkReviewBottomSheet({
    super.key,
    required this.distanceKm,
    required this.steps,
    required this.onSubmit,
    this.routePoints = const <Offset>[],
  });

  final double distanceKm;
  final int steps;
  final List<Offset> routePoints;
  final ValueChanged<int> onSubmit;

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

    widget.onSubmit(_rating);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
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
                  borderRadius: BorderRadius.circular(10),
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
                  color: AppColors.success.withValues(
                    alpha: .10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.thumb_up_rounded,
                  color: AppColors.success,
                  size: 38,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Walk Completed!',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'How was your walk?',
                style: TextStyle(
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
                height: 125,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: _RoutePainter(
                    widget.routePoints,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.route_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
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
                      'Distance',
                      Icons.directions_walk_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stat(
                      '${widget.steps}',
                      'Steps',
                      Icons.directions_run_rounded,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) {
                    final int star = index + 1;

                    return IconButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              setState(() {
                                _rating = star;
                              });
                            },
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 38,
                        color: star <= _rating
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // REVIEW
              // ==================================================

              TextField(
                controller: _reviewController,
                enabled: !_submitting,
                maxLines: 3,
                maxLength: 300,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Write a review (optional)',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
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
                      _rating == 0 || _submitting
                          ? null
                          : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 6),

              // ==================================================
              // SKIP
              // ==================================================

              TextButton(
                onPressed: _submitting
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text(
                  'Skip Review',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(
    String value,
    String title,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 25,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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

    final Paint linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    path.moveTo(
      points.first.dx,
      points.first.dy,
    );

    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        points[i].dx,
        points[i].dy,
      );
    }

    canvas.drawPath(
      path,
      linePaint,
    );

    final Paint startPaint = Paint()
      ..color = AppColors.success;

    final Paint endPaint = Paint()
      ..color = AppColors.error;

    canvas.drawCircle(
      points.first,
      7,
      startPaint,
    );

    canvas.drawCircle(
      points.last,
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
