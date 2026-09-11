import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../controllers/live_walk_session_controller.dart';
import '../widgets/live_walk_app_bar.dart';
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

class _LiveWalkStartScreenState extends State<LiveWalkStartScreen> {
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
      backgroundColor: DojoWalkerColors.background,
      appBar: LiveWalkAppBar(
        enabled: !starting && !ending,
        onSos: _handleSos,
        onSupport: _handleSupport,
      ),
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
                16,
                wide ? 28 : 16,
                22,
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
                      _buildWalkInformationCard(),
                      const SizedBox(height: 14),
                      _buildStartSection(
                        starting: starting,
                        ending: ending,
                      ),
                      const SizedBox(height: 14),
                      _buildSafetyFooter(),
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
  // WALK INFORMATION CARD
  // ============================================================

  Widget _buildWalkInformationCard() {
    final String dogName = widget.dogName.trim().isEmpty
        ? 'Your dog'
        : widget.dogName.trim();

    final String ownerName = widget.ownerName.trim().isEmpty
        ? 'Owner'
        : widget.ownerName.trim();

    final String breed = widget.dogBreed.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: DojoWalkerColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DojoWalkerColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkerColors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DojoWalkerColors.light,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: DojoWalkerColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY FOR THE WALK',
                      style: TextStyle(
                        color: DojoWalkerColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.25,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Everything is ready to begin.',
                      style: TextStyle(
                        color: DojoWalkerColors.textSecondary,
                        fontSize: 11.5,
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
          // DOG
          // ======================================================

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DojoWalkerColors.light,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: DojoWalkerColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DojoWalkerColors.soft,
                    ),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: DojoWalkerColors.primary,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WALKING WITH',
                        style: TextStyle(
                          color: DojoWalkerColors.textSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dogName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DojoWalkerColors.textPrimary,
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
                            color:
                                DojoWalkerColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // OWNER + REQUEST
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.person_outline_rounded,
                  label: 'OWNER',
                  value: ownerName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  icon:
                      Icons.confirmation_number_outlined,
                  label: 'REQUEST',
                  value: _requestId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION ITEM
  // ============================================================

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: DojoWalkerColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DojoWalkerColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DojoWalkerColors.light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: DojoWalkerColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                        DojoWalkerColors.textSecondary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DojoWalkerColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
        color: DojoWalkerColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: DojoWalkerColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkerColors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DojoWalkerColors.light,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: DojoWalkerColors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY TO START?',
                      style: TextStyle(
                        color: DojoWalkerColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Slide to begin your live walk.',
                      style: TextStyle(
                        color: DojoWalkerColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          LiveWalkStartSlider(
            key: ValueKey<bool>(starting),
            enabled: sliderEnabled,
            onStarted: _startWalk,
          ),

          if (starting) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: DojoWalkerColors.light,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        DojoWalkerColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'Starting live walk...',
                    style: TextStyle(
                      color: DojoWalkerColors.textSecondary,
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
  // SAFETY FOOTER
  // ============================================================

  Widget _buildSafetyFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          color: DojoWalkerColors.primary,
          size: 15,
        ),
        SizedBox(width: 6),
        Text(
          'Safe • Live • Tracked',
          style: TextStyle(
            color: DojoWalkerColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SOS
  // ============================================================

  void _handleSos() {
    if (!mounted) {
      return;
    }

    _showMessage(
      'SOS support is available from the live walk.',
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  void _handleSupport() {
    if (!mounted) {
      return;
    }

    _showMessage(
      'Help & Support is available from the Live Walk header.',
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
      await _controller.startWalk();

      if (!mounted) {
        return;
      }

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
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: DojoWalkerColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
          backgroundColor: DojoWalkerColors.error,
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
