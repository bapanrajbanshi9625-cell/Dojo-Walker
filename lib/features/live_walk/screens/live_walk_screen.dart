// File:
// lib/features/live_walk/screens/live_walk_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_walk_session_controller.dart';
import '../widgets/live_walk_complete_slider.dart';
import '../widgets/live_walk_map_layer.dart';
import '../widgets/live_walk_review_bottom_sheet.dart';

class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({
    super.key,
    required this.ownerUid,
    required this.ownerName,
    required this.walkId,
    required this.dogName,
    this.dogBreed = '',
    this.ownerPhone,
    this.sessionId,
  });

  final String ownerUid;
  final String ownerName;
  final String walkId;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;
  final String? sessionId;

  @override
  State<LiveWalkScreen> createState() => _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  late final LiveWalkSessionController _controller;

  bool _showingEndDialog = false;
  bool _showingReview = false;

  Map<String, dynamic> _lastSessionData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();

    _controller = LiveWalkSessionController(
      ownerUid: widget.ownerUid,
      ownerName: widget.ownerName,
      walkId: widget.walkId,
      dogName: widget.dogName,
      dogBreed: widget.dogBreed,
      ownerPhone: widget.ownerPhone,
      sessionId: widget.sessionId,
    );

    _controller.addListener(_onControllerChanged);

    unawaited(_controller.initialize());
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _sessionStream {
    return _controller.sessionStream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _sessionStream,
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
      ) {
        final Map<String, dynamic> data =
            snapshot.data?.data() ?? <String, dynamic>{};

        if (data.isNotEmpty) {
          _lastSessionData = Map<String, dynamic>.from(data);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            _controller.updateFromSession(data);
          });
        }

        final Map<String, dynamic> sessionData =
            data.isNotEmpty ? data : _lastSessionData;

        final bool walkStarted = _controller.walkStarted;
        final bool ending = _controller.ending;
        final bool starting = _controller.startingWalk;

        return Scaffold(
          backgroundColor: AppColors.cardBackground,

          // ======================================================
          // APP BAR
          // ======================================================

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
            actions: [
              IconButton(
                tooltip: 'SOS',
                onPressed: ending ? null : _openSos,
                icon: const Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              IconButton(
                tooltip: 'Support',
                onPressed: ending ? null : _openSupport,
                icon: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          // ======================================================
          // BODY
          // ======================================================

          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // OSM MAP
                  // ==================================================

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 340,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: LiveWalkMapLayer(
                                sessionData: sessionData,
                                gpsReady: _controller.gpsReady,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: _liveMapBadge(),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: _gpsBadge(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // DETAILS
                  // ==================================================

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDogOwnerCard(),

                        const SizedBox(height: 14),

                        // BEFORE START
                        if (!walkStarted && !ending)
                          _buildStartSection(starting),

                        // AFTER START
                        if (walkStarted && !ending) ...[
                          _buildWalkingStatus(),

                          const SizedBox(height: 14),

                          _buildLiveStats(sessionData),

                          const SizedBox(height: 14),

                          _buildWalkInfo(),

                          const SizedBox(height: 18),

                          _buildCompleteSection(),
                        ],

                        // ENDING
                        if (ending) _buildEndingSection(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DOG / OWNER CARD
  // ============================================================

  Widget _buildDogOwnerCard() {
    final String dogName = widget.dogName.trim().isEmpty
        ? 'Dog'
        : widget.dogName.trim();

    final String ownerName = widget.ownerName.trim().isEmpty
        ? 'Owner'
        : widget.ownerName.trim();

    final String breed = widget.dogBreed.trim();

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
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dogName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (breed.isNotEmpty)
                  Text(
                    breed,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.person_rounded,
                size: 19,
                color: Colors.black45,
              ),
              const SizedBox(height: 3),
              Text(
                ownerName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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

  Widget _buildStartSection(bool starting) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .10),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Start the walk when you are ready.',
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

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed:
                  starting || _controller.ending ? null : _startWalk,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black12,
                disabledForegroundColor: Colors.black38,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: starting
                  ? const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 25,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'START WALK',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WALKING STATUS
  // ============================================================

  Widget _buildWalkingStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.green.withValues(alpha: .25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 9),

          const Expanded(
            child: Text(
              'WALKING • LIVE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
              ),
            ),
          ),

          if (_controller.gpsReady)
            const Icon(
              Icons.gps_fixed_rounded,
              color: Colors.green,
              size: 19,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LIVE STATS
  // ============================================================

  Widget _buildLiveStats(Map<String, dynamic> data) {
    final double distance =
        _readDouble(data['distanceKm']) ??
        _controller.totalDistanceKm;

    final int steps =
        _readInt(data['steps']) ??
        _controller.steps;

    final String duration =
        _readDuration(data);

    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.route_rounded,
            distance < 1
                ? '${(distance * 1000).round()} m'
                : '${distance.toStringAsFixed(2)} km',
            'Distance',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            Icons.timer_rounded,
            duration,
            'Duration',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            Icons.directions_walk_rounded,
            steps.toString(),
            'Steps',
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 23,
          ),

          const SizedBox(height: 7),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WALK INFO
  // ============================================================

  Widget _buildWalkInfo() {
    final String ownerName = widget.ownerName.trim().isEmpty
        ? 'Owner'
        : widget.ownerName.trim();

    final String dogName = widget.dogName.trim().isEmpty
        ? 'Dog'
        : widget.dogName.trim();

    final String breed = widget.dogBreed.trim();
    final String? phone = _cleanOptional(widget.ownerPhone);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.person_rounded,
            'Owner',
            ownerName,
          ),

          _infoDivider(),

          _infoRow(
            Icons.pets_rounded,
            'Dog',
            dogName,
          ),

          if (breed.isNotEmpty) ...[
            _infoDivider(),
            _infoRow(
              Icons.category_rounded,
              'Breed',
              breed,
            ),
          ],

          if (phone != null) ...[
            _infoDivider(),
            _infoRow(
              Icons.phone_rounded,
              'Phone',
              phone,
            ),
          ],
        ],
      ),
    );
  }

  String? _cleanOptional(String? value) {
    if (value == null) {
      return null;
    }

    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1),
    );
  }

  // ============================================================
  // COMPLETE SECTION
  // ============================================================

  Widget _buildCompleteSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Finish Walk',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'When you reach the destination, slide to complete the walk.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 18),

          LiveWalkCompleteSlider(
            enabled:
                !_controller.ending &&
                _controller.walkStarted,
            onCompleted: _confirmCompleteWalk,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ENDING
  // ============================================================

  Widget _buildEndingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 35,
            height: 35,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),

          SizedBox(height: 12),

          Text(
            'Completing walk...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // START WALK
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

      _showMessage('Walk started.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(_cleanError(error));
    }
  }

  // ============================================================
  // COMPLETE CONFIRMATION
  // ============================================================

  void _confirmCompleteWalk() {
    if (_controller.ending || _showingEndDialog) {
      return;
    }

    if (!_controller.walkStarted) {
      _showError('Start the walk first.');
      return;
    }

    _showingEndDialog = true;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Complete Walk?',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to complete this walk?',
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                unawaited(_completeWalk());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _showingEndDialog = false;
    });
  }

  // ============================================================
  // COMPLETE WALK
  // ============================================================

  Future<void> _completeWalk() async {
    if (_controller.ending || !_controller.walkStarted) {
      return;
    }

    try {
      await _controller.endWalk();

      if (!mounted) {
        return;
      }

      _showMessage('Walk completed.');

      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) {
        return;
      }

      await _openReviewBottomSheet();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(_cleanError(error));
    }
  }

  // ============================================================
  // REVIEW
  // ============================================================

  Future<void> _openReviewBottomSheet() async {
    if (!mounted || _showingReview) {
      return;
    }

    _showingReview = true;

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(_lastSessionData);

    final double? sessionDistance =
        _readDouble(data['distanceKm']);

    final double distance =
        sessionDistance == null
            ? _controller.totalDistanceKm
            : sessionDistance;

    final int? sessionSteps =
        _readInt(data['steps']);

    final int steps =
        sessionSteps == null
            ? _controller.steps
            : sessionSteps;

    final String duration =
        _readDuration(data);

    final List<Offset> routePoints =
        _extractRoutePoints(data);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext sheetContext) {
        return LiveWalkReviewBottomSheet(
          routePoints: routePoints,
          distanceKm: distance,
          duration: duration,
          steps: steps,
          walkId: widget.walkId,
          ownerUid: widget.ownerUid,
          dogName: widget.dogName,
          onBackToHome: () {
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );

    _showingReview = false;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

    _showingReview = false;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  // ============================================================
  // MAP BADGE
  // ============================================================

  Widget _liveMapBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 7),

          const Text(
            'LIVE LOCATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gpsBadge() {
    final bool gpsReady = _controller.gpsReady;

    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        gpsReady
            ? Icons.gps_fixed_rounded
            : Icons.gps_off_rounded,
        color: gpsReady ? Colors.green : Colors.red,
        size: 20,
      ),
    );
  }

  // ============================================================
  // SOS
  // ============================================================

  void _openSos() {
    if (_controller.ending) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _SosSheet(
          ownerName: widget.ownerName,
          ownerPhone: widget.ownerPhone,
        );
      },
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  void _openSupport() {
    if (_controller.ending) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),

                const SizedBox(height: 10),

                const Text(
                  'Walk Support',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Need help during this walk?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();

                      _showMessage(
                        'Support contact will be connected soon.',
                      );
                    },
                    icon: const Icon(
                      Icons.support_agent_rounded,
                    ),
                    label: const Text(
                      'Contact Support',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ROUTE POINTS
  // ============================================================

  List<Offset> _extractRoutePoints(
    Map<String, dynamic> data,
  ) {
    final dynamic raw =
        data['routePoints'] ??
        data['polylinePoints'] ??
        data['locations'] ??
        data['routeCoordinates'];

    if (raw is! List) {
      return <Offset>[];
    }

    final List<Offset> points = <Offset>[];

    for (final dynamic item in raw) {
      if (item is GeoPoint) {
        points.add(
          Offset(
            item.latitude,
            item.longitude,
          ),
        );
        continue;
      }

      if (item is Map) {
        final dynamic lat =
            item['latitude'] ?? item['lat'];

        final dynamic lng =
            item['longitude'] ??
            item['lng'] ??
            item['lon'];

        final double? latitude = _readDouble(lat);
        final double? longitude = _readDouble(lng);

        if (latitude != null && longitude != null) {
          points.add(
            Offset(
              latitude,
              longitude,
            ),
          );
        }
      }
    }

    return points;
  }

  // ============================================================
  // DURATION
  // ============================================================

  String _readDuration(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['durationMinutes'] ??
        data['duration'] ??
        data['elapsedMinutes'];

    if (value is num) {
      final int minutes = value.toInt();

      if (minutes < 60) {
        return '${minutes}m';
      }

      final int hours = minutes ~/ 60;
      final int remaining = minutes % 60;

      return '${hours}h ${remaining}m';
    }

    if (value is String) {
      final String text = value.trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '0m';
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  // ============================================================
  // INT
  // ============================================================

  int _readInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString().trim(),
        ) ??
        0;
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

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

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();

    super.dispose();
  }
}

// ================================================================
// SOS SHEET
// ================================================================

class _SosSheet extends StatelessWidget {
  const _SosSheet({
    required this.ownerName,
    required this.ownerPhone,
  });

  final String ownerName;
  final String? ownerPhone;

  @override
  Widget build(BuildContext context) {
    final String trimmedOwnerName = ownerName.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        25,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 18),

            const Icon(
              Icons.sos_rounded,
              color: AppColors.error,
              size: 48,
            ),

            const SizedBox(height: 10),

            const Text(
              'Emergency SOS',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              trimmedOwnerName.isEmpty
                  ? 'Emergency assistance'
                  : 'Emergency assistance for $trimmedOwnerName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.emergency_rounded,
                ),
                label: const Text(
                  'Emergency Assistance',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
