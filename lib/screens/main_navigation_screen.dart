// File:
// lib/screens/main_navigation_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/app_state_service.dart';
import '../features/accept_live_strip/models/accept_live_strip_data.dart';
import '../features/accept_live_strip/widgets/accept_live_strip.dart';
import '../features/accept_walk/screens/accept_walk_screen.dart';
import '../features/insta_walk/models/insta_walk_request.dart';
import '../features/live_walk/screens/live_walk_screen.dart';
import '../features/live_walk/screens/live_walk_start_screen.dart';
import '../features/live_walk/widgets/live_walk_review_bottom_sheet.dart';
import '../features/qr_walk/screens/qr_scanner_screen.dart';
import 'menu_screen.dart';
import 'walker_home_screen.dart';
import 'walker_main_app_bar.dart';
import 'walks_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
  });

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  // ============================================================
  // NAVIGATION
  // ============================================================

  int _currentIndex = 0;

  late final List<Widget> _screens;

  bool _openingReview = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _screens = const <Widget>[
      WalkerHomeScreen(),
      WalksScreen(),
      SizedBox.shrink(),
      MenuScreen(),
    ];

    unawaited(
      AppStateService.instance.refresh(),
    );
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      unawaited(
        AppStateService.instance.refresh(),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ============================================================
  // SELECTED COLOR
  // ============================================================

  Color get _selectedColor {
    switch (_currentIndex) {
      case 0:
        return AppColors.primary;

      case 1:
        return Colors.green;

      case 2:
        return AppColors.primary;

      case 3:
        return Colors.deepPurple;

      default:
        return AppColors.primary;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      // ==========================================================
      // WALKER MAIN APP BAR
      // ==========================================================

      appBar: const WalkerMainAppBar(),

      body: _screens[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AcceptLiveStrip(
            onTap: _openCurrentWalk,
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  //
  // HOME | WALKS | QR SCAN | MENU
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: .10,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              -5,
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: _selectedColor,
            unselectedItemColor: AppColors.textGrey,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            onTap: (int index) async {
              if (index == 2) {
                await _openQrScanner();
                return;
              }

              if (index == _currentIndex) {
                return;
              }

              setState(() {
                _currentIndex = index;
              });
            },
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size: 25,
                  ),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size: 27,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.directions_walk_rounded,
                    size: 25,
                  ),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.directions_walk_rounded,
                    size: 27,
                  ),
                ),
                label: 'Walks',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 25,
                    color: AppColors.textGrey,
                  ),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 27,
                    color: AppColors.primary,
                  ),
                ),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    size: 25,
                  ),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    size: 27,
                  ),
                ),
                label: 'Menu',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OPEN QR SCANNER
  // ============================================================

  Future<void> _openQrScanner() async {
    final dynamic result =
        await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) =>
            const QrScannerScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result is String &&
        result.trim().isNotEmpty) {
      _handleQrResult(result);
      return;
    }

    if (result is Map) {
      _handleQrMapResult(
        Map<String, dynamic>.from(result),
      );
    }
  }

  // ============================================================
  // HANDLE QR RESULT
  // ============================================================

  void _handleQrResult(
    String rawResult,
  ) {
    try {
      final dynamic decoded =
          jsonDecode(rawResult);

      if (decoded is Map) {
        _handleQrMapResult(
          Map<String, dynamic>.from(
            decoded,
          ),
        );

        return;
      }

      _showMessage(
        'QR scanned successfully.',
      );
    } catch (_) {
      _showMessage(
        'QR scanned successfully.',
      );
    }
  }

  // ============================================================
  // HANDLE QR MAP RESULT
  // ============================================================

  void _handleQrMapResult(
    Map<String, dynamic> result,
  ) {
    final String status =
        _readString(
      result['status'],
    ).toUpperCase();

    final String message =
        _readString(
      result['message'],
    );

    if (status == 'ERROR' ||
        status == 'FAILED') {
      _showMessage(
        message.isNotEmpty
            ? message
            : 'Unable to connect QR.',
      );

      return;
    }

    if (message.isNotEmpty) {
      _showMessage(message);
      return;
    }

    _showMessage(
      'Owner connected successfully.',
    );

    unawaited(
      AppStateService.instance.refresh(),
    );
  }

  // ============================================================
  // OPEN CURRENT WALK
  //
  // CANONICAL ID:
  //
  // walk_request/DW000001
  // liveWalkSessions/DW000001
  // walk_history/DW000001
  //
  // NO separate walkId/sessionId.
  // ============================================================

  Future<void> _openCurrentWalk(
    AcceptLiveStripData stripData,
  ) async {
    if (stripData.isHidden) {
      return;
    }

    final String requestId =
        stripData.requestId.trim();

    if (!_isValidRequestId(requestId)) {
      return;
    }

    debugPrint(
      'MainNavigation: opening requestId='
      '$requestId '
      'status=${stripData.status}',
    );

    final AppStateService appState =
        AppStateService.instance;

    // ==========================================================
    // GET REQUEST FROM APP STATE
    // ==========================================================

    Map<String, dynamic>? walkData =
        appState.activeWalkData;

    if (walkData == null ||
        walkData.isEmpty ||
        _requestId(
              walkData,
              requestId,
            ) !=
            requestId) {
      walkData =
          await _getWalkRequest(requestId);
    }

    // ==========================================================
    // READY / LIVE / ACCEPTED SESSION FALLBACK
    // ==========================================================

    if ((walkData == null ||
            walkData.isEmpty) &&
        (stripData.isAccepted ||
            stripData.isReady ||
            stripData.isLive)) {
      walkData =
          await _findLiveSession(requestId);
    }

    // ==========================================================
    // WALK DATA REQUIRED
    // ==========================================================

    if (walkData == null ||
        walkData.isEmpty) {
      if (mounted) {
        _showMessage(
          'Walk information is not available.',
        );
      }

      return;
    }

    // ==========================================================
    // VERIFY REQUEST IS STILL ACTIVE
    // ==========================================================

    final String status =
        _status(walkData['status']);

    if (_isEndedRequest(status) &&
        !stripData.isLive) {
      await appState.refresh();
      return;
    }

    // ==========================================================
    // BUILD REQUEST
    // ==========================================================

    final InstaWalkRequest request =
        _buildRequest(
      requestId,
      walkData,
    );

    if (!request.hasValidRequestId) {
      return;
    }

    // ==========================================================
    // ACCEPTED → ACCEPT WALK / PICKUP SCREEN
    // ==========================================================

    if (stripData.isAccepted) {
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return AcceptWalkScreen(
              request: request,
            );
          },
        ),
      );

      if (mounted) {
        await AppStateService.instance.refresh();
      }

      return;
    }

    // ==========================================================
    // READY → LIVE WALK START SCREEN
    // ==========================================================

    if (stripData.isReady) {
      if (!mounted) {
        return;
      }

      final String ownerUid =
          _firstNonEmpty(
        <dynamic>[
          request.ownerUid,
          request.ownerAuthUid,
          request.ownerId,
          walkData['ownerUid'],
          walkData['ownerAuthUid'],
          walkData['ownerId'],
        ],
      );

      final String ownerName =
          _firstNonEmpty(
        <dynamic>[
          request.ownerName,
          walkData['ownerName'],
          'Owner',
        ],
      );

      final String dogName =
          _firstNonEmpty(
        <dynamic>[
          request.dogName,
          walkData['dogName'],
          walkData['petName'],
          'Dog',
        ],
      );

      final String dogBreed =
          _firstNonEmpty(
        <dynamic>[
          request.dogBreed,
          walkData['dogBreed'],
          walkData['breed'],
        ],
      );

      final String ownerPhone =
          _firstNonEmpty(
        <dynamic>[
          request.ownerPhone,
          walkData['ownerPhone'],
          walkData['ownerMobile'],
          walkData['mobileNumber'],
          walkData['phone'],
        ],
      );

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return LiveWalkStartScreen(
              ownerUid: ownerUid,
              ownerName: ownerName,
              requestId: requestId,
              dogName: dogName,
              dogBreed: dogBreed,
              ownerPhone:
                  ownerPhone.trim().isEmpty
                      ? null
                      : ownerPhone.trim(),
            );
          },
        ),
      );

      if (mounted) {
        await AppStateService.instance.refresh();
      }

      return;
    }

    // ==========================================================
    // ONLY LIVE STATE CAN CONTINUE BELOW
    // ==========================================================

    if (!stripData.isLive) {
      return;
    }

    // ==========================================================
    // LIVE SESSION
    // ==========================================================

    Map<String, dynamic>? sessionData =
        appState.activeSessionData;

    if (sessionData == null ||
        sessionData.isEmpty ||
        _sessionRequestId(
              sessionData,
              requestId,
            ) !=
            requestId) {
      sessionData =
          await _findLiveSession(
        requestId,
      );
    }

    // ==========================================================
    // LIVE SESSION REQUIRED
    // ==========================================================

    if (sessionData == null ||
        sessionData.isEmpty) {
      if (mounted) {
        _showMessage(
          'Live Walk session is not ready yet. Please try again.',
        );
      }

      return;
    }

    // ============================================================
    // OWNER
    // ============================================================

    final String ownerUid =
        _firstNonEmpty(
      <dynamic>[
        request.ownerUid,
        request.ownerAuthUid,
        request.ownerId,
        walkData['ownerUid'],
        walkData['ownerAuthUid'],
        walkData['ownerId'],
        sessionData['ownerUid'],
        sessionData['ownerAuthUid'],
        sessionData['ownerId'],
      ],
    );

    final String ownerName =
        _firstNonEmpty(
      <dynamic>[
        request.ownerName,
        walkData['ownerName'],
        sessionData['ownerName'],
        'Owner',
      ],
    );

    // ============================================================
    // DOG
    // ============================================================

    final String dogName =
        _firstNonEmpty(
      <dynamic>[
        request.dogName,
        walkData['dogName'],
        walkData['petName'],
        sessionData['dogName'],
        sessionData['petName'],
        'Dog',
      ],
    );

    final String dogBreed =
        _firstNonEmpty(
      <dynamic>[
        request.dogBreed,
        walkData['dogBreed'],
        walkData['breed'],
        sessionData['dogBreed'],
        sessionData['breed'],
      ],
    );

    // ============================================================
    // PHONE
    // ============================================================

    final String ownerPhone =
        _firstNonEmpty(
      <dynamic>[
        request.ownerPhone,
        walkData['ownerPhone'],
        walkData['ownerMobile'],
        walkData['mobileNumber'],
        walkData['phone'],
        sessionData['ownerPhone'],
        sessionData['ownerMobile'],
        sessionData['mobileNumber'],
        sessionData['phone'],
      ],
    );

    // ============================================================
    // OPEN LIVE WALK
    // ============================================================

    if (!mounted) {
      return;
    }

    final dynamic result =
        await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) {
          return LiveWalkScreen(
            ownerUid: ownerUid,
            ownerName: ownerName,
            requestId: requestId,
            dogName: dogName,
            dogBreed: dogBreed,
            ownerPhone:
                ownerPhone.trim().isEmpty
                    ? null
                    : ownerPhone.trim(),
          );
        },
      ),
    );

    // ============================================================
    // REFRESH AFTER RETURN
    // ============================================================

    if (!mounted) {
      return;
    }

    await AppStateService.instance.refresh();

    // ============================================================
    // REVIEW AFTER COMPLETED WALK
    // ============================================================

    if (result is Map) {
      final Map<String, dynamic>
          reviewResult =
          Map<String, dynamic>.from(
        result,
      );

      final bool walkCompleted =
          reviewResult['walkCompleted'] ==
              true;

      final bool showReview =
          reviewResult['showReview'] ==
              true;

      if (walkCompleted &&
          showReview) {
        await _openWalkReview(
          reviewResult,
        );
      }
    }
  }

  // ============================================================
  // OPEN WALK REVIEW
  // ============================================================

  Future<void> _openWalkReview(
    Map<String, dynamic> result,
  ) async {
    if (_openingReview ||
        !mounted) {
      return;
    }

    _openingReview = true;

    try {
      if (_currentIndex != 0) {
        setState(() {
          _currentIndex = 0;
        });
      }

      final String walkId =
          _readString(
        result['requestId'] ??
            result['walkId'],
      );

      if (!_isValidRequestId(walkId)) {
        _showMessage(
          'Review could not be opened: Walk ID is missing.',
        );

        return;
      }

      final String ownerUid =
          _readString(
        result['ownerUid'],
      );

      final String dogName =
          _firstNonEmpty(
        <dynamic>[
          result['dogName'],
          'Dog',
        ],
      );

      final double distanceKm =
          _readDouble(
                result['distanceKm'],
              ) ??
              0.0;

      final String duration =
          _readString(
        result['duration'],
      ).isEmpty
            ? '0m'
            : _readString(
                result['duration'],
              );

      final int steps =
          _readInt(
        result['steps'],
      );

      final List<Offset> routePoints =
          _readRoutePoints(
        result['routePoints'],
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 120,
        ),
      );

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor:
            Colors.transparent,
        barrierColor:
            Colors.black54,
        builder: (_) {
          return LiveWalkReviewBottomSheet(
            routePoints:
                routePoints,
            distanceKm:
                distanceKm,
            duration:
                duration,
            steps:
                steps,
            walkId:
                walkId,
            ownerUid:
                ownerUid,
            dogName:
                dogName,
            onBackToHome:
                _returnToHome,
          );
        },
      );

      if (mounted) {
        await AppStateService.instance
            .refresh();
      }
    } finally {
      _openingReview = false;
    }
  }

  // ============================================================
  // RETURN TO HOME
  // ============================================================

  void _returnToHome() {
    if (!mounted) {
      return;
    }

    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    }

    unawaited(
      AppStateService.instance.refresh(),
    );
  }

  // ============================================================
  // READ ROUTE POINTS
  // ============================================================

  List<Offset> _readRoutePoints(
    dynamic raw,
  ) {
    if (raw is! List) {
      return <Offset>[];
    }

    final List<Offset> points =
        <Offset>[];

    for (final dynamic item in raw) {
      if (item is Offset) {
        points.add(item);
        continue;
      }

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

        continue;
      }

      if (item is List &&
          item.length >= 2) {
        final double? latitude =
            _readDouble(item[0]);

        final double? longitude =
            _readDouble(item[1]);

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
  // GET WALK REQUEST
  // ============================================================

  Future<Map<String, dynamic>?> _getWalkRequest(
    String requestId,
  ) async {
    final String id =
        requestId.trim();

    if (!_isValidRequestId(id)) {
      return null;
    }

    try {
      final FirebaseFirestore firestore =
          FirebaseFirestore.instance;

      final DocumentSnapshot<
          Map<String, dynamic>> document =
          await firestore
              .collection('walk_request')
              .doc(id)
              .get();

      if (document.exists) {
        final Map<String, dynamic>? data =
            document.data();

        if (data != null) {
          final String status =
              _status(data['status']);

          if (_isEndedRequest(status)) {
            return null;
          }

          return <String, dynamic>{
            ...data,
            'requestId': id,
          };
        }
      }

      final QuerySnapshot<
          Map<String, dynamic>> querySnapshot =
          await firestore
              .collection('walk_request')
              .where(
                'requestId',
                isEqualTo: id,
              )
              .limit(10)
              .get();

      for (final QueryDocumentSnapshot<
              Map<String, dynamic>>
          queryDocument in querySnapshot.docs) {
        final Map<String, dynamic> data =
            queryDocument.data();

        final String storedRequestId =
            _firstNonEmpty(
          <dynamic>[
            data['requestId'],
            queryDocument.id,
          ],
        );

        if (storedRequestId != id) {
          continue;
        }

        final String status =
            _status(data['status']);

        if (_isEndedRequest(status)) {
          continue;
        }

        return <String, dynamic>{
          ...data,
          'requestId': id,
        };
      }

      debugPrint(
        'MainNavigation: walk request not found '
        'for requestId=$id',
      );

      return null;
    } on FirebaseException catch (error) {
      debugPrint(
        'MainNavigation walk request error: '
        '${error.code} ${error.message}',
      );

      return null;
    } catch (error) {
      debugPrint(
        'MainNavigation walk request error: $error',
      );

      return null;
    }
  }

  // ============================================================
  // FIND LIVE SESSION
  // ============================================================

  Future<Map<String, dynamic>?> _findLiveSession(
    String requestId,
  ) async {
    final String id =
        requestId.trim();

    if (!_isValidRequestId(id)) {
      return null;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> document =
          await FirebaseFirestore.instance
              .collection('liveWalkSessions')
              .doc(id)
              .get();

      if (!document.exists) {
        debugPrint(
          'MainNavigation: live session not found '
          'for requestId=$id',
        );

        return null;
      }

      final Map<String, dynamic>? data =
          document.data();

      if (data == null) {
        return null;
      }

      final String storedRequestId =
          _firstNonEmpty(
        <dynamic>[
          data['requestId'],
          document.id,
        ],
      );

      if (storedRequestId != id) {
        debugPrint(
          'MainNavigation: live session requestId mismatch '
          'expected=$id actual=$storedRequestId',
        );

        return null;
      }

      final String status =
          _status(data['status']);

      if (_isEndedSession(status)) {
        debugPrint(
          'MainNavigation: live session already ended '
          'requestId=$id status=$status',
        );

        return null;
      }

      return <String, dynamic>{
        ...data,
        'requestId': id,
      };
    } on FirebaseException catch (error) {
      debugPrint(
        'MainNavigation live session error: '
        '${error.code} ${error.message}',
      );

      return null;
    } catch (error) {
      debugPrint(
        'MainNavigation live session error: $error',
      );

      return null;
    }
  }

  // ============================================================
  // BUILD REQUEST
  // ============================================================

  InstaWalkRequest _buildRequest(
    String requestId,
    Map<String, dynamic> data,
  ) {
    final String id =
        requestId.trim();

    final GeoPoint? ownerLocation =
        data['ownerLocation'] is GeoPoint
            ? data['ownerLocation'] as GeoPoint
            : null;

    return InstaWalkRequest(
      requestId: id,

      ownerId: _firstNonEmpty(
        <dynamic>[
          data['ownerId'],
          data['ownerID'],
        ],
      ),

      ownerAuthUid: _firstNonEmpty(
        <dynamic>[
          data['ownerAuthUid'],
          data['ownerUid'],
          data['ownerAuthId'],
        ],
      ),

      ownerUid: _firstNonEmpty(
        <dynamic>[
          data['ownerUid'],
          data['ownerAuthUid'],
        ],
      ),

      ownerName: _firstNonEmpty(
        <dynamic>[
          data['ownerName'],
          data['name'],
        ],
      ),

      ownerPhone: _firstNonEmpty(
        <dynamic>[
          data['ownerPhone'],
          data['ownerMobile'],
          data['mobileNumber'],
          data['phone'],
        ],
      ),

      walkerUid: _firstNonEmpty(
        <dynamic>[
          data['walkerUid'],
          data['walkerAuthUid'],
        ],
      ),

      walkerId: _firstNonEmpty(
        <dynamic>[
          data['walkerId'],
          data['walkerID'],
        ],
      ),

      dogName: _firstNonEmpty(
        <dynamic>[
          data['dogName'],
          data['petName'],
        ],
      ),

      dogBreed: _firstNonEmpty(
        <dynamic>[
          data['dogBreed'],
          data['breed'],
        ],
      ),

      dogPhoto: _firstNonEmpty(
        <dynamic>[
          data['dogPhoto'],
          data['dogPhotoUrl'],
          data['dogImage'],
        ],
      ),

      status: _readString(
        data['status'],
      ),

      pickupAddress: _firstNonEmpty(
        <dynamic>[
          data['pickupAddress'],
          data['pickupLocation'],
          data['ownerAddress'],
        ],
      ),

      address: _firstNonEmpty(
        <dynamic>[
          data['address'],
          data['ownerAddress'],
          data['pickupAddress'],
        ],
      ),

      latitude: ownerLocation?.latitude ??
          _readDouble(
            data['latitude'] ??
                data['lat'] ??
                data['pickupLatitude'] ??
                data['pickupLat'] ??
                data['ownerLat'],
          ),

      longitude: ownerLocation?.longitude ??
          _readDouble(
            data['longitude'] ??
                data['lng'] ??
                data['pickupLongitude'] ??
                data['pickupLng'] ??
                data['ownerLng'],
          ),

      distanceKm:
          _readDouble(
                data['distanceKm'],
              ) ??
              0.0,

      durationMinutes:
          _readInt(
        data['durationMinutes'],
      ),

      timeFormatted:
          _readString(
        data['timeFormatted'],
      ),

      date:
          _readString(
        data['date'],
      ),

      createdAt:
          _readTimestamp(
        data['createdAt'],
      ),

      acceptedAt:
          _readTimestamp(
        data['acceptedAt'],
      ),

      startedAt:
          _readTimestamp(
        data['startedAt'],
      ),

      endedAt:
          _readTimestamp(
        data['endedAt'],
      ),

      cancelledAt:
          _readTimestamp(
        data['cancelledAt'],
      ),

      rejectedAt:
          _readTimestamp(
        data['rejectedAt'],
      ),

      updatedAt:
          _readTimestamp(
        data['updatedAt'],
      ),
    );
  }

  // ============================================================
  // REQUEST ID
  // ============================================================

  String _requestId(
    Map<String, dynamic> data,
    String fallback,
  ) {
    return _firstNonEmpty(
      <dynamic>[
        data['requestId'],
        fallback,
      ],
    );
  }

  // ============================================================
  // SESSION REQUEST ID
  // ============================================================

  String _sessionRequestId(
    Map<String, dynamic> data,
    String fallback,
  ) {
    return _firstNonEmpty(
      <dynamic>[
        data['requestId'],
        fallback,
      ],
    );
  }

  // ============================================================
  // VALID REQUEST ID
  // ============================================================

  bool _isValidRequestId(
    String value,
  ) {
    return RegExp(
      r'^DW\d{6}$',
    ).hasMatch(value.trim());
  }

  // ============================================================
  // ACTIVE REQUEST STATUS
  // ============================================================

  bool _isEndedRequest(
    String status,
  ) {
    switch (status) {
      case 'REJECTED':
      case 'DECLINED':
      case 'CANCELLED':
      case 'CANCELED':
      case 'COMPLETED':
      case 'ENDED':
      case 'EXPIRED':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // SESSION END STATUS
  // ============================================================

  bool _isEndedSession(
    String status,
  ) {
    switch (status) {
      case 'COMPLETED':
      case 'ENDED':
      case 'CANCELLED':
      case 'CANCELED':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _status(
    dynamic value,
  ) {
    return _readString(value)
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  // ============================================================
  // STRING
  // ============================================================

  String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // FIRST NON EMPTY
  // ============================================================

  String _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final dynamic value in values) {
      final String text =
          _readString(value);

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
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

  int _readInt(
    dynamic value,
  ) {
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
  // TIMESTAMP
  // ============================================================

  Timestamp? _readTimestamp(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value;
    }

    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }

    return null;
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
          margin:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            90,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }
}
