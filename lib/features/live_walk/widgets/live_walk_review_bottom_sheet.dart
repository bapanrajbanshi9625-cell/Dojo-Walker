// File:
// lib/features/live_walk/widgets/live_walk_review_bottom_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
  // ============================================================
  // REVIEW STATE
  // ============================================================

  int _rating = 0;

  final TextEditingController _noteController =
      TextEditingController();

  bool _saving = false;

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * .88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                // ==================================================
                // HANDLE
                // ==================================================

                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // SUCCESS ICON
                // ==================================================

                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          AppColors.primary.withValues(
                        alpha: .10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Walk Completed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.dogName.trim().isEmpty
                      ? 'How was your walk?'
                      : 'How was your walk with ${widget.dogName.trim()}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // WALK SUMMARY
                // ==================================================

                _buildSummaryCard(),

                const SizedBox(height: 20),

                // ==================================================
                // RATING
                // ==================================================

                const Text(
                  'Rate this walk',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Your feedback helps improve the service.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                _buildRating(),

                const SizedBox(height: 20),

                // ==================================================
                // NOTE
                // ==================================================

                const Text(
                  'Walker Note',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  maxLength: 500,
                  textInputAction:
                      TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText:
                        'Add a note about the walk...',
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterStyle:
                        const TextStyle(
                      color: Colors.black38,
                      fontSize: 10,
                    ),
                    contentPadding:
                        const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color:
                            AppColors.border,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color:
                            AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // SUBMIT
                // ==================================================

                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _saving ? null : _submitReview,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          Colors.black12,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                    child: _saving
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
                            'SUBMIT REVIEW',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: .4,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // SKIP
                // ==================================================

                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: TextButton(
                    onPressed:
                        _saving ? null : _skipReview,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          AppColors.secondary,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Skip Review',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'You can skip the review and return to Home.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              Icons.route_rounded,
              widget.distanceKm < 1
                  ? '${(widget.distanceKm * 1000).round()} m'
                  : '${widget.distanceKm.toStringAsFixed(2)} km',
              'Distance',
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _summaryItem(
              Icons.timer_rounded,
              widget.duration,
              'Duration',
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _summaryItem(
              Icons.directions_walk_rounded,
              widget.steps.toString(),
              'Steps',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 42,
      color: AppColors.border,
    );
  }

  // ============================================================
  // RATING
  // ============================================================

  Widget _buildRating() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: List<Widget>.generate(
        5,
        (int index) {
          final int star =
              index + 1;

          final bool selected =
              star <= _rating;

          return GestureDetector(
            behavior:
                HitTestBehavior.opaque,
            onTap: _saving
                ? null
                : () {
                    setState(() {
                      _rating = star;
                    });
                  },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 5,
              ),
              child: Icon(
                selected
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 42,
                color: selected
                    ? AppColors.primary
                    : Colors.black26,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SUBMIT REVIEW
  // ============================================================

  Future<void> _submitReview() async {
    if (_saving) {
      return;
    }

    // Rating optional hai.
    // 0 hone par bhi review save ho sakta hai.
    setState(() {
      _saving = true;
    });

    try {
      await _saveReview();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      widget.onBackToHome();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Review save failed: ${_cleanError(error)}',
            ),
            backgroundColor:
                AppColors.error,
            behavior:
                SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ============================================================
  // SKIP REVIEW
  // ============================================================

  void _skipReview() {
    if (_saving || !mounted) {
      return;
    }

    // Close review sheet first.
    Navigator.of(context).pop();

    // LiveWalkScreen will then return to Home.
    widget.onBackToHome();
  }

  // ============================================================
  // SAVE REVIEW
  //
  // Collection:
  //
  // walk_history/{walkId}
  //
  // Existing walk history document update hoga.
  // New document create nahi hoga unless it does not exist.
  // ============================================================

  Future<void> _saveReview() async {
    final String walkId =
        widget.walkId.trim();

    if (walkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final String note =
        _noteController.text.trim();

    final DocumentReference<
            Map<String, dynamic>>
        historyRef =
        _firestore
            .collection('walk_history')
            .doc(walkId);

    // ==========================================================
    // REVIEW DATA
    // ==========================================================

    final Map<String, dynamic> reviewData =
        <String, dynamic>{
      'rating': _rating,
      'walkerNote': note,
      'reviewSubmitted': true,
      'reviewedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // SAVE
    // ==========================================================

    await historyRef.set(
      reviewData,
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // ERROR CLEAN
  // ============================================================

  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }
}
