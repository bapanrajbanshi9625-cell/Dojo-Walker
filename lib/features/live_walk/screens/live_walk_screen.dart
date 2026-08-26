import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/live_walk_background_service.dart';
import '../../../core/services/live_walk_session_service.dart';
import '../../../services/walk_request_service.dart';
import '../services/walker_location_service.dart';
import '../widgets/live_walk_bottom_sheet.dart';
import '../widgets/live_walk_map.dart';
import '../widgets/live_walk_sos_sheet.dart';
import '../widgets/live_walk_start_slider.dart';

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
  State<LiveWalkScreen> createState() =>
      _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final WalkRequestService _service =
      WalkRequestService.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  final LiveWalkBackgroundService _backgroundService =
      LiveWalkBackgroundService.instance;

  final LiveWalkSessionService _sessionService =
      LiveWalkSessionService.instance;

  // ============================================================
  // GPS STREAM
  //
  // IMPORTANT:
  // यह screen GPS START नहीं करती.
  //
  // GPS Active Insta Walk से पहले ही चल रहा होगा.
  // यहाँ केवल existing central GPS stream को observe करेंगे.
  // ============================================================

  StreamSubscription<Position>? _locationSubscription;

  // ============================================================
  // UI STATE
  // ============================================================

  bool _ending = false;

  bool _startingWalk = false;

  bool _walkStarted = false;

  double _totalDistanceKm = 0.0;

  // ============================================================
  // ROUTE
  // ============================================================

  final List<Map<String, dynamic>> _routeCoordinates =
      <Map<String, dynamic>>[];

  bool _routeLoaded = false;

  // ============================================================
  // SESSION ID
  // ============================================================

  String get sessionId {
    final String? value =
        widget.sessionId?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'session-${widget.walkId}';
  }

  // ============================================================
  // FIRESTORE SESSION
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      get _sessionRef {
    return FirebaseFirestore.instance
        .collection('liveWalkSessions')
        .doc(sessionId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _sessionStream {
    return _sessionRef.snapshots();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // IMPORTANT
    //
    // GPS यहां START नहीं किया जा रहा.
    //
    // Insta Walk Active/Search flow से GPS पहले से चलता रहेगा.
    // ----------------------------------------------------------

    unawaited(
      _attachToExistingGpsStream(),
    );
  }

  // ============================================================
  // ATTACH EXISTING GPS STREAM
  // ============================================================

  Future<void> _attachToExistingGpsStream() async {
    if (_ending) {
      return;
    }

    try {
      await _locationSubscription?.cancel();

      _locationSubscription =
          _backgroundService.locationStream.listen(
        (Position position) {
          if (!mounted || _ending) {
            return;
          }

          _handlePosition(position);
        },
        onError: (Object error) {
          debugPrint(
            'Live GPS stream error: $error',
          );
        },
        cancelOnError: false,
      );

      final Position? current =
          _backgroundService.lastPosition;

      if (current != null &&
          mounted &&
          !_ending) {
        _handlePosition(current);
      }
    } catch (e) {
      debugPrint(
        'Attach GPS stream error: $e',
      );
    }
  }

  // ============================================================
  // POSITION
  // ============================================================

  void _handlePosition(
    Position position,
  ) {
    if (!mounted || _ending) {
      return;
    }

    final double distance =
        _backgroundService.totalDistanceKm;

    if (distance >= 0) {
      _totalDistanceKm = distance;
    }

    // ----------------------------------------------------------
    // IMPORTANT
    //
    // GPS position सिर्फ tracking के लिए है.
    // Walk start/stop इससे control नहीं होता.
    // ----------------------------------------------------------

    setState(() {});
  }

  // ============================================================
  // LOAD EXISTING SESSION
  // ============================================================

  void _loadExistingSession(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // ROUTE
    // ----------------------------------------------------------

    if (!_routeLoaded) {
      final dynamic rawRoute =
          data['routeCoordinates'];

      if (rawRoute is List) {
        for (final dynamic item in rawRoute) {
          if (item is! Map) {
            continue;
          }

          final double? latitude =
              _toDouble(
            item['lat'] ??
                item['latitude'],
          );

          final double? longitude =
              _toDouble(
            item['lng'] ??
                item['longitude'],
          );

          if (latitude == null ||
              longitude == null) {
            continue;
          }

          if (!_validCoordinate(
            latitude,
            longitude,
          )) {
            continue;
          }

          _routeCoordinates.add(
            <String, dynamic>{
              'lat': latitude,
              'lng': longitude,
              if (item['timestamp'] != null)
                'timestamp':
                    item['timestamp'],
            },
          );
        }
      }

      _routeLoaded = true;
    }

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double? distance =
        _toDouble(data['distanceKm']);

    if (distance != null &&
        distance >= 0) {
      _totalDistanceKm = distance;
    }

    // ----------------------------------------------------------
    // WALK STATUS
    // ----------------------------------------------------------

    final String status =
        data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status == 'active' ||
        status == 'started') {
      _walkStarted = true;
    }
  }

  // ============================================================
  // START WALK
  //
  // IMPORTANT:
  //
  // यह GPS START नहीं करता.
  //
  // GPS पहले से चलता रहेगा.
  //
  // यह केवल:
  // status = active
  // startedAt = server timestamp
  // ============================================================

  Future<void> _startWalk() async {
    if (_walkStarted ||
        _startingWalk ||
        _ending) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _startingWalk = true;
    });

    try {
      await _sessionService.startWalk(
        sessionId: sessionId,
        walkId: widget.walkId,
        ownerUid: widget.ownerUid,
        ownerName: widget.ownerName,
        dogName: widget.dogName,
        dogBreed: widget.dogBreed,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _walkStarted = true;
        _startingWalk = false;
      });
    } catch (e) {
      debugPrint(
        'Start walk error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _startingWalk = false;
      });

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // STOP GPS
  //
  // केवल COMPLETED के बाद call होगा.
  // ============================================================

  Future<void> _stopGpsTracking() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    try {
      await _backgroundService.stop();
    } catch (e) {
      debugPrint(
        'GPS stop error: $e',
      );
    }
  }

  // ============================================================
  // END WALK
  // ============================================================

  Future<void> _endWalk() async {
    if (_ending || !mounted) {
      return;
    }

    if (!_walkStarted) {
      _showError(
        'Please start the walk first.',
      );
      return;
    }

    setState(() {
      _ending = true;
    });

    try {
      // --------------------------------------------------------
      // FIRST: COMPLETE FIRESTORE SESSION
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        sessionId: sessionId,
      );

      // --------------------------------------------------------
      // ALSO END WALK REQUEST
      // --------------------------------------------------------

      await _service.endLiveWalk(
        widget.walkId,
        sessionId: sessionId,
      );

      // --------------------------------------------------------
      // NOW GPS CAN STOP
      // --------------------------------------------------------

      await _stopGpsTracking();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint(
        'End walk error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _ending = false;
      });

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );

      // --------------------------------------------------------
      // IMPORTANT
      //
      // Error होने पर GPS stop नहीं करेंगे.
      // Walk अभी active माना जाएगा.
      // --------------------------------------------------------

      if (_locationSubscription == null) {
        unawaited(
          _attachToExistingGpsStream(),
        );
      }
    }
  }

  // ============================================================
  // CONFIRM END WALK
  // ============================================================

  void _confirmEndWalk() {
    if (_ending) {
      return;
    }

    if (!_walkStarted) {
      _showError(
        'Start the walk before ending it.',
      );
      return;
    }

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
            'End Walk?',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
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
                'Keep Walking',
                style: TextStyle(
                  color:
                      AppColors.secondary,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                unawaited(
                  _endWalk(),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.error,
                foregroundColor:
                    Colors.white,
                elevation: 0,
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
  // SUPPORT
  // ============================================================

  void _openSupport() {
    if (_ending) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (_) {
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
              top: Radius.circular(25),
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
                  Icons.support_agent_rounded,
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
                        context,
                      ).pop();

                      _showMessage(
                        'Support contact will be connected soon.',
                      );
                    },
                    icon: const Icon(
                      Icons
                          .support_agent_rounded,
                    ),
                    label: const Text(
                      'Contact Support',
                    ),
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
  // SOS
  // ============================================================

  void _openSos() {
    if (_ending) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return const LiveWalkSosSheet();
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _sessionStream,
      builder: (
        BuildContext context,
        AsyncSnapshot<
                DocumentSnapshot<
                    Map<String, dynamic>>>
            snapshot,
      ) {
        final Map<String, dynamic> data =
            snapshot.data?.data() ??
                <String, dynamic>{};

        // ------------------------------------------------------
        // LOAD SESSION
        // ------------------------------------------------------

        if (data.isNotEmpty) {
          _loadExistingSession(data);
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                'live';

        // ------------------------------------------------------
        // FIRESTORE SAYS WALK STARTED
        // ------------------------------------------------------

        final bool firestoreWalkStarted =
            status == 'active' ||
            status == 'started';

        // ------------------------------------------------------
        // KEEP LOCAL STATE IN SYNC
        // ------------------------------------------------------

        if (firestoreWalkStarted &&
            !_walkStarted) {
          WidgetsBinding.instance
              .addPostFrameCallback(
            (_) {
              if (!mounted) {
                return;
              }

              if (!_walkStarted) {
                setState(() {
                  _walkStarted = true;
                });
              }
            },
          );
        }

        // ------------------------------------------------------
        // COMPLETED
        // ------------------------------------------------------

        if (status == 'completed' ||
            status == 'ended') {
          if (_locationSubscription !=
              null) {
            WidgetsBinding.instance
                .addPostFrameCallback(
              (_) {
                if (!mounted) {
                  return;
                }

                unawaited(
                  _stopGpsTracking(),
                );
              },
            );
          }

          return _completedScreen(
            data,
          );
        }

        // ------------------------------------------------------
        // SHOW START SLIDER
        // ------------------------------------------------------

        final bool showStartSlider =
            !_walkStarted &&
            !firestoreWalkStarted &&
            !_ending;

        // ------------------------------------------------------
        // LIVE SCREEN
        // ------------------------------------------------------

        return Scaffold(
          backgroundColor:
              AppColors.cardBackground,

          // ====================================================
          // APP BAR
          // ====================================================

          appBar: AppBar(
            backgroundColor:
                AppColors.primary,
            surfaceTintColor:
                AppColors.primary,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading:
                false,
            title: const Text(
              'LIVE WALK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'SOS',
                onPressed:
                    _ending
                        ? null
                        : _openSos,
                icon: const Icon(
                  Icons.sos_rounded,
                  color:
                      Colors.white,
                  size: 27,
                ),
              ),
              IconButton(
                tooltip: 'Support',
                onPressed:
                    _ending
                        ? null
                        : _openSupport,
                icon: const Icon(
                  Icons
                      .support_agent_rounded,
                  color:
                      Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          // ====================================================
          // BODY
          // ====================================================

          body: Stack(
            children: [
              // ------------------------------------------------
              // MAP
              // ------------------------------------------------

              Positioned.fill(
                child: LiveWalkMap(
                  sessionData: data,
                ),
              ),

              // ------------------------------------------------
              // LIVE BADGE
              // ------------------------------------------------

              Positioned(
                top: 14,
                left: 16,
                child:
                    _liveBadge(),
              ),

              // ------------------------------------------------
              // GPS BADGE
              // ------------------------------------------------

              Positioned(
                top: 14,
                right: 16,
                child:
                    _gpsBadge(data),
              ),

              // ------------------------------------------------
              // BOTTOM INFORMATION
              //
              // Walk started हो चुका है तभी normal
              // bottom sheet दिखेगा.
              // ------------------------------------------------

              if (_walkStarted ||
                  firestoreWalkStarted)
                Align(
                  alignment:
                      Alignment.bottomCenter,
                  child:
                      LiveWalkBottomSheet(
                    ownerName:
                        widget.ownerName,
                    dogName:
                        widget.dogName,
                    dogBreed:
                        widget.dogBreed,
                    ownerPhone:
                        widget.ownerPhone,
                    sessionData:
                        data,
                    ending:
                        _ending,
                    onEndWalk:
                        _confirmEndWalk,
                  ),
                ),

              // ------------------------------------------------
              // START WALK SLIDER
              //
              // Reach के बाद यही दिखाई देगा.
              // ------------------------------------------------

              if (showStartSlider)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: SafeArea(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        // --------------------------------------
                        // SMALL INFORMATION
                        // --------------------------------------

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color:
                                    Color(0x22000000),
                                blurRadius:
                                    10,
                                offset:
                                    Offset(
                                  0,
                                  3,
                                ),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons
                                    .location_on_rounded,
                                color:
                                    AppColors.success,
                                size: 15,
                              ),
                              SizedBox(
                                width: 6,
                              ),
                              Text(
                                'GPS is active',
                                style:
                                    TextStyle(
                                  color:
                                      AppColors.secondary,
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 9,
                        ),

                        // --------------------------------------
                        // START SLIDER
                        // --------------------------------------

                        LiveWalkStartSlider(
                          enabled:
                              !_startingWalk &&
                                  !_ending,
                          onStarted:
                              _startWalk,
                        ),

                        if (_startingWalk)
                          const Padding(
                            padding:
                                EdgeInsets.only(
                              top: 8,
                            ),
                            child:
                                SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // LIVE BADGE
  // ============================================================

  Widget _liveBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color:
                Color(0x26000000),
            blurRadius: 10,
            offset:
                Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color:
                AppColors.success,
            size: 9,
          ),
          SizedBox(
            width: 7,
          ),
          Text(
            'LIVE',
            style: TextStyle(
              color:
                  AppColors.secondary,
              fontSize: 10,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GPS BADGE
  // ============================================================

  Widget _gpsBadge(
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic>?
        currentLocation =
        _readMap(
      data['currentLocation'],
    );

    final double? lat =
        _toDouble(
      currentLocation?['lat'] ??
          currentLocation?[
              'latitude'] ??
          data['currentLat'],
    );

    final double? lng =
        _toDouble(
      currentLocation?['lng'] ??
          currentLocation?[
              'longitude'] ??
          data['currentLng'],
    );

    final bool hasLocation =
        lat != null &&
        lng != null &&
        _validCoordinate(
          lat,
          lng,
        );

    final bool centralGpsActive =
        _backgroundService
            .lastPosition !=
            null;

    final bool gpsReady =
        hasLocation ||
        centralGpsActive;

    final Color color =
        gpsReady
            ? AppColors.success
            : AppColors.primary;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color:
                Color(0x26000000),
            blurRadius: 10,
            offset:
                Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            gpsReady
                ? 'GPS'
                : 'GPS...',
            style:
                const TextStyle(
              color:
                  AppColors.secondary,
              fontSize: 9,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETED SCREEN
  // ============================================================

  Widget _completedScreen(
    Map<String, dynamic> data,
  ) {
    final double distance =
        _toDouble(
              data['distanceKm'],
            ) ??
            _totalDistanceKm;

    final int steps =
        _toInt(
              data['steps'],
            ) ??
            0;

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'WALK COMPLETED',
          style: TextStyle(
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.success
                            .withValues(
                      alpha: .10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                        AppColors.success,
                    size: 80,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Walk Completed',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        AppColors.secondary,
                    fontSize: 25,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  '${widget.dogName}\'s walk is complete.',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // ------------------------------------------------
                // STATS
                // ------------------------------------------------

                Row(
                  children: [
                    Expanded(
                      child:
                          _completedStat(
                        distance
                                .toStringAsFixed(
                              2,
                            ) +
                            ' km',
                        'Distance',
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child:
                          _completedStat(
                        '$steps',
                        'Steps',
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 25,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(true);
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
                          14,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'Back to Walker Home',
                      style:
                          TextStyle(
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
      ),
    );
  }

  // ============================================================
  // COMPLETED STAT
  // ============================================================

  Widget _completedStat(
    String value,
    String title,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 10,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(16),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style:
                const TextStyle(
              color:
                  AppColors.secondary,
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 9,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
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
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // MESSAGE
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
              SnackBarBehavior.floating,
          duration:
              const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  // ============================================================
  // SAFE DOUBLE
  // ============================================================

  double? _toDouble(
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
  // SAFE INT
  // ============================================================

  int? _toInt(
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
  // SAFE MAP
  // ============================================================

  Map<String, dynamic>? _readMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return null;
  }

  // ============================================================
  // VALID COORDINATE
  // ============================================================

  bool _validCoordinate(
    double lat,
    double lng,
  ) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 &&
            lng == 0);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();

    // ----------------------------------------------------------
    // IMPORTANT
    //
    // यहां GPS STOP नहीं करना है.
    //
    // GPS पूरे lifecycle में चलता रहेगा.
    // केवल End Walk -> Completed के बाद stop होगा.
    // ----------------------------------------------------------

    super.dispose();
  }
}
