import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_walk_session_controller.dart';
import '../widgets/live_walk_start_slider.dart';
import 'live_walk_screen.dart';

class LiveWalkStartScreen extends StatefulWidget {
  const LiveWalkStartScreen({
    super.key,
    required this.ownerUid,
    required this.ownerName,
    required this.requestId,
    required this.dogName,
    this.dogBreed = '',
    this.ownerPhone,
  });

  final String ownerUid;
  final String ownerName;
  final String requestId;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  @override
  State<LiveWalkStartScreen> createState() =>
      _LiveWalkStartScreenState();
}

class _LiveWalkStartScreenState
    extends State<LiveWalkStartScreen> {
  late final LiveWalkSessionController _controller;

  late final String _requestId;

  @override
  void initState() {
    super.initState();

    _requestId = widget.requestId.trim();

    if (!RegExp(r'^DW\d{6}$').hasMatch(_requestId)) {
      throw ArgumentError(
        'Invalid requestId. Expected DW######.',
      );
    }

    _controller = LiveWalkSessionController(
      requestId: _requestId,
      ownerUid: widget.ownerUid,
      ownerName: widget.ownerName,
      dogName: widget.dogName,
      dogBreed: widget.dogBreed,
      ownerPhone: widget.ownerPhone,
    );

    _controller.addListener(_onControllerChanged);

    unawaited(_controller.initialize());
  }

  // ============================================================
  // CONTROLLER LISTENER
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool starting = _controller.startingWalk;
    final bool ending = _controller.ending;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'LIVE WALK',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDogOwnerCard(),

              const SizedBox(height: 16),

              _buildStartSection(
                starting: starting,
                ending: ending,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DOG + OWNER CARD
  // ============================================================

  Widget _buildDogOwnerCard() {
    final String dogName =
        widget.dogName.trim().isEmpty
            ? 'Dog'
            : widget.dogName.trim();

    final String ownerName =
        widget.ownerName.trim().isEmpty
            ? 'Owner'
            : widget.ownerName.trim();

    final String breed =
        widget.dogBreed.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ======================================================
          // DOG ICON
          // ======================================================

          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: .10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),

          const SizedBox(width: 12),

          // ======================================================
          // DOG DETAILS
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  dogName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                if (breed.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    breed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // OWNER
          // ======================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.person_rounded,
                size: 19,
                color: Colors.black45,
              ),

              const SizedBox(height: 3),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 100,
                ),
                child: Text(
                  ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // START SECTION
  // ============================================================

  Widget _buildStartSection({
    required bool starting,
    required bool ending,
  }) {
    final bool sliderEnabled =
        !starting &&
        !ending &&
        !_controller.walkStarted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: .10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Start?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Slide to start the walk.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // START SLIDER
          // ======================================================

          LiveWalkStartSlider(
            key: ValueKey<bool>(starting),
            enabled: sliderEnabled,
            onStarted: _startWalk,
          ),

          // ======================================================
          // STARTING INDICATOR
          // ======================================================

          if (starting) ...[
            const SizedBox(height: 12),

            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Center(
              child: Text(
                'Starting live walk...',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ACTUAL WALK START
  // ============================================================

  Future<void> _startWalk() async {
    if (_controller.startingWalk ||
        _controller.walkStarted ||
        _controller.ending) {
      return;
    }

    try {
      // ========================================================
      // THIS IS THE ACTUAL WALK START
      // ========================================================

      await _controller.startWalk();

      if (!mounted) {
        return;
      }

      // ========================================================
      // ONLY AFTER startWalk() SUCCESS:
      // OPEN ACTIVE LIVE WALK SCREEN
      // ========================================================

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LiveWalkScreen(
            ownerUid: widget.ownerUid,
            ownerName: widget.ownerName,
            requestId: _requestId,
            dogName: widget.dogName,
            dogBreed: widget.dogBreed,
            ownerPhone: widget.ownerPhone,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        _cleanError(error),
      );
    }
  }

  // ============================================================
  // ERROR CLEANUP
  // ============================================================

  String _cleanError(Object error) {
    final String message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();

    return message.isEmpty
        ? 'Unable to start the walk.'
        : message;
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _controller.dispose();

    super.dispose();
  }
}
