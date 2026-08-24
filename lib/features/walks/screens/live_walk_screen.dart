import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/live_walk_background_service.dart';
import '../../../services/walk_request_service.dart';
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
  final WalkRequestService _service =
      WalkRequestService.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  final LiveWalkBackgroundService _backgroundService =
      LiveWalkBackgroundService.instance;

  StreamSubscription<Position>? _locationSubscription;

  bool _ending = false;
  bool _gpsStarting = false;
  bool _gpsActive = false;
  bool _routeLoaded = false;

  double _totalDistanceKm = 0.0;

  final List<Map<String, dynamic>> _routeCoordinates =
      <Map<String, dynamic>>[];

  // ============================================================
  // SESSION ID
  // ============================================================

  String get sessionId {
    final String? value = widget.sessionId?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'session-${widget.walkId}';
  }

  // ============================================================
  // FIRESTORE SESSION
  // ============================================================

  DocumentReference<Map<String, dynamic>> get _sessionRef {
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

    unawaited(_startGpsTracking());
  }

  // ============================================================
  // START GPS
  // ============================================================

  Future<void> _startGpsTracking() async {
    if (_gpsStarting || _gpsActive || _ending) {
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

      if (_ending) {
        return;
      }

      // --------------------------------------------------------
      // RESTORE SESSION
      // --------------------------------------------------------

      double initialDistance = _totalDistanceKm;

      int initialSteps = 0;
      int initialPee = 0;
      int initialPoop = 0;

      DateTime? initialStartedAt;

      final List<Map<String, dynamic>> initialRoute =
          <Map<String, dynamic>>[];

      try {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _sessionRef.get();

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data != null) {
          _loadExistingRoute(data);

          final double? distance =
              _toDouble(data['distanceKm']);

          if (distance != null && distance >= 0) {
            initialDistance = distance;
          }

          initialSteps =
              _toInt(data['steps']) ?? 0;

          initialPee =
              _toInt(data['peeCount']) ?? 0;

          initialPoop =
              _toInt(data['poopCount']) ?? 0;

          final dynamic startedAt =
              data['startedAt'];

          if (startedAt is Timestamp) {
            initialStartedAt =
                startedAt.toDate();
          } else if (startedAt is DateTime) {
            initialStartedAt = startedAt;
          }

          final dynamic rawRoute =
              data['routeCoordinates'];

          if (rawRoute is List) {
            for (final dynamic item in rawRoute) {
              if (item is Map) {
                initialRoute.add(
                  Map<String, dynamic>.from(item),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint(
          'Existing session read failed: $e',
        );
      }

      // --------------------------------------------------------
      // START BACKGROUND GPS
      // --------------------------------------------------------

      final bool started =
          await _backgroundService.start(
        walkId: widget.walkId,
        sessionId: sessionId,
        initialDistanceKm: initialDistance,
        initialSteps: initialSteps,
        initialPeeCount: initialPee,
        initialPoopCount: initialPoop,
        initialStartedAt: initialStartedAt,
        initialRoute: initialRoute,
      );

      if (!started) {
        if (mounted) {
          _showGpsError(
            'Unable to start GPS tracking.',
          );
        }

        return;
      }

      // --------------------------------------------------------
      // CENTRAL GPS STREAM
      // --------------------------------------------------------

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

      _gpsActive = true;

      // --------------------------------------------------------
      // LAST POSITION
      // --------------------------------------------------------

      final Position? current =
          _backgroundService.lastPosition;

      if (current != null &&
          mounted &&
          !_ending) {
        _handlePosition(current);
      }

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
  // POSITION
  // ============================================================

  void _handlePosition(Position position) {
    if (!mounted || _ending) {
      return;
    }

    final double distance =
        _backgroundService.totalDistanceKm;

    if (distance >= 0) {
      _totalDistanceKm = distance;
    }

    setState(() {});
  }

  // ============================================================
  // LOAD ROUTE
  // ============================================================

  void _loadExistingRoute(
    Map<String, dynamic> data,
  ) {
    if (_routeLoaded) {
      return;
    }

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
              'timestamp': item['timestamp'],
          },
        );
      }
    }

    final double? distance =
        _toDouble(data['distanceKm']);

    if (distance != null && distance >= 0) {
      _totalDistanceKm = distance;
    }

    _routeLoaded = true;
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> _stopGpsTracking() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    await _backgroundService.stop();

    _gpsActive = false;
  }

  // ============================================================
  // END WALK
  // ============================================================

  Future<void> _endWalk() async {
    if (_ending || !mounted) {
      return;
    }

    setState(() {
      _ending = true;
    });

    try {
      await _stopGpsTracking();

      await _service.endLiveWalk(
        widget.walkId,
        sessionId: sessionId,
      );

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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );

      if (!_gpsActive) {
        unawaited(
          _startGpsTracking(),
        );
      }
    }
  }

  // ============================================================
  // CONFIRM END
  // ============================================================

  void _confirmEndWalk() {
    if (_ending) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'End Walk?',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
            style: TextStyle(
              color: AppColors.grey,
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
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
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
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: AppColors.card,
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
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Need help during this walk?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey,
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
                      Icons.support_agent_rounded,
                    ),
                    label: const Text(
                      'Contact Support',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
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
  // SOS
  // ============================================================

  void _openSos() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
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
                DocumentSnapshot<Map<String, dynamic>>>
            snapshot,
      ) {
        final Map<String, dynamic> data =
            snapshot.data?.data() ??
                <String, dynamic>{};

        // ------------------------------------------------------
        // LOAD ROUTE ONCE
        // ------------------------------------------------------

        if (!_routeLoaded && data.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (!mounted || _routeLoaded) {
                return;
              }

              _loadExistingRoute(data);

              if (mounted) {
                setState(() {});
              }
            },
          );
        }

        final String status =
            data['status']
                    ?.toString()
                    .toLowerCase() ??
                'live';

        // ------------------------------------------------------
        // COMPLETED
        // ------------------------------------------------------

        if (status == 'completed' ||
            status == 'ended') {
          if (_gpsActive) {
            unawaited(
              _stopGpsTracking(),
            );
          }

          return _completedScreen(data);
        }

        // ------------------------------------------------------
        // LIVE
        // ------------------------------------------------------

        return Scaffold(
          backgroundColor: AppColors.card,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            surfaceTintColor: AppColors.primary,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'LIVE WALK',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'SOS',
                onPressed: _ending ? null : _openSos,
                icon: const Icon(
                  Icons.sos_rounded,
                  color: AppColors.white,
                  size: 27,
                ),
              ),
              IconButton(
                tooltip: 'Support',
                onPressed: _ending
                    ? null
                    : _openSupport,
                icon: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: LiveWalkMap(
                  sessionData: data,
                ),
              ),

              Positioned(
                top: 14,
                left: 16,
                child: _liveBadge(),
              ),

              Positioned(
                top: 14,
                right: 16,
                child: _gpsBadge(data),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: LiveWalkBottomSheet(
                  ownerName: widget.ownerName,
                  dogName: widget.dogName,
                  dogBreed: widget.dogBreed,
                  ownerPhone: widget.ownerPhone,
                  sessionData: data,
                  ending: _ending,
                  onEndWalk: _confirmEndWalk,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: AppColors.success,
            size: 9,
          ),
          SizedBox(width: 7),
          Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 10,
              fontWeight: FontWeight.w900,
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
    final double? lat = _toDouble(
      data['currentLocation'] is Map
          ? data['currentLocation']['lat']
          : data['currentLat'],
    );

    final double? lng = _toDouble(
      data['currentLocation'] is Map
          ? data['currentLocation']['lng']
          : data['currentLng'],
    );

    final bool hasLocation =
        lat != null &&
        lng != null &&
        _validCoordinate(
          lat,
          lng,
        );

    final Color color =
        hasLocation
            ? AppColors.success
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            hasLocation ? 'GPS' : 'GPS...',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 9,
              fontWeight: FontWeight.w900,
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
        _toDouble(data['distanceKm']) ??
            _totalDistanceKm;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: const Text(
          'WALK COMPLETED',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 80,
              ),
              const SizedBox(height: 18),
              const Text(
                'Walk Completed',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Distance: '
                '${distance.toStringAsFixed(2)} km',
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Walker Home',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
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
  // HELPERS
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

  bool _validCoordinate(
    double lat,
    double lng,
  ) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();

    // Background GPS को यहाँ stop नहीं करना है.
    // Actual stop केवल End Walk flow में होगा.

    super.dispose();
  }
}
