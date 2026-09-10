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
      backgroundColor: const Color(0xFFF7F8FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            top: 10,
            bottom: 10,
          ),
          child: Material(
            color: Colors.white.withValues(alpha: .14),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.of(context).maybePop();
              },
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        title: const Text(
          'LIVE WALK',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 12,
              top: 10,
              bottom: 10,
            ),
            child: Material(
              color: Colors.white.withValues(alpha: .14),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  _showHelpDialog(context);
                },
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final bool wide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                wide ? 28 : 16,
                18,
                wide ? 28 : 16,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 760,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroHeader(),

                      const SizedBox(height: 16),

                      _buildDogOwnerCard(),

                      const SizedBox(height: 14),

                      _buildStartSection(
                        starting: starting,
                        ending: ending,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HERO HEADER
  // ============================================================

  Widget _buildHeroHeader() {
    final String dogName =
        widget.dogName.trim().isEmpty
            ? 'your dog'
            : widget.dogName.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        17,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: .88),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .20),
              ),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready for the walk?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Everything is ready for $dogName.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .88),
                    fontSize: 12.5,
                    height: 1.35,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE9EBEF),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // DOG
          // ======================================================

          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: .09,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pets_rounded,
                  color: AppColors.primary,
                  size: 31,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WALKING WITH',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dogName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17191D),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (breed.isNotEmpty) ...[
                      const SizedBox(height: 3),
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
            ],
          ),

          const SizedBox(height: 16),

          Container(
            height: 1,
            color: const Color(0xFFF0F1F3),
          ),

          const SizedBox(height: 14),

          // ======================================================
          // OWNER
          // ======================================================

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF5D626B),
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'OWNER',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF202329),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              if (widget.ownerPhone != null &&
                  widget.ownerPhone!.trim().isNotEmpty)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: .08,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    color: AppColors.primary,
                    size: 18,
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
      padding: const EdgeInsets.fromLTRB(
        18,
        19,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE9EBEF),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: .09,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Start?',
                      style: TextStyle(
                        color: Color(0xFF17191D),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Slide when you are ready to begin.',
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

          const SizedBox(height: 18),

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
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: .06,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'Starting live walk...',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HELP
  // ============================================================

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Text(
                'Help & Support',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Make sure you and the dog are ready before starting the live walk.',
            style: TextStyle(
              color: Colors.black54,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
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
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
