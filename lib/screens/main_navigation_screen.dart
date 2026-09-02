// File:
// lib/screens/main_navigation_screen.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/app_state_service.dart';
import '../features/insta_walk/models/insta_walk_request.dart';
import '../features/live_walk/screens/live_walk_screen.dart';
import '../features/qr_walk/screens/qr_scanner_screen.dart';
import '../widgets/active_walk_strip.dart';
import 'menu_screen.dart';
import 'walker_home_screen.dart';
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
      // QR does not need a permanent screen.
      // Index 2 is handled by _openQrScanner().
      SizedBox.shrink(),
      MenuScreen(),
    ];

    AppStateService.instance.refresh();
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
      AppStateService.instance.refresh();
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

      body: _screens[_currentIndex],

      // ==========================================================
      // BOTTOM AREA
      // ==========================================================

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ------------------------------------------------------
          // ACTIVE WALK
          // ------------------------------------------------------

          ActiveWalkStrip(
            onTap: _openCurrentWalk,
          ),

          // ------------------------------------------------------
          // NAVIGATION BAR
          // ------------------------------------------------------

          _buildBottomNavigation(),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  //
  // 4 EQUAL ITEMS:
  //
  // HOME | WALKS | QR SCAN | MENU
  //
  // QR IS NOT FLOATING.
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

            unselectedItemColor:
                AppColors.textGrey,

            backgroundColor:
                Colors.transparent,

            elevation: 0,

            type:
                BottomNavigationBarType.fixed,

            selectedFontSize: 11,

            unselectedFontSize: 10,

            selectedLabelStyle:
                const TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),

            unselectedLabelStyle:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),

            onTap: (int index) async {
              // ==================================================
              // QR TAB
              // ==================================================

              if (index == 2) {
                await _openQrScanner();
                return;
              }

              // ==================================================
              // SAME TAB
              // ==================================================

              if (index == _currentIndex) {
                return;
              }

              // ==================================================
              // NORMAL NAVIGATION
              // ==================================================

              setState(() {
                _currentIndex = index;
              });
            },

            items: <BottomNavigationBarItem>[
              // ==================================================
              // HOME
              // ==================================================

              const BottomNavigationBarItem(
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

              // ==================================================
              // WALKS
              // ==================================================

              const BottomNavigationBarItem(
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

              // ==================================================
              // QR SCAN
              //
              // SAME SIZE AS OTHER ITEMS
              // NOT FLOATING
              // ==================================================

              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 25,
                    color:
                        AppColors.textGrey,
                  ),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 27,
                    color:
                        AppColors.primary,
                  ),
                ),
                label: 'Scan',
              ),

              // ==================================================
              // MENU
              // ==================================================

              const BottomNavigationBarItem(
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

    // ----------------------------------------------------------
    // QR SCANNER RETURNS JSON STRING
    // ----------------------------------------------------------

    if (result is String &&
        result.trim().isNotEmpty) {
      _handleQrResult(result);
      return;
    }

    // ----------------------------------------------------------
    // ALSO SUPPORT MAP RESULT
    // ----------------------------------------------------------

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

    // Refresh app state because QR service
    // may have created a live session.
    AppStateService.instance.refresh();
  }

  // ============================================================
  // OPEN CURRENT WALK
  //
  // ONLY:
  //
  // walk_request
  // liveWalkSessions
  //
  // NO active_walk / active_walks.
  // ============================================================

  Future<void> _openCurrentWalk(
    ActiveWalkStripState stripState,
  ) async {
    if (!stripState.show) {
      return;
    }

    final String walkId =
        stripState.walkId.trim();

    if (walkId.isEmpty) {
      return;
    }

    debugPrint(
      'MainNavigation: opening walk '
      'walkId=$walkId '
      'isLive=${stripState.isLive}',
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
              walkId,
            ) !=
            walkId) {
      walkData =
          await _getWalkRequest(walkId);
    }

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

    if (_isEndedRequest(status)) {
      await appState.refresh();
      return;
    }

    // ==========================================================
    // BUILD REQUEST
    // ==========================================================

    final InstaWalkRequest request =
        _buildRequest(
      walkId,
      walkData,
    );

    if (request.id.isEmpty) {
      return;
    }

    // ==========================================================
    // SESSION
    // ==========================================================

    Map<String, dynamic>? sessionData =
        appState.activeSessionData;

    String sessionId =
        _firstNonEmpty(
      <dynamic>[
        request.liveWalkSessionId,
        appState.activeSessionId,
        sessionData?['sessionId'],
      ],
    );

    // ==========================================================
    // FIND LIVE SESSION
    // ==========================================================

    if (sessionId.isEmpty) {
      sessionData =
          await _findLiveSession(
        walkId,
      );

      if (sessionData != null) {
        sessionId =
            _firstNonEmpty(
          <dynamic>[
            sessionData['sessionId'],
            sessionData['liveWalkSessionId'],
          ],
        );
      }
    }

    // ==========================================================
    // OWNER
    // ==========================================================

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

    // ==========================================================
    // DOG
    // ==========================================================

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

    // ==========================================================
    // PHONE
    // ==========================================================

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

    // ==========================================================
    // SESSION REQUIRED
    // ==========================================================

    if (sessionId.isEmpty) {
      if (mounted) {
        _showMessage(
          'Live Walk session is not ready yet. Please try again.',
        );
      }

      return;
    }

    // ==========================================================
    // OPEN LIVE WALK
    // ==========================================================

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return LiveWalkScreen(
            ownerUid: ownerUid,
            ownerName: ownerName,
            walkId: request.id,
            dogName: dogName,
            dogBreed: dogBreed,
            ownerPhone:
                ownerPhone.trim().isEmpty
                    ? null
                    : ownerPhone.trim(),
            sessionId: sessionId,
          );
        },
      ),
    );

    // ==========================================================
    // REFRESH AFTER RETURN
    // ==========================================================

    if (mounted) {
      await AppStateService.instance
          .refresh();
    }
  }

  // ============================================================
  // GET WALK REQUEST
  // ============================================================

  Future<Map<String, dynamic>?> _getWalkRequest(
    String walkId,
  ) async {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> document =
          await FirebaseFirestore.instance
              .collection('walk_request')
              .doc(id)
              .get();

      if (!document.exists) {
        return null;
      }

      final Map<String, dynamic>? data =
          document.data();

      if (data == null) {
        return null;
      }

      final String status =
          _status(data['status']);

      if (_isEndedRequest(status)) {
        return null;
      }

      return <String, dynamic>{
        ...data,
        'walkId': _firstNonEmpty(
          <dynamic>[
            data['walkId'],
            id,
          ],
        ),
      };
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
    String walkId,
  ) async {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('liveWalkSessions')
              .where(
                'walkId',
                isEqualTo: id,
              )
              .limit(10)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      for (final QueryDocumentSnapshot<
          Map<String, dynamic>> document
          in snapshot.docs) {
        final Map<String, dynamic> data =
            document.data();

        final String status =
            _status(data['status']);

        if (_isEndedSession(status)) {
          continue;
        }

        return <String, dynamic>{
          ...data,
          'sessionId': _firstNonEmpty(
            <dynamic>[
              data['sessionId'],
              data['liveWalkSessionId'],
              document.id,
            ],
          ),
        };
      }

      return null;
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
    String id,
    Map<String, dynamic> data,
  ) {
    final String walkId =
        id.trim();

    return InstaWalkRequest(
      id: walkId,

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

      latitude: _readDouble(
        data['latitude'] ??
            data['lat'] ??
            data['pickupLatitude'] ??
            data['pickupLat'] ??
            data['ownerLat'],
      ),

      longitude: _readDouble(
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

      date: _readString(
        data['date'],
      ),

      activeWalkId:
          _firstNonEmpty(
        <dynamic>[
          data['activeWalkId'],
          data['walkId'],
        ],
      ),

      liveWalkSessionId:
          _firstNonEmpty(
        <dynamic>[
          data['liveWalkSessionId'],
          data['sessionId'],
          AppStateService
              .instance
              .activeSessionId,
        ],
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
        data['walkId'],
        data['requestId'],
        fallback,
      ],
    );
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
