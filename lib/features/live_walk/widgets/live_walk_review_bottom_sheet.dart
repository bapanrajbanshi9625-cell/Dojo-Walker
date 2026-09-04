import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final TextEditingController _noteController =
      TextEditingController();

  bool _saving = false;
  bool _navigatingHome = false;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset =
        MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            22 + bottomInset,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: <Widget>[
              // ==================================================
              // HANDLE
              // ==================================================

              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // SUCCESS HEADER
              // ==================================================

              _buildSuccessHeader(),

              const SizedBox(height: 20),

              // ==================================================
              // WALK SUMMARY
              // ==================================================

              _buildSummaryCard(),

              const SizedBox(height: 22),

              // ==================================================
              // RATING
              // ==================================================

              const Text(
                'How was the walk?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Your feedback helps us improve the experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              _buildRating(),

              const SizedBox(height: 22),

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

              _buildNoteField(),

              const SizedBox(height: 16),

              // ==================================================
              // SUBMIT
              // ==================================================

              _buildSubmitButton(),

              const SizedBox(height: 8),

              // ==================================================
              // SKIP
              // ==================================================

              _buildSkipButton(),

              const SizedBox(height: 3),

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
    );
  }

  // ============================================================
  // SUCCESS HEADER
  // ============================================================

  Widget _buildSuccessHeader() {
    return Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(
              alpha: 0.10,
            ),
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: 0.16,
              ),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.primary,
            size: 42,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Walk Completed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          widget.dogName.trim().isEmpty
              ? 'Great job! Your walk has been completed.'
              : 'Great job walking ${widget.dogName.trim()}!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.08,
          ),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _summaryItem(
              icon: Icons.route_rounded,
              value: widget.distanceKm < 1
                  ? '${(widget.distanceKm * 1000).round()} m'
                  : '${widget.distanceKm.toStringAsFixed(2)} km',
              label: 'Distance',
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _summaryItem(
              icon: Icons.timer_outlined,
              value: widget.duration,
              label: 'Duration',
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _summaryItem(
              icon: Icons.directions_walk_rounded,
              value: widget.steps.toString(),
              label: 'Steps',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.09,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
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
      height: 52,
      color: AppColors.border,
    );
  }

  // ============================================================
  // RATING
  // ============================================================

  Widget _buildRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(
        5,
        (int index) {
          final int star = index + 1;
          final bool selected = star <= _rating;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _saving
                ? null
                : () {
                    setState(() {
                      _rating = star;
                    });
                  },
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(
                        alpha: 0.10,
                      )
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(
                          alpha: 0.20,
                        )
                      : AppColors.border,
                ),
              ),
              child: Icon(
                selected
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 30,
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
  // NOTE FIELD
  // ============================================================

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 4,
      maxLength: 500,
      textInputAction: TextInputAction.newline,
      enabled: !_saving,
      decoration: InputDecoration(
        hintText: 'Add a note about the walk...',
        hintStyle: const TextStyle(
          color: Colors.black35,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        counterStyle: const TextStyle(
          color: Colors.black38,
          fontSize: 10,
        ),
        contentPadding: const EdgeInsets.all(15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border.withValues(
              alpha: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _saving ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.primary.withValues(
            alpha: 0.55,
          ),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 160),
          child: _saving
              ? const SizedBox(
                  key: ValueKey<String>('saving'),
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
              : const Row(
                  key: ValueKey<String>('submit'),
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'SUBMIT REVIEW',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // SKIP BUTTON
  // ============================================================

  Widget _buildSkipButton() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextButton(
        onPressed:
            _saving ? null : _skipReview,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Skip Review',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_rounded,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitReview() async {
    if (_saving || _navigatingHome) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _saveReview();

      if (!mounted) {
        return;
      }

      await _returnHome();
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }

  // ============================================================
  // SKIP
  // ============================================================

  Future<void> _skipReview() async {
    if (_saving || _navigatingHome) {
      return;
    }

    await _returnHome();
  }

  // ============================================================
  // CLOSE SHEET THEN RETURN HOME
  //
  // IMPORTANT:
  // Do NOT pop the LiveWalkScreen here.
  // The parent screen owns the navigation.
  // ============================================================

  Future<void> _returnHome() async {
    if (_navigatingHome) {
      return;
    }

    _navigatingHome = true;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    await Future<void>.delayed(
      const Duration(milliseconds: 120),
    );

    widget.onBackToHome();
  }

  // ============================================================
  // SAVE REVIEW
  // ============================================================

  Future<void> _saveReview() async {
    final String walkId =
        widget.walkId.trim();

    if (walkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not signed in.',
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    final String ownerUid =
        widget.ownerUid.trim();

    final String note =
        _noteController.text.trim();

    final Timestamp now =
        Timestamp.now();

    final Map<String, dynamic> reviewData =
        <String, dynamic>{
      'walkId': walkId,
      'walkerUid': walkerUid,
      if (ownerUid.isNotEmpty)
        'ownerUid': ownerUid,
      'rating': _rating,
      'note': note,
      'reviewSubmitted': true,
      'reviewedAt': now,
    };

    final DocumentReference<
            Map<String, dynamic>>
        walkerReviewRef =
        _firestore
            .collection('walkerReviews')
            .doc(walkId);

    final DocumentReference<
            Map<String, dynamic>>
        historyRef =
        _firestore
            .collection('walk_history')
            .doc(walkId);

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      walkerReviewRef,
      reviewData,
      SetOptions(merge: true),
    );

    batch.set(
      historyRef,
      <String, dynamic>{
        'walkerReview': reviewData,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    if (error is FirebaseException) {
      final String message =
          error.message?.trim() ?? '';

      if (error.code ==
          'permission-denied') {
        return message.isEmpty
            ? 'Firestore permission denied while saving the review.'
            : message;
      }

      if (message.isNotEmpty) {
        return message;
      }

      return error.code;
    }

    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }
}
