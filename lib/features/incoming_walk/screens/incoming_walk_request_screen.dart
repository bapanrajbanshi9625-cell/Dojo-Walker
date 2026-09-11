import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../../accept_walk/screens/accept_walk_screen.dart';
import '../../accept_walk/services/accept_walk_accept_service.dart';
import '../../insta_walk/models/insta_walk_request.dart';
import '../services/incoming_walk_reject_service.dart';
import '../services/incoming_walk_sound_service.dart';
import '../widgets/incoming_walk_bottom_panel.dart';
import '../widgets/incoming_walk_map.dart';
import '../widgets/incoming_walk_top_bar.dart';

class IncomingWalkRequestScreen extends StatefulWidget {
  const IncomingWalkRequestScreen({
    super.key,
    required this.request,
  });

  final InstaWalkRequest request;

  @override
  State<IncomingWalkRequestScreen> createState() =>
      _IncomingWalkRequestScreenState();
}

class _IncomingWalkRequestScreenState
    extends State<IncomingWalkRequestScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final AcceptWalkAcceptService _acceptService =
      AcceptWalkAcceptService.instance;

  final IncomingWalkRejectService _rejectService =
      IncomingWalkRejectService.instance;

  final IncomingWalkSoundService _soundService =
      IncomingWalkSoundService.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  bool _accepting = false;
  bool _rejecting = false;
  bool _requestUnavailable = false;
  bool _leavingScreen = false;

  double? get _ownerLatitude {
    return widget.request.latitude;
  }

  double? get _ownerLongitude {
    return widget.request.longitude;
  }

  LatLng? get _ownerLocation {
    final double? latitude = _ownerLatitude;
    final double? longitude = _ownerLongitude;

    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  String get _ownerName {
    final String value = widget.request.ownerName.trim();
    return value.isEmpty ? 'Owner' : value;
  }

  String get _ownerPhone {
    return widget.request.ownerPhone.trim();
  }

  String get _dogName {
    final String value = widget.request.dogName.trim();
    return value.isEmpty ? 'Your Pet' : value;
  }

  String get _dogBreed {
    return widget.request.dogBreed.trim();
  }

  String get _address {
    final String pickup =
        widget.request.pickupAddress.trim();

    if (pickup.isNotEmpty) {
      return pickup;
    }

    return widget.request.address.trim();
  }

  String get _requestId {
    return widget.request.requestId.trim();
  }

  @override
  void initState() {
    super.initState();

    _startRequestMonitoring();
    _startRequestSound();
  }

  Future<void> _startRequestSound() async {
    final String requestId = _requestId;

    if (requestId.isEmpty) {
      return;
    }

    try {
      await _soundService.playForRequest(requestId);
    } catch (error) {
      debugPrint(
        'Incoming walk sound error: $error',
      );
    }
  }

  Future<void> _stopRequestSound() async {
    final String requestId = _requestId;

    if (requestId.isEmpty) {
      return;
    }

    try {
      await _soundService.stopRequest(requestId);
    } catch (error) {
      debugPrint(
        'Incoming walk sound stop error: $error',
      );
    }
  }

  void _startRequestMonitoring() {
    final String requestId = _requestId;

    if (requestId.isEmpty) {
      debugPrint(
        'IncomingWalkRequestScreen: request ID is empty.',
      );
      return;
    }

    final DocumentReference<Map<String, dynamic>> requestRef =
        _firestore
            .collection('walk_request')
            .doc(requestId);

    _requestSubscription = requestRef.snapshots().listen(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!mounted || _leavingScreen) {
          return;
        }

        if (!snapshot.exists) {
          _handleRequestUnavailable(
            'This walk request is no longer available.',
          );
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (status == 'searching') {
          return;
        }

        if (status == 'accepted' ||
            status == 'completed' ||
            status == 'complete' ||
            status == 'finished' ||
            status == 'closed' ||
            status == 'cancelled' ||
            status == 'rejected') {
          _handleRequestUnavailable(
            'This walk request is no longer available.',
          );
          return;
        }

        if (status.isNotEmpty) {
          _handleRequestUnavailable(
            'This walk request is no longer available.',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'Incoming walk monitor error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  void _handleRequestUnavailable(
    String message,
  ) {
    if (!mounted ||
        _leavingScreen ||
        _requestUnavailable) {
      return;
    }

    _leavingScreen = true;

    unawaited(
      _stopRequestSound(),
    );

    setState(() {
      _requestUnavailable = true;
    });

    _showMessage(message);

    Future<void>.delayed(
      const Duration(milliseconds: 900),
      () {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _acceptWalk() async {
    if (_accepting ||
        _rejecting ||
        _requestUnavailable ||
        _leavingScreen) {
      return;
    }

    final String requestId = _requestId;

    if (requestId.isEmpty) {
      _showMessage(
        'Walk request ID is missing.',
      );
      return;
    }

    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Walker authentication is unavailable.',
      );
      return;
    }

    setState(() {
      _accepting = true;
    });

    try {
      await _acceptService.acceptWalk(requestId);

      await _stopRequestSound();

      if (!mounted) {
        return;
      }

      _leavingScreen = true;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AcceptWalkScreen(
            request: widget.request,
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Accept walk error: $error',
      );

      if (mounted) {
        _showMessage(
          _cleanException(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _accepting = false;
        });
      }
    }
  }

  Future<void> _rejectWalk() async {
    if (_accepting ||
        _rejecting ||
        _requestUnavailable ||
        _leavingScreen) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Reject Walk?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'You will not be able to accept this request again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text(
                'REJECT',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) {
      return;
    }

    final String requestId = _requestId;

    if (requestId.isEmpty) {
      _showMessage(
        'Walk request ID is missing.',
      );
      return;
    }

    setState(() {
      _rejecting = true;
    });

    try {
      await _rejectService.rejectWalk(requestId);

      await _stopRequestSound();

      if (!mounted) {
        return;
      }

      _leavingScreen = true;

      Navigator.of(context).pop();
    } catch (error) {
      debugPrint(
        'Reject walk error: $error',
      );

      if (mounted) {
        _showMessage(
          _cleanException(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _rejecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? ownerLocation =
        _ownerLocation;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (
        bool didPop,
        void result,
      ) {},
      child: Scaffold(
        backgroundColor:
            const Color(0xFFE9EEF3),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ownerLocation != null
                  ? IncomingWalkMap(
                      walkerLocation: null,
                      ownerLocation: ownerLocation,
                      routePoints: const [],
                    )
                  : ColoredBox(
                      color: DojoWalkerColors.primary
                          .withValues(
                        alpha: 0.04,
                      ),
                    ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const IncomingWalkTopBar(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IncomingWalkBottomPanel(
                dogName: _dogName,
                dogBreed: _dogBreed,
                ownerName: _ownerName,
                ownerPhone: _ownerPhone,
                distanceText: '—',
                etaText:
                    widget.request.durationMinutes > 0
                        ? '${widget.request.durationMinutes} min'
                        : '—',
                paymentText:
                    'After acceptance',
                address: _address,
                onAccept: _acceptWalk,
                onReject: _rejectWalk,
                accepting: _accepting,
                rejecting: _rejecting,
              ),
            ),
            if (_requestUnavailable)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.white70,
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _cleanException(Object error) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
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
          behavior:
              SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _leavingScreen = true;

    unawaited(
      _stopRequestSound(),
    );

    unawaited(
      _requestSubscription?.cancel(),
    );

    super.dispose();
  }
}
