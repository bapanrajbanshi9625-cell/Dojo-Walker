import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_walk_session_controller.dart';
import '../widgets/live_walk_app_bar.dart';
import '../widgets/live_walk_bottom_sheet.dart';
import '../widgets/live_walk_map.dart';

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

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _sessionStream {
    return _controller.sessionStream;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _sessionStream,
      builder: (
        BuildContext context,
        AsyncSnapshot<
                DocumentSnapshot<Map<String, dynamic>>>
            snapshot,
      ) {
        final Map<String, dynamic> firestoreData =
            snapshot.data?.data() ??
                <String, dynamic>{};

        if (firestoreData.isNotEmpty) {
          _lastSessionData =
              Map<String, dynamic>.from(
            firestoreData,
          );

          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (!mounted) {
                return;
              }

              _controller.updateFromSession(
                firestoreData,
              );
            },
          );
        }

        // ======================================================
        // MAP DATA
        //
        // Firestore remains useful for route/location data.
        // Live metrics are taken directly from controller.
        // ======================================================

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
          appBar: LiveWalkAppBar(
            enabled: !ending,
            onSos: _openSos,
            onSupport: _openSupport,
          ),
          body: Stack(
            children: <Widget>[
              // ==================================================
              // FULL SCREEN LIVE MAP
              // ==================================================

              Positioned.fill(
                child: LiveWalkMap(
                  sessionData: sessionData,
                ),
              ),

              // ==================================================
              // BOTTOM DRAGGABLE SHEET
              // ==================================================

              if (walkStarted || ending)
                DraggableScrollableSheet(
                  initialChildSize: .22,
                  minChildSize: .18,
                  maxChildSize: .72,
                  snap: true,
                  snapSizes: const <double>[
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
  // BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet(
    ScrollController scrollController,
    Map<String, dynamic> sessionData,
    bool ending,
  ) {
    // ==========================================================
    // IMPORTANT:
    //
    // Do NOT use Firestore distance/steps here first.
    //
    // Controller contains the live local metric values.
    // ==========================================================

    final double distance =
        _controller.totalDistanceKm;

    final int steps =
        _controller.steps;

    // ==========================================================
    // LIVE DURATION
    //
    // Controller ticker refreshes this every second.
    // ==========================================================

    final String duration =
        _controller.formattedDuration;

    return LiveWalkBottomSheet(
      scrollController: scrollController,
      ending: ending,
      ownerUid: widget.ownerUid,
      ownerName: widget.ownerName,
      dogName: widget.dogName,
      dogBreed: widget.dogBreed,
      distanceKm: distance,
      steps: steps,
      duration: duration,
      peeCount: _controller.peeCount,
      poopCount: _controller.poopCount,
      onCallOwner: _callOwner,
      onActivityConfirmed: _recordDogActivity,
      onComplete: _confirmCompleteWalk,
    );
  }

  // ============================================================
  // CALL OWNER
  // ============================================================

  Future<void> _callOwner() async {
    final String phone =
        widget.ownerPhone?.trim() ?? '';

    if (phone.isEmpty) {
      _showError(
        'Owner phone number is not available.',
      );
      return;
    }

    final String sanitizedPhone =
        phone.replaceAll(
      RegExp(r'\s+'),
      '',
    );

    final Uri uri = Uri(
      scheme: 'tel',
      path: sanitizedPhone,
    );

    try {
      final bool launched =
          await launchUrl(uri);

      if (!launched && mounted) {
        _showError(
          'Unable to open phone dialer.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showError(
          'Unable to open phone dialer.',
        );
      }
    }
  }

  // ============================================================
  // RECORD PEE / POOP
  // ============================================================

  Future<void> _recordDogActivity(
    String type,
  ) async {
    try {
      await _controller.recordDogActivity(
        type: type,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '$type recorded.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        _cleanError(error),
      );

      rethrow;
    }
  }

  // ============================================================
  // COMPLETE WALK CONFIRMATION
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
          backgroundColor: Colors.white,
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
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
                Navigator.of(
                  dialogContext,
                ).pop();

                unawaited(
                  _completeWalk(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
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
      await _controller.endWalk();

      if (!mounted) {
        return;
      }

      // ========================================================
      // FINAL DATA MUST COME FROM CONTROLLER
      //
      // This prevents an old Firestore snapshot from replacing
      // the final live values.
      // ========================================================

      final Map<String, dynamic> resultSessionData =
          Map<String, dynamic>.from(
        _controller.sessionData.isNotEmpty
            ? _controller.sessionData
            : _lastSessionData,
      );

      final double distance =
          _controller.totalDistanceKm;

      final int steps =
          _controller.steps;

      final String duration =
          _controller.formattedDuration;

      final List<Offset> routePoints =
          _extractRoutePoints(
        resultSessionData,
      );

      resultSessionData['distanceKm'] =
          distance;

      resultSessionData['steps'] =
          steps;

      resultSessionData['duration'] =
          duration;

      resultSessionData['durationSeconds'] =
          _controller.durationSeconds;

      resultSessionData['peeCount'] =
          _controller.peeCount;

      resultSessionData['poopCount'] =
          _controller.poopCount;

      _leavingScreen = true;

      Navigator.of(context).pop(
        <String, dynamic>{
          'walkCompleted': true,
          'showReview': true,
          'requestId': widget.requestId,
          'ownerUid': widget.ownerUid,
          'ownerName': widget.ownerName,
          'ownerPhone': widget.ownerPhone,
          'dogName': widget.dogName,
          'dogBreed': widget.dogBreed,
          'distanceKm': distance,
          'steps': steps,
          'duration': duration,
          'durationSeconds':
              _controller.durationSeconds,
          'routePoints': routePoints,
          'sessionData': resultSessionData,
          'peeCount':
              _controller.peeCount,
          'poopCount':
              _controller.poopCount,
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
      backgroundColor: Colors.transparent,
      builder: (
        BuildContext sheetContext,
      ) {
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
      builder: (
        BuildContext sheetContext,
      ) {
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
              children: <Widget>[
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
                      Navigator.of(
                        sheetContext,
                      ).pop();

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
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
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
          children: <Widget>[
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
              cleanOwnerName.isEmpty
                  ? 'Emergency assistance'
                  : 'Emergency assistance for $cleanOwnerName',
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
