// File:
// lib/features/insta_walk/screens/incoming_walk_request_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/insta_walk_request.dart';
import '../services/insta_walk_accept_service.dart';
import '../services/insta_walk_reject_service.dart';
import '../../live_walk/screens/live_walk_screen.dart';

class IncomingWalkRequestScreen extends StatefulWidget {
  final InstaWalkRequest request;

  const IncomingWalkRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<IncomingWalkRequestScreen> createState() =>
      _IncomingWalkRequestScreenState();
}

class _IncomingWalkRequestScreenState
    extends State<IncomingWalkRequestScreen> {
  final MapController _mapController = MapController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final InstaWalkAcceptService _acceptService =
      InstaWalkAcceptService.instance;

  final InstaWalkRejectService _rejectService =
      InstaWalkRejectService.instance;

  StreamSubscription<Position>? _locationSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  Position? _walkerPosition;

  bool _loadingLocation = true;
  bool _accepting = false;
  bool _rejecting = false;
  bool _accepted = false;
  bool _reaching = false;
  bool _requestUnavailable = false;
  bool _leavingScreen = false;

  double _distanceMeters = 0;

  // ============================================================
  // REQUEST DATA
  // ============================================================

  double? get _ownerLatitude => widget.request.latitude;

  double? get _ownerLongitude => widget.request.longitude;

  String get _ownerUid {
    final String authUid =
        widget.request.ownerAuthUid.trim();

    if (authUid.isNotEmpty) {
      return authUid;
    }

    final String uid =
        widget.request.ownerUid.trim();

    if (uid.isNotEmpty) {
      return uid;
    }

    return widget.request.ownerId.trim();
  }

  String get _ownerName {
    final String value =
        widget.request.ownerName.trim();

    return value.isEmpty ? 'Owner' : value;
  }

  String get _ownerPhone {
    return widget.request.ownerPhone.trim();
  }

  String get _dogName {
    final String value =
        widget.request.dogName.trim();

    return value.isEmpty ? 'Dog' : value;
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

  String get _sessionId {
    return widget.request.liveWalkSessionId.trim();
  }

  String get _walkId {
    return widget.request.id.trim();
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  String get _paymentText {
    return 'After acceptance';
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _accepted =
        widget.request.status.trim().toLowerCase() ==
            'accepted';

    unawaited(_startLocationTracking());
    _startRequestMonitoring();
  }

  // ============================================================
  // REALTIME REQUEST MONITOR
  // ============================================================

  void _startRequestMonitoring() {
    if (_walkId.isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> walkRef =
        _firestore
            .collection('walk_request')
            .doc(_walkId);

    _requestSubscription = walkRef.snapshots().listen(
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
            data['status']?.toString().trim().toLowerCase() ??
                '';

        final String currentWalkerUid =
            data['walkerUid']?.toString().trim() ?? '';

        final String currentWalkerId =
            data['walkerId']?.toString().trim() ?? '';

        // --------------------------------------------------------
        // CURRENT WALKER ACCEPTED
        // --------------------------------------------------------

        if (status == 'accepted' &&
            _isCurrentWalker(
              currentWalkerUid,
              currentWalkerId,
            )) {
          if (!_accepted) {
            setState(() {
              _accepted = true;
            });
          }

          return;
        }

        // --------------------------------------------------------
        // REQUEST STILL SEARCHING
        // --------------------------------------------------------

        if (status == 'searching') {
          return;
        }

        // --------------------------------------------------------
        // SOMEONE ELSE ACCEPTED / REQUEST UNAVAILABLE
        // --------------------------------------------------------

        if (!_accepted) {
          _handleRequestUnavailable(
            'This walk has already been accepted by another Walker.',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'Incoming request monitor error: $error',
        );
      },
    );
  }

  // ============================================================
  // CURRENT WALKER CHECK
  // ============================================================

  bool _isCurrentWalker(
    String walkerUid,
    String walkerId,
  ) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final String currentAuthUid =
        user.uid.trim();

    final String cleanWalkerUid =
        walkerUid.trim();

    // UID match
    if (cleanWalkerUid.isNotEmpty &&
        currentAuthUid.isNotEmpty &&
        cleanWalkerUid == currentAuthUid) {
      return true;
    }

    // Walker ID match is intentionally not used here
    // because it would require an asynchronous Firestore
    // lookup inside the snapshot listener.
    //
    // The accept service already verifies the Walker ID
    // during acceptance.

    return false;
  }

  // ============================================================
  // REQUEST UNAVAILABLE
  // ============================================================

  void _handleRequestUnavailable(
    String message,
  ) {
    if (!mounted ||
        _leavingScreen ||
        _accepted) {
      return;
    }

    _leavingScreen = true;

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

        Navigator.pop(context);
      },
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _startLocationTracking() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          _showMessage(
            'Please turn on Location/GPS.',
          );
        }
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showMessage(
            'Location permission is required.',
          );
        }
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) {
        return;
      }

      _updateWalkerLocation(position);

      _locationSubscription =
          Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        _updateWalkerLocation,
        onError: (Object error) {
          debugPrint(
            'Incoming walk location error: $error',
          );
        },
      );
    } catch (error) {
      debugPrint(
        'Incoming request location error: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to get your location.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  void _updateWalkerLocation(
    Position position,
  ) {
    final double? ownerLat =
        _ownerLatitude;

    final double? ownerLng =
        _ownerLongitude;

    double distance = 0;

    if (ownerLat != null &&
        ownerLng != null) {
      distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        ownerLat,
        ownerLng,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _walkerPosition = position;
      _distanceMeters = distance;
    });

    _fitBothLocations();
  }

  // ============================================================
  // FIT MAP
  // ============================================================

  void _fitBothLocations() {
    final Position? walker =
        _walkerPosition;

    final double? ownerLat =
        _ownerLatitude;

    final double? ownerLng =
        _ownerLongitude;

    if (walker == null ||
        ownerLat == null ||
        ownerLng == null) {
      return;
    }

    try {
      final LatLng walkerPoint =
          LatLng(
        walker.latitude,
        walker.longitude,
      );

      final LatLng ownerPoint =
          LatLng(
        ownerLat,
        ownerLng,
      );

      final LatLngBounds bounds =
          LatLngBounds.fromPoints(
        <LatLng>[
          walkerPoint,
          ownerPoint,
        ],
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(
            45,
            120,
            45,
            360,
          ),
          maxZoom: 16,
        ),
      );
    } catch (_) {
      // Map may not be ready yet.
    }
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<void> _acceptWalk() async {
    if (_accepting ||
        _rejecting ||
        _accepted ||
        _requestUnavailable) {
      return;
    }

    if (_walkId.isEmpty) {
      _showMessage(
        'Walk request ID is missing.',
      );
      return;
    }

    setState(() {
      _accepting = true;
    });

    try {
      await _acceptService.acceptWalk(
        _walkId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _accepted = true;
      });

      _showMessage(
        'Walk accepted. Please reach the owner.',
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

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _rejectWalk() async {
    if (_accepting ||
        _rejecting ||
        _accepted ||
        _requestUnavailable) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Reject Walk?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'You will not be able to accept this walk again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'CANCEL',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'REJECT',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true ||
        !mounted) {
      return;
    }

    if (_walkId.isEmpty) {
      _showMessage(
        'Walk request ID is missing.',
      );
      return;
    }

    setState(() {
      _rejecting = true;
    });

    try {
      await _rejectService.rejectWalk(
        _walkId,
      );

      if (!mounted) {
        return;
      }

      _leavingScreen = true;

      Navigator.pop(context);
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

  // ============================================================
  // REACH OWNER
  // ============================================================

  Future<void> _onReachOwner() async {
    if (!_accepted ||
        _reaching ||
        _requestUnavailable) {
      return;
    }

    if (_ownerLatitude == null ||
        _ownerLongitude == null) {
      _showMessage(
        'Owner location is unavailable.',
      );
      return;
    }

    if (_distanceMeters > 100) {
      _showMessage(
        'Please reach within 100 m of the owner.',
      );
      return;
    }

    if (_walkId.isEmpty) {
      _showMessage(
        'Walk ID is missing.',
      );
      return;
    }

    final String sessionId =
        _sessionId;

    if (sessionId.isEmpty) {
      _showMessage(
        'Live Walk session is not ready yet.',
      );
      return;
    }

    setState(() {
      _reaching = true;
    });

    try {
      _leavingScreen = true;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (
            BuildContext context,
          ) {
            return LiveWalkScreen(
              ownerUid: _ownerUid,
              ownerName: _ownerName,
              walkId: _walkId,
              dogName: _dogName,
              dogBreed: _dogBreed,
              ownerPhone:
                  _ownerPhone.isEmpty
                      ? null
                      : _ownerPhone,
              sessionId: sessionId,
            );
          },
        ),
      );
    } catch (error) {
      _leavingScreen = false;

      debugPrint(
        'Open Live Walk error: $error',
      );

      if (mounted) {
        _showMessage(
          _cleanException(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _reaching = false;
        });
      }
    }
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    final double? ownerLat =
        _ownerLatitude;

    final double? ownerLng =
        _ownerLongitude;

    final List<Marker> markers =
        <Marker>[];

    // WALKER
    if (_walkerPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _walkerPosition!.latitude,
            _walkerPosition!.longitude,
          ),
          width: 58,
          height: 58,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow:
                  const <BoxShadow>[
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      );
    }

    // OWNER
    if (ownerLat != null &&
        ownerLng != null) {
      markers.add(
        Marker(
          point: LatLng(
            ownerLat,
            ownerLng,
          ),
          width: 62,
          height: 72,
          child: Column(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration:
                    const BoxDecoration(
                  color: Color(0xFFF4511E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final LatLng center =
        ownerLat != null &&
                ownerLng != null
            ? LatLng(
                ownerLat,
                ownerLng,
              )
            : _walkerPosition != null
                ? LatLng(
                    _walkerPosition!.latitude,
                    _walkerPosition!.longitude,
                  )
                : const LatLng(
                    20.5937,
                    78.9629,
                  );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions:
            const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),
        MarkerLayer(
          markers: markers,
        ),
        if (_walkerPosition != null &&
            ownerLat != null &&
            ownerLng != null)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: <LatLng>[
                  LatLng(
                    _walkerPosition!.latitude,
                    _walkerPosition!.longitude,
                  ),
                  LatLng(
                    ownerLat,
                    ownerLng,
                  ),
                ],
                strokeWidth: 4,
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          12,
          14,
          0,
        ),
        child: Row(
          children: <Widget>[
            _circleButton(
              Icons.arrow_back_rounded,
              () {
                if (!_leavingScreen) {
                  Navigator.pop(context);
                }
              },
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),
                boxShadow:
                    const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    _accepted
                        ? Icons.check_circle_rounded
                        : Icons.notifications_active_rounded,
                    color: _accepted
                        ? Colors.green
                        : const Color(0xFFF4511E),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _accepted
                        ? 'WALK ACCEPTED'
                        : 'INCOMING WALK',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder:
            const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            icon,
            size: 23,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            14,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow:
                <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 4,
                decoration:
                    BoxDecoration(
                  color: Colors.black12,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              Row(
                children: <Widget>[
                  Container(
                    width: 58,
                    height: 58,
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFFFE7DE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color:
                          Color(0xFFF4511E),
                      size: 30,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: <Widget>[
                        Text(
                          _dogName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          _dogBreed.isEmpty
                              ? _ownerName
                              : '$_dogBreed • $_ownerName',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                Colors.black54,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              Row(
                children: <Widget>[
                  Expanded(
                    child: _infoBox(
                      Icons.location_on_rounded,
                      _distanceText,
                      'from you',
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: _infoBox(
                      Icons.schedule_rounded,
                      _etaText,
                      'arrival',
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: _infoBox(
                      Icons.payments_rounded,
                      _paymentText,
                      'payment',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              if (_address.isNotEmpty)
                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF7F7F7,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons
                            .location_on_rounded,
                        color:
                            Color(0xFFF4511E),
                        size: 21,
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                      Expanded(
                        child: Text(
                          _address,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 12,
              ),

              if (_accepted)
                SizedBox(
                  width:
                      double.infinity,
                  height: 56,
                  child:
                      ElevatedButton(
                    onPressed:
                        _canReachOwner &&
                                !_reaching
                            ? _onReachOwner
                            : null,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFF4511E,
                      ),
                      disabledBackgroundColor:
                          Colors.black12,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),
                    ),
                    child: _reaching
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _canReachOwner
                                ? 'REACHED OWNER'
                                : 'REACH OWNER',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  15,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                  ),
                )
              else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child:
                            OutlinedButton(
                          onPressed:
                              _rejecting ||
                                      _accepting
                                  ? null
                                  : _rejectWalk,
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                Colors.red,
                            side:
                                const BorderSide(
                              color:
                                  Colors.red,
                              width: 1.4,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),
                          ),
                          child: _rejecting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Text(
                                  'REJECT',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child:
                            ElevatedButton(
                          onPressed:
                              _accepting ||
                                      _rejecting
                                  ? null
                                  : _acceptWalk,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFFF4511E,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),
                          ),
                          child: _accepting
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                      Colors
                                          .white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'ACCEPT WALK',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .white,
                                    fontSize:
                                        15,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(
                height: 7,
              ),

              Text(
                _accepted
                    ? (_canReachOwner
                        ? 'You are within 100 m of the owner.'
                        : 'Reach the owner to open Live Walk.')
                    : 'Review the location before accepting this walk.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 11,
                  color:
                      Colors.black45,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO BOX
  // ============================================================

  Widget _infoBox(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF7F7F7),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color:
                const Color(0xFFF4511E),
            size: 19,
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            label,
            style:
                const TextStyle(
              fontSize: 9,
              color:
                  Colors.black45,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  String get _distanceText {
    if (_walkerPosition == null ||
        _ownerLatitude == null ||
        _ownerLongitude == null) {
      return '—';
    }

    if (_distanceMeters < 1000) {
      return '${_distanceMeters.round()} m';
    }

    return '${(_distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  // ============================================================
  // ETA
  // ============================================================

  String get _etaText {
    if (widget.request.durationMinutes > 0) {
      return '${widget.request.durationMinutes} min';
    }

    if (_distanceMeters <= 0) {
      return '—';
    }

    const double walkingSpeedKmH = 5;

    final double minutes =
        (_distanceMeters / 1000) /
            walkingSpeedKmH *
            60;

    final int rounded =
        math.max(
      1,
      minutes.ceil(),
    );

    return '$rounded min';
  }

  // ============================================================
  // REACHED
  // ============================================================

  bool get _canReachOwner {
    return _accepted &&
        !_requestUnavailable &&
        _ownerLatitude != null &&
        _ownerLongitude != null &&
        _distanceMeters <= 100;
  }

  // ============================================================
  // ERROR CLEANER
  // ============================================================

  String _cleanException(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
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
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _buildMap(),
          ),

          _buildTopBar(),

          _buildBottomSheet(),

          if (_loadingLocation)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white70,
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
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
    );
  }
}
