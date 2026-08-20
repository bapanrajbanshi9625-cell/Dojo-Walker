import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../features/walks/services/walk_request_service.dart';

class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({
    super.key,
    required this.ownerUid,
    required this.ownerName,
    required this.walkId,
    this.ownerPhone,
    this.sessionId,
  });

  final String ownerUid;
  final String ownerName;
  final String walkId;
  final String? ownerPhone;

  /// Optional session ID.
  ///
  /// If not provided, service will use:
  /// session-{walkId}
  final String? sessionId;

  @override
  State<LiveWalkScreen> createState() =>
      _LiveWalkScreenState();
}

class _LiveWalkScreenState
    extends State<LiveWalkScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFFF6600);

  static const Color blue =
      Color(0xFF238EAE);

  static const Color green =
      Color(0xFF16A34A);

  static const Color red =
      Color(0xFFE53935);

  static const Color dark =
      Color(0xFF263746);

  static const Color muted =
      Color(0xFF7A8289);

  static const Color background =
      Color(0xFFF5F6F8);

  static const Color cardBorder =
      Color(0xFFE1E6E8);

  // ============================================================
  // STATE
  // ============================================================

  bool _isEndingWalk = false;

  // ============================================================
  // SERVICE
  // ============================================================

  final WalkRequestService _service =
      WalkRequestService.instance;

  // ============================================================
  // FIRESTORE REFERENCES
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      get _activeWalkRef =>
          FirebaseFirestore.instance
              .collection('active_walk')
              .doc(widget.walkId);

  String get _resolvedSessionId =>
      widget.sessionId?.trim().isNotEmpty == true
          ? widget.sessionId!.trim()
          : 'session-${widget.walkId}';

  DocumentReference<Map<String, dynamic>>
      get _sessionRef =>
          FirebaseFirestore.instance
              .collection('liveWalkSessions')
              .doc(_resolvedSessionId);

  // ============================================================
  // END WALK
  // ============================================================

  Future<void> _endWalk() async {
    if (_isEndingWalk) {
      return;
    }

    setState(() {
      _isEndingWalk = true;
    });

    try {
      await _service.endLiveWalk(
        widget.walkId,
        sessionId: _resolvedSessionId,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isEndingWalk = false;
      });

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message,
            ),
          ),
        );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _activeWalkRef.snapshots(),
      builder: (
        context,
        activeSnapshot,
      ) {
        if (activeSnapshot.hasError) {
          return _errorScreen(
            activeSnapshot.error.toString(),
          );
        }

        final Map<String, dynamic>
            activeData =
            activeSnapshot.data?.data() ??
                <String, dynamic>{};

        final String status =
            activeData['status']
                    ?.toString()
                    .toLowerCase() ??
                'active';

        if (status != 'active') {
          return _completedScreen(
            activeData,
          );
        }

        return StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream: _sessionRef.snapshots(),
          builder: (
            context,
            sessionSnapshot,
          ) {
            final Map<String, dynamic>
                sessionData =
                sessionSnapshot.data?.data() ??
                    <String, dynamic>{};

            return _activeWalkScreen(
              activeData,
              sessionData,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ACTIVE WALK SCREEN
  // ============================================================

  Widget _activeWalkScreen(
    Map<String, dynamic> activeData,
    Map<String, dynamic> sessionData,
  ) {
    // ----------------------------------------------------------
    // DURATION
    // ----------------------------------------------------------

    final int elapsedSeconds =
        _toInt(
      sessionData['elapsedSeconds'],
    );

    final String duration =
        sessionData['elapsedSeconds'] !=
                null
            ? _formatDuration(
                elapsedSeconds,
              )
            : activeData['duration']
                    ?.toString() ??
                '00:00:00';

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double distanceKm =
        _toDouble(
      sessionData['distanceKm'],
    );

    final String distance =
        sessionData['distanceKm'] != null
            ? '${distanceKm.toStringAsFixed(1)} km'
            : activeData['distance']
                    ?.toString() ??
                '0.0 km';

    // ----------------------------------------------------------
    // PEE / POOP
    // ----------------------------------------------------------

    final int peeCount =
        _toInt(
      sessionData['peeCount'] ??
          activeData['peeCount'],
    );

    final int poopCount =
        _toInt(
      sessionData['poopCount'] ??
          activeData['poopCount'],
    );

    // ----------------------------------------------------------
    // CURRENT LOCATION
    // ----------------------------------------------------------

    final Map<String, dynamic>
        currentLocation =
        _mapValue(
      sessionData['currentLocation'],
    );

    final double currentLat =
        _toDouble(
      currentLocation['lat'] ??
          activeData['currentLat'],
    );

    final double currentLng =
        _toDouble(
      currentLocation['lng'] ??
          activeData['currentLng'],
    );

    // ----------------------------------------------------------
    // ROUTE
    // ----------------------------------------------------------

    final List<dynamic> route =
        _listValue(
      sessionData['routeCoordinates'],
    );

    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: orange,
        surfaceTintColor: orange,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'Live Walk',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _isEndingWalk
                ? null
                : _showEndWalkDialog,
            icon: const Icon(
              Icons.stop_circle_outlined,
              color: Colors.white,
            ),
            tooltip: 'End Walk',
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // ACTIVE STATUS
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                color: orange,
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 9),

                  const Text(
                    'Walk Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(.9),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(width: 7),

                  const Icon(
                    Icons
                        .directions_walk_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  25,
                ),
                child: Column(
                  children: [
                    // ==========================================
                    // OWNER
                    // ==========================================

                    _ownerCard(),

                    const SizedBox(height: 16),

                    // ==========================================
                    // LIVE MAP
                    // ==========================================

                    _liveMapCard(
                      latitude: currentLat,
                      longitude: currentLng,
                      routeCount: route.length,
                    ),

                    const SizedBox(height: 16),

                    // ==========================================
                    // MAIN STATS
                    // ==========================================

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon:
                                Icons.timer_outlined,
                            title: 'Duration',
                            value: duration,
                            iconColor: orange,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _statCard(
                            icon:
                                Icons.route_rounded,
                            title: 'Distance',
                            value: distance,
                            iconColor: blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // DOG EVENTS
                    // ==========================================

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon:
                                Icons.water_drop_rounded,
                            title: 'Pee',
                            value:
                                peeCount.toString(),
                            iconColor: blue,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _statCard(
                            icon:
                                Icons.pets_rounded,
                            title: 'Poop',
                            value:
                                poopCount.toString(),
                            iconColor: green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ==========================================
                    // LOCATION INFO
                    // ==========================================

                    _locationInfoCard(
                      latitude: currentLat,
                      longitude: currentLng,
                      routeCount: route.length,
                    ),

                    const SizedBox(height: 22),

                    // ==========================================
                    // END WALK
                    // ==========================================

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isEndingWalk
                            ? null
                            : _showEndWalkDialog,

                        icon: _isEndingWalk
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .stop_circle_outlined,
                              ),

                        label: Text(
                          _isEndingWalk
                              ? 'Ending Walk...'
                              : 'End Walk',
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor:
                              Colors.white,
                          disabledBackgroundColor:
                              red.withOpacity(.65),
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OWNER CARD
  // ============================================================

_ownerCard(
  ownerId: activeData['ownerId']?.toString().trim() ?? '',
),
  final String displayOwnerId =
      ownerId.isNotEmpty ? ownerId : 'Owner ID unavailable';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.045),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: blue.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: blue,
            size: 28,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DOG OWNER',
                style: TextStyle(
                  color: muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                widget.ownerName.isEmpty
                    ? 'Owner'
                    : widget.ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: dark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Owner ID: $displayOwnerId',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),

              if (widget.ownerPhone != null &&
                  widget.ownerPhone!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.ownerPhone!,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ACTIVE',
            style: TextStyle(
              color: green,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ),
      ],
    ),
  );
}


  // ============================================================
  // LIVE MAP CARD
  // ============================================================

  Widget _liveMapCard({
    required double latitude,
    required double longitude,
    required int routeCount,
  }) {
    final bool hasLocation =
        latitude != 0.0 ||
            longitude != 0.0;

    return Container(
      width: double.infinity,
      height: 285,
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFE7EEF0),
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color:
              const Color(0xFFD6E0E2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.06),
            blurRadius: 13,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(21),
        child: Stack(
          children: [
            // --------------------------------------------------
            // MAP PLACEHOLDER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              height: double.infinity,
              decoration:
                  const BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF1F2),
                    Color(0xFFDCE8EA),
                  ],
                ),
              ),
              child: CustomPaint(
                painter:
                    _MapGridPainter(),
              ),
            ),

            // --------------------------------------------------
            // CENTER LOCATION
            // --------------------------------------------------

            Center(
              child: Container(
                width: 62,
                height: 62,
                decoration:
                    BoxDecoration(
                  color:
                      orange.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin:
                      const EdgeInsets.all(
                    15,
                  ),
                  decoration:
                      const BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .directions_walk_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // TOP LABEL
            // --------------------------------------------------

            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withOpacity(.95),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .my_location_rounded,
                      color: blue,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LIVE LOCATION',
                      style:
                          TextStyle(
                        color: dark,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------
            // ROUTE COUNT
            // --------------------------------------------------

            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withOpacity(.95),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  '$routeCount points',
                  style:
                      const TextStyle(
                    color: dark,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // LOCATION STATUS
            // --------------------------------------------------

            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withOpacity(.95),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      hasLocation
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_off_rounded,
                      color: hasLocation
                          ? green
                          : muted,
                      size: 14,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      hasLocation
                          ? 'GPS CONNECTED'
                          : 'WAITING FOR GPS',
                      style:
                          TextStyle(
                        color: hasLocation
                            ? green
                            : muted,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION INFO
  // ============================================================

  Widget _locationInfoCard({
    required double latitude,
    required double longitude,
    required int routeCount,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: cardBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color:
                      blue.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: blue,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Current Location',
                  style:
                      TextStyle(
                    color: dark,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              Text(
                '$routeCount pts',
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(
            height: 1,
            color: Color(0xFFE9ECEE),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _coordinateItem(
                  'Latitude',
                  latitude
                      .toStringAsFixed(6),
                ),
              ),

              Container(
                width: 1,
                height: 30,
                color:
                    const Color(0xFFE9ECEE),
              ),

              Expanded(
                child: _coordinateItem(
                  'Longitude',
                  longitude
                      .toStringAsFixed(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COORDINATE
  // ============================================================

  Widget _coordinateItem(
    String title,
    String value,
  ) {
    return Column(
      children: [
        Text(
          title,
          style:
              const TextStyle(
            color: muted,
            fontSize: 9,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style:
              const TextStyle(
            color: dark,
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.035),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  iconColor.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style:
                const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color: dark,
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
  // END WALK DIALOG
  // ============================================================

  void _showEndWalkDialog() {
    if (_isEndingWalk) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          title: const Text(
            'End Walk?',
            style: TextStyle(
              color: dark,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          content: const Text(
            'Are you sure you want to end this walk?',
            style: TextStyle(
              color: muted,
              height: 1.4,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Keep Walking',
                style: TextStyle(
                  color: dark,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await _endWalk();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
              ),
              child: const Text(
                'End Walk',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // COMPLETED SCREEN
  // ============================================================

  Widget _completedScreen(
    Map<String, dynamic> data,
  ) {
    final String duration =
        data['duration']
                ?.toString() ??
            '00:00:00';

    final String distance =
        data['distance']
                ?.toString() ??
            '0.0 km';

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: orange,
        surfaceTintColor: orange,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Walk Completed',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFEAF7EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .check_circle_rounded,
                  size: 58,
                  color: green,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Walk Completed',
                style:
                    TextStyle(
                  color: dark,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'This walk has been successfully completed.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color: muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child:
                        _completedStat(
                      Icons
                          .timer_outlined,
                      'Duration',
                      duration,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child:
                        _completedStat(
                      Icons
                          .route_rounded,
                      'Distance',
                      distance,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child:
                    ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        orange,
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
                  child:
                      const Text(
                    'Back to Walker Home',
                    style:
                        TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
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
  // COMPLETED STAT
  // ============================================================

  Widget _completedStat(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: cardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: orange,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style:
                const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style:
                const TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR SCREEN
  // ============================================================

  Widget _errorScreen(
    String error,
  ) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: orange,
        foregroundColor:
            Colors.white,
        title: const Text(
          'Live Walk',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: red,
                size: 65,
              ),

              const SizedBox(height: 15),

              const Text(
                'Unable to load walk',
                style:
                    TextStyle(
                  color: dark,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                error,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      orange,
                  foregroundColor:
                      Colors.white,
                ),
                child:
                    const Text(
                  'Go Back',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  Map<String, dynamic> _mapValue(
    dynamic value,
  ) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  List<dynamic> _listValue(
    dynamic value,
  ) {
    if (value is List) {
      return value;
    }

    return <dynamic>[];
  }

  String _formatDuration(
    int totalSeconds,
  ) {
    final int hours =
        totalSeconds ~/ 3600;

    final int minutes =
        (totalSeconds % 3600) ~/ 60;

    final int seconds =
        totalSeconds % 60;

    final String hh =
        hours.toString().padLeft(
              2,
              '0',
            );

    final String mm =
        minutes.toString().padLeft(
              2,
              '0',
            );

    final String ss =
        seconds.toString().padLeft(
              2,
              '0',
            );

    return '$hh:$mm:$ss';
  }
}

// ============================================================
// SIMPLE MAP GRID
// ============================================================

class _MapGridPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint paint =
        Paint()
          ..color =
              const Color(0xFFD3DFE1)
          ..strokeWidth = 1;

    const double gap = 45;

    for (
      double x = 0;
      x <= size.width;
      x += gap
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (
      double y = 0;
      y <= size.height;
      y += gap
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    final Paint roadPaint =
        Paint()
          ..color =
              const Color(0xFFC5D3D6)
          ..strokeWidth = 9
          ..strokeCap =
              StrokeCap.round;

    canvas.drawLine(
      Offset(
        0,
        size.height * .72,
      ),
      Offset(
        size.width,
        size.height * .28,
      ),
      roadPaint,
    );

    canvas.drawLine(
      Offset(
        size.width * .20,
        0,
      ),
      Offset(
        size.width * .78,
        size.height,
      ),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
