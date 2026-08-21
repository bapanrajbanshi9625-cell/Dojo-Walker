import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/walk_request_service.dart';
import '../services/walker_location_service.dart';
import '../widgets/live_walk_bottom_sheet.dart';
import '../widgets/live_walk_map.dart';
import '../widgets/live_walk_sos_sheet.dart';

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
  static const Color orange = Color(0xFFFF6600);
  static const Color dark = Color(0xFF263746);
  static const Color red = Color(0xFFE53935);

  final WalkRequestService _service =
      WalkRequestService.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  StreamSubscription<Position>? _locationSubscription;

  bool _ending = false;
  bool _gpsStarting = false;
  bool _gpsActive = false;

  Position? _lastPosition;

  double _totalDistanceKm = 0;

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

    return widget.walkId;
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

    _startGpsTracking();
  }

  // ============================================================
  // START GPS
  // ============================================================

  Future<void> _startGpsTracking() async {
    if (_gpsStarting || _gpsActive) {
      return;
    }

    _gpsStarting = true;

    try {
      final bool allowed =
          await _locationService.ensurePermission();

      if (!allowed) {
        if (mounted) {
          _showGpsError(
            'Location permission is required for Live Walk.',
          );
        }

        return;
      }

      // --------------------------------------------------------
      // GET FIRST LOCATION
      // --------------------------------------------------------

      final Position? firstPosition =
          await _locationService.getCurrentLocation();

      if (firstPosition != null) {
        await _handlePosition(firstPosition);
      }

      // --------------------------------------------------------
      // START CONTINUOUS GPS
      // --------------------------------------------------------

      final bool started =
          await _locationService.startTracking();

      if (!started) {
        if (mounted) {
          _showGpsError(
            'Unable to start GPS tracking.',
          );
        }

        return;
      }

      await _locationSubscription?.cancel();

      _locationSubscription =
          _locationService.locationStream.listen(
        (Position position) {
          _handlePosition(position);
        },
        onError: (Object error) {
          debugPrint(
            'Walker GPS stream error: $error',
          );
        },
      );

      _gpsActive = true;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        'GPS start error: $e',
      );

      if (mounted) {
        _showGpsError(
          'Unable to connect to GPS.',
        );
      }
    } finally {
      _gpsStarting = false;
    }
  }

  // ============================================================
  // HANDLE GPS POSITION
  // ============================================================

  Future<void> _handlePosition(
    Position position,
  ) async {
    if (!mounted && _ending) {
      return;
    }

    // ----------------------------------------------------------
    // DISTANCE FROM PREVIOUS GPS POINT
    // ----------------------------------------------------------

    if (_lastPosition != null) {
      final double segmentKm =
          _locationService.distanceInKm(
        walkerLatitude:
            _lastPosition!.latitude,
        walkerLongitude:
            _lastPosition!.longitude,
        requestLatitude:
            position.latitude,
        requestLongitude:
            position.longitude,
      );

      // Ignore impossible GPS jumps.
      if (segmentKm <= 0.5) {
        _totalDistanceKm += segmentKm;
      }
    }

    _lastPosition = position;

    // ----------------------------------------------------------
    // ROUTE POINT
    // ----------------------------------------------------------

    final Map<String, dynamic> routePoint =
        <String, dynamic>{
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp':
          DateTime.now().millisecondsSinceEpoch,
    };

    // ----------------------------------------------------------
    // PREVENT SAME GPS POINT DUPLICATES
    // ----------------------------------------------------------

    bool shouldAddPoint = true;

    if (_routeCoordinates.isNotEmpty) {
      final Map<String, dynamic> last =
          _routeCoordinates.last;

      final double? lastLat =
          double.tryParse(
        last['lat']?.toString() ?? '',
      );

      final double? lastLng =
          double.tryParse(
        last['lng']?.toString() ?? '',
      );

      if (lastLat != null && lastLng != null) {
        final double distanceMeters =
            Geolocator.distanceBetween(
          lastLat,
          lastLng,
          position.latitude,
          position.longitude,
        );

        if (distanceMeters < 5) {
          shouldAddPoint = false;
        }
      }
    }

    if (shouldAddPoint) {
      _routeCoordinates.add(routePoint);
    }

    // ----------------------------------------------------------
    // FIRESTORE UPDATE
    // ----------------------------------------------------------

    try {
      final Map<String, dynamic> updateData =
          <String, dynamic>{
        'currentLocation': <String, dynamic>{
          'lat': position.latitude,
          'lng': position.longitude,
        },

        'currentLat': position.latitude,

        'currentLng': position.longitude,

        'distanceKm': _totalDistanceKm,

        'gpsAccuracy': position.accuracy,

        'gpsHeading': position.heading,

        'gpsSpeed': position.speed,

        'gpsUpdatedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      if (shouldAddPoint) {
        updateData['routeCoordinates'] =
            _routeCoordinates;
      }

      await _sessionRef.update(
        updateData,
      );
    } catch (e) {
      debugPrint(
        'Live GPS Firestore update error: $e',
      );
    }
  }

  // ============================================================
  // LOAD EXISTING ROUTE
  // ============================================================

  void _loadExistingRoute(
    Map<String, dynamic> data,
  ) {
    if (_routeLoaded) {
      return;
    }

    _routeLoaded = true;

    final dynamic raw =
        data['routeCoordinates'];

    if (raw is! List) {
      return;
    }

    for (final dynamic item in raw) {
      if (item is Map) {
        final dynamic lat =
            item['lat'] ??
                item['latitude'];

        final dynamic lng =
            item['lng'] ??
                item['longitude'];

        final double? latitude =
            double.tryParse(
          lat?.toString() ?? '',
        );

        final double? longitude =
            double.tryParse(
          lng?.toString() ?? '',
        );

        if (latitude != null &&
            longitude != null &&
            latitude != 0 &&
            longitude != 0) {
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
    }

    // ----------------------------------------------------------
    // EXISTING DISTANCE
    // ----------------------------------------------------------

    final dynamic existingDistance =
        data['distanceKm'];

    final double? parsedDistance =
        double.tryParse(
      existingDistance?.toString() ?? '',
    );

    if (parsedDistance != null &&
        parsedDistance >= 0) {
      _totalDistanceKm =
          parsedDistance;
    }
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> _stopGpsTracking() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    await _locationService.stopTracking();

    _gpsActive = false;
  }

  // ============================================================
  // END WALK
  // ============================================================

  Future<void> _endWalk() async {
    if (_ending) return;

    setState(() {
      _ending = true;
    });

    try {
      await _stopGpsTracking();

      await _service.endLiveWalk(
        widget.walkId,
        sessionId: sessionId,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _ending = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
            ),
          ),
        );

      // If ending failed, GPS should continue.
      if (!_gpsActive) {
        await _startGpsTracking();
      }
    }
  }

  // ============================================================
  // END WALK CONFIRMATION
  // ============================================================

  void _confirmEndWalk() {
    if (_ending) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'End Walk?',
            style: TextStyle(
              color: dark,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
            style: TextStyle(
              color: Color(0xFF7A8289),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _endWalk();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'End Walk',
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
  // SUPPORT
  // ============================================================

  void _openSupport() {
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
            color: Colors.white,
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
                    color: const Color(
                      0xFFD7DCE0,
                    ),
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
                  color: orange,
                  size: 38,
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Walk Support',
                  style: TextStyle(
                    color: dark,
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
                    color:
                        Color(0xFF7A8289),
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
                      Navigator.pop(
                        context,
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
                          orange,
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
  // GPS ERROR
  // ============================================================

  void _showGpsError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: red,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream: _sessionStream,
      builder: (
        context,
        snapshot,
      ) {
        final Map<String, dynamic> data =
            snapshot.data?.data() ??
                <String, dynamic>{};

        // ------------------------------------------------------
        // LOAD EXISTING ROUTE ONCE
        // ------------------------------------------------------

        _loadExistingRoute(data);

        final String status =
            data['status']
                    ?.toString()
                    .toLowerCase() ??
                'live';

        // ------------------------------------------------------
        // SESSION ENDED
        // ------------------------------------------------------

        if (status == 'completed' ||
            status == 'ended') {
          if (_gpsActive) {
            _stopGpsTracking();
          }

          return _completedScreen(data);
        }

        return Scaffold(
          backgroundColor:
              Colors.white,

          extendBodyBehindAppBar:
              true,

          // ====================================================
          // APP BAR
          // ====================================================

          appBar: AppBar(
            backgroundColor: orange,
            surfaceTintColor: orange,
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
                onPressed: _openSos,
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
                    _openSupport,
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
              // ACTUAL FIRESTORE GPS MAP
              // ------------------------------------------------

              Positioned.fill(
                child: LiveWalkMap(
                  sessionData:
                      data,
                ),
              ),

              // ------------------------------------------------
              // LIVE BADGE
              // ------------------------------------------------

              Positioned(
                top: MediaQuery.of(
                          context,
                        )
                            .padding
                            .top +
                    62,
                left: 16,
                child:
                    _liveBadge(),
              ),

              // ------------------------------------------------
              // GPS STATUS
              // ------------------------------------------------

              Positioned(
                top: MediaQuery.of(
                          context,
                        )
                            .padding
                            .top +
                    62,
                right: 16,
                child:
                    _gpsBadge(data),
              ),

              // ------------------------------------------------
              // BOTTOM SHEET
              // ------------------------------------------------

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
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(.15),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
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
                Color(0xFF16A34A),
            size: 9,
          ),
          SizedBox(width: 7),
          Text(
            'LIVE',
            style: TextStyle(
              color: dark,
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
    final dynamic lat =
        data['currentLat'];

    final dynamic lng =
        data['currentLng'];

    final bool hasLocation =
        lat != null &&
            lng != null;

    final Color color =
        hasLocation
            ? const Color(
                0xFF16A34A,
              )
            : orange;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(.15),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
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
            hasLocation
                ? 'GPS'
                : 'GPS...',
            style: TextStyle(
              color: dark,
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
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),

      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        backgroundColor: orange,
        foregroundColor:
            Colors.white,
        centerTitle: true,
        title: const Text(
          'WALK COMPLETED',
          style: TextStyle(
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
              const Icon(
                Icons
                    .check_circle_rounded,
                color:
                    Color(0xFF16A34A),
                size: 80,
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'Walk Completed',
                style: TextStyle(
                  color: dark,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                'Distance: '
                '${_totalDistanceKm.toStringAsFixed(2)} km',
                style:
                    const TextStyle(
                  color:
                      Color(0xFF7A8289),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                ),
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
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  child:
                      const Text(
                    'Back to Walker Home',
                    style: TextStyle(
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.stopTracking();

    super.dispose();
  }
}
