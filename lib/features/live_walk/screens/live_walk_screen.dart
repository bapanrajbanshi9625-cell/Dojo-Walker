import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_walk_session_controller.dart';
import '../widgets/live_walk_complete_slider.dart';
import '../widgets/live_walk_map_layer.dart';

class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({
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

  /// CANONICAL WALK / REQUEST / SESSION ID
  ///
  /// walk_request/{requestId}
  /// liveWalkSessions/{requestId}
  /// walk_history/{requestId}
  final String requestId;

  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  @override
  State<LiveWalkScreen> createState() =>
      _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  late final LiveWalkSessionController _controller;

  bool _showingEndDialog = false;
  bool _leavingScreen = false;

  int _peeCount = 0;
  int _poopCount = 0;
  bool _activityCountsInitialized = false;

  Map<String, dynamic> _lastSessionData =
      <String, dynamic>{};

  @override
  void initState() {
    super.initState();

    final String cleanRequestId =
        widget.requestId.trim();

    if (!RegExp(r'^DW\d{6}$').hasMatch(cleanRequestId)) {
      throw ArgumentError(
        'Invalid requestId. Expected DW######.',
      );
    }

    _controller = LiveWalkSessionController(
      requestId: cleanRequestId,
      ownerUid: widget.ownerUid,
      ownerName: widget.ownerName,
      dogName: widget.dogName,
      dogBreed: widget.dogBreed,
      ownerPhone: widget.ownerPhone,
    );

    _controller.addListener(
      _onControllerChanged,
    );

    unawaited(
      _controller.initialize(),
    );
  }

  // ============================================================
  // CONTROLLER
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _sessionStream {
    return _controller.sessionStream;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _sessionStream,
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
      ) {
        final Map<String, dynamic> firestoreData =
            snapshot.data?.data() ??
                <String, dynamic>{};

        if (firestoreData.isNotEmpty) {
          _lastSessionData =
              Map<String, dynamic>.from(
            firestoreData,
          );

          _initializeActivityCounts(
            firestoreData,
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            _controller.updateFromSession(
              firestoreData,
            );
          });
        }

        final Map<String, dynamic> sessionData =
            firestoreData.isNotEmpty
                ? firestoreData
                : _lastSessionData;

        final bool walkStarted =
            _controller.walkStarted;

        final bool ending =
            _controller.ending;

        return Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: .94,
                ),
                borderRadius: BorderRadius.circular(
                  22,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'LIVE WALK',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                ),
                child: Row(
                  children: [
                    _topActionButton(
                      icon: Icons.sos_rounded,
                      tooltip: 'SOS',
                      onPressed:
                          ending ? null : _openSos,
                      iconColor: AppColors.error,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    _topActionButton(
                      icon: Icons.support_agent_rounded,
                      tooltip: 'Support',
                      onPressed:
                          ending ? null : _openSupport,
                      iconColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // ====================================================
              // FULL SCREEN LIVE MAP
              // ====================================================

              Positioned.fill(
                child: LiveWalkMapLayer(
                  sessionData: sessionData,
                  gpsReady: _controller.gpsReady,
                ),
              ),

              // ====================================================
              // BOTTOM DRAGGABLE SHEET
              // ====================================================

              if (walkStarted || ending)
                DraggableScrollableSheet(
                  initialChildSize: .22,
                  minChildSize: .18,
                  maxChildSize: .72,
                  snap: true,
                  snapSizes: const [
                    .22,
                    .72,
                  ],
                  builder: (
                    BuildContext context,
                    ScrollController scrollController,
                  ) {
                    return _buildBottomSheet(
                      scrollController,
                      sessionData,
                      ending,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // TOP ACTION BUTTON
  // ============================================================

  Widget _topActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.white.withValues(
        alpha: .95,
      ),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet(
    ScrollController scrollController,
    Map<String, dynamic> sessionData,
    bool ending,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          28,
        ),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _buildCompactDogOwnerHeader(),

          if (!ending) ...[
            const SizedBox(
              height: 18,
            ),

            _buildWalkingStatus(),

            const SizedBox(
              height: 18,
            ),

            _buildLiveStats(
              sessionData,
            ),

            const SizedBox(
              height: 18,
            ),

            _buildDogActivities(),

            const SizedBox(
              height: 20,
            ),

            _buildCompleteSection(),
          ],

          if (ending) ...[
            const SizedBox(
              height: 18,
            ),
            _buildEndingSection(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // COMPACT DOG + OWNER HEADER
  // ============================================================

  Widget _buildCompactDogOwnerHeader() {
    final String cleanDogName =
        widget.dogName.trim().isEmpty
            ? 'Dog'
            : widget.dogName.trim();

    final String cleanOwnerName =
        widget.ownerName.trim().isEmpty
            ? 'Owner'
            : widget.ownerName.trim();

    final String cleanBreed =
        widget.dogBreed.trim();

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: .10,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: AppColors.primary,
            size: 27,
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                cleanOwnerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Row(
                children: [
                  Flexible(
                    child: Text(
                      cleanDogName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  if (cleanBreed.isNotEmpty) ...[
                    const SizedBox(
                      width: 5,
                    ),
                    const Text(
                      '•',
                      style: TextStyle(
                        color: Colors.black26,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Flexible(
                      child: Text(
                        cleanBreed,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withValues(
              alpha: .09,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                color: Colors.green,
                size: 16,
              ),
              SizedBox(
                width: 4,
              ),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WALKING STATUS
  // ============================================================

  Widget _buildWalkingStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(
          alpha: .07,
        ),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: Colors.green.withValues(
            alpha: .20,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          const Expanded(
            child: Text(
              'WALKING • LIVE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
              ),
            ),
          ),

          Icon(
            Icons.my_location_rounded,
            color: Colors.green.withValues(
              alpha: .75,
            ),
            size: 18,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIVE STATS
  // ============================================================

  Widget _buildLiveStats(
    Map<String, dynamic> data,
  ) {
    final double distance =
        _readDouble(
              data['distanceKm'],
            ) ??
            _controller.totalDistanceKm;

    final int steps =
        _readInt(
              data['steps'],
            ) ??
            _controller.steps;

    final String duration =
        _readDuration(data);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'WALK STATS',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.timer_rounded,
                duration,
                'Minutes',
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: _statCard(
                Icons.route_rounded,
                distance < 1
                    ? '${(distance * 1000).round()} m'
                    : '${distance.toStringAsFixed(2)} km',
                'KM',
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: _statCard(
                Icons.directions_walk_rounded,
                steps.toString(),
                'Steps',
              ),
            ),
          ],
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
        vertical: 13,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(15),
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

          const SizedBox(
            height: 6,
          ),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PEE / POOP
  // ============================================================

  Widget _buildDogActivities() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'DOG ACTIVITY',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        Row(
          children: [
            Expanded(
              child: _activityButton(
                icon: Icons.water_drop_rounded,
                title: 'PEE',
                count: _peeCount,
                iconColor: Colors.blue,
                onPressed: () {
                  _confirmDogActivity(
                    type: 'Pee',
                    icon: Icons.water_drop_rounded,
                    iconColor: Colors.blue,
                  );
                },
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: _activityButton(
                icon: Icons.circle,
                title: 'POOP',
                count: _poopCount,
                iconColor: Colors.brown,
                onPressed: () {
                  _confirmDogActivity(
                    type: 'Poop',
                    icon: Icons.circle,
                    iconColor: Colors.brown,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _activityButton({
    required IconData icon,
    required String title,
    required int count,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: iconColor.withValues(
              alpha: .06,
            ),
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: iconColor.withValues(
                alpha: .16,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: .12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      '$count recorded',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(
                      alpha: .15,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: iconColor,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVITY CONFIRMATION
  // ============================================================

  void _confirmDogActivity({
    required String type,
    required IconData icon,
    required Color iconColor,
  }) {
    showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(
            22,
            24,
            22,
            10,
          ),
          titlePadding:
              const EdgeInsets.fromLTRB(
            22,
            22,
            22,
            0,
          ),
          title: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: .10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                'Record $type?',
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color:
                      AppColors.secondary,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          content: Text(
            'Confirm that the dog $type.toLowerCase() during this walk.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.secondary,
                      minimumSize:
                          const Size(
                        0,
                        46,
                      ),
                      side: BorderSide(
                        color:
                            AppColors.border,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (type == 'Pee') {
                        _peeCount++;
                      } else {
                        _poopCount++;
                      }

                      Navigator.of(
                        dialogContext,
                      ).pop();

                      if (mounted) {
                        setState(() {});
                      }
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      minimumSize:
                          const Size(
                        0,
                        46,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ACTIVITY COUNT INITIALIZATION
  // ============================================================

  void _initializeActivityCounts(
    Map<String, dynamic> data,
  ) {
    if (_activityCountsInitialized) {
      return;
    }

    final int? pee =
        _readInt(
          data['peeCount'] ??
              data['pee'],
        );

    final int? poop =
        _readInt(
          data['poopCount'] ??
              data['poop'],
        );

    if (pee != null) {
      _peeCount = pee;
    }

    if (poop != null) {
      _poopCount = poop;
    }

    _activityCountsInitialized = true;
  }

  // ============================================================
  // COMPLETE SECTION
  // ============================================================

  Widget _buildCompleteSection() {
    return LiveWalkCompleteSlider(
      enabled:
          !_controller.ending &&
          _controller.walkStarted,
      onCompleted:
          _confirmCompleteWalk,
    );
  }

  // ============================================================
  // ENDING
  // ============================================================

  Widget _buildEndingSection() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 35,
            height: 35,
            child:
                CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Completing walk...',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETE CONFIRMATION
  // ============================================================

  void _confirmCompleteWalk() {
    if (_controller.ending ||
        _showingEndDialog) {
      return;
    }

    if (!_controller.walkStarted) {
      _showError(
        'Start the walk first.',
      );
      return;
    }

    _showingEndDialog = true;

    showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              AppColors.cardBackground,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Complete Walk?',
            style: TextStyle(
              color:
                  AppColors.secondary,
              fontWeight:
                  FontWeight.w900,
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
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color:
                      AppColors.secondary,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                unawaited(
                  _completeWalk(),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child:
                  const Text(
                'Complete',
              ),
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
    if (_controller.ending ||
        !_controller.walkStarted ||
        _leavingScreen) {
      return;
    }

    try {
      // --------------------------------------------------------
      // 1. COMPLETE WALK
      // --------------------------------------------------------

      await _controller.endWalk();

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // 2. CAPTURE FINAL DATA
      // --------------------------------------------------------

      final Map<String, dynamic>
          resultSessionData =
          Map<String, dynamic>.from(
        _lastSessionData,
      );

      final double distance =
          _readDouble(
                resultSessionData[
                    'distanceKm'],
              ) ??
              _controller.totalDistanceKm;

      final int steps =
          _readInt(
                resultSessionData[
                    'steps'],
              ) ??
              _controller.steps;

      final String duration =
          _readDuration(
        resultSessionData,
      );

      final List<Offset>
          routePoints =
          _extractRoutePoints(
        resultSessionData,
      );

      // --------------------------------------------------------
      // 3. LEAVE LIVE WALK SCREEN
      // --------------------------------------------------------

      _leavingScreen = true;

      Navigator.of(context).pop(
        <String, dynamic>{
          'walkCompleted': true,
          'showReview': true,

          'requestId':
              widget.requestId,

          'ownerUid':
              widget.ownerUid,
          'ownerName':
              widget.ownerName,
          'ownerPhone':
              widget.ownerPhone,

          'dogName':
              widget.dogName,
          'dogBreed':
              widget.dogBreed,

          'distanceKm':
              distance,
          'steps':
              steps,
          'duration':
              duration,

          'routePoints':
              routePoints,

          'sessionData':
              resultSessionData,

          'peeCount':
              _peeCount,
          'poopCount':
              _poopCount,
        },
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
  // SOS
  // ============================================================

  void _openSos() {
    if (_controller.ending) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (
        BuildContext sheetContext,
      ) {
        return _SosSheet(
          ownerName:
              widget.ownerName,
          ownerPhone:
              widget.ownerPhone,
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
      backgroundColor:
          Colors.transparent,
      builder: (
        BuildContext sheetContext,
      ) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            25,
          ),
          decoration:
              const BoxDecoration(
            color:
                AppColors.cardBackground,
            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.border,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                const Icon(
                  Icons
                      .support_agent_rounded,
                  color:
                      AppColors.primary,
                  size: 38,
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Walk Support',
                  style: TextStyle(
                    color:
                        AppColors.secondary,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Need help during this walk?',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 50,
                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        sheetContext,
                      ).pop();

                      _showMessage(
                        'Support contact will be connected soon.',
                      );
                    },
                    icon: const Icon(
                      Icons
                          .support_agent_rounded,
                    ),
                    label:
                        const Text(
                      'Contact Support',
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
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

    final List<Offset> points =
        <Offset>[];

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
            item['latitude'] ??
            item['lat'];

        final dynamic lng =
            item['longitude'] ??
            item['lng'] ??
            item['lon'];

        final double? latitude =
            _readDouble(lat);

        final double? longitude =
            _readDouble(lng);

        if (latitude != null &&
            longitude != null) {
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
      final int minutes =
          value.toInt();

      if (minutes < 60) {
        return '${minutes}m';
      }

      final int hours =
          minutes ~/ 60;

      final int remaining =
          minutes % 60;

      return '${hours}h ${remaining}m';
    }

    if (value != null) {
      final String text =
          value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '0m';
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double? _readDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // INT
  // ============================================================

  int? _readInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // ERROR
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

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          backgroundColor:
              AppColors.error,
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
  }

  // ============================================================
  // NORMAL MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior
                  .floating,
          duration:
              const Duration(
            seconds: 2,
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

// ============================================================================
// SOS SHEET
// ============================================================================

class _SosSheet extends StatelessWidget {
  const _SosSheet({
    required this.ownerName,
    required this.ownerPhone,
  });

  final String ownerName;
  final String? ownerPhone;

  @override
  Widget build(
    BuildContext context,
  ) {
    final String cleanOwnerName =
        ownerName.trim();

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        25,
      ),
      decoration:
          const BoxDecoration(
        color:
            AppColors.cardBackground,
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration:
                  BoxDecoration(
                color:
                    AppColors.border,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Icon(
              Icons.sos_rounded,
              color:
                  AppColors.error,
              size: 48,
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Emergency SOS',
              style: TextStyle(
                color:
                    AppColors.secondary,
                fontSize: 20,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              cleanOwnerName.isEmpty
                  ? 'Emergency assistance'
                  : 'Emergency assistance for $cleanOwnerName',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 50,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop();
                },
                icon: const Icon(
                  Icons
                      .emergency_rounded,
                ),
                label:
                    const Text(
                  'Emergency Assistance',
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      AppColors.error,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
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
