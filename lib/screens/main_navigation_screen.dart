// File:
// lib/screens/main_navigation_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/active_walk_strip_service.dart';
import '../core/services/app_state_service.dart';
import '../features/insta_walk/models/insta_walk_request.dart';
import '../features/live_walk/screens/live_walk_screen.dart';
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
      MenuScreen(),
    ];

    // Refresh current walk state.
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
      body: _screens[_currentIndex],

      // ========================================================
      // BOTTOM AREA
      // ========================================================

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ActiveWalkStrip(
            onTap: _openCurrentWalk,
          ),

          BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: _selectedColor,
            unselectedItemColor: AppColors.textGrey,
            type: BottomNavigationBarType.fixed,

            onTap: (int index) {
              if (index == _currentIndex) {
                return;
              }

              setState(() {
                _currentIndex = index;
              });
            },

            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.directions_walk_rounded,
                ),
                label: 'Walks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_rounded),
                label: 'Menu',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPEN CURRENT WALK
  //
  // CURRENT FLOW
  //
  // QR WALK:
  //
  // QR Scan
  //    ↓
  // Connection
  //    ↓
  // Active Walk
  //    ↓
  // Reach
  //    ↓
  // Live Walk
  //    ↓
  // Start Walk
  //    ↓
  // Complete Walk
  //
  //
  // INSTA WALK:
  //
  // Search
  //    ↓
  // Request
  //    ↓
  // Accept
  //    ↓
  // Reach Pickup
  //    ↓
  // Live Walk
  //    ↓
  // Start Walk
  //    ↓
  // Complete Walk
  //
  // IMPORTANT:
  // ActiveWalkDetailsScreen is NOT used anymore.
  // ============================================================

  Future<void> _openCurrentWalk(
    ActiveWalkStripState stripState,
  ) async {
    if (!stripState.show ||
        stripState.walkId.trim().isEmpty) {
      debugPrint(
        'MainNavigation: no current walk.',
      );
      return;
    }

    final String walkId =
        stripState.walkId.trim();

    debugPrint(
      'MainNavigation: opening current walk '
      'walkId=$walkId '
      'isLive=${stripState.isLive}',
    );

    final AppStateService appState =
        AppStateService.instance;

    // ==========================================================
    // GET CURRENT WALK DATA FROM APP STATE
    // ==========================================================

    Map<String, dynamic>? walkData =
        appState.activeWalkData;

    // ==========================================================
    // IF APP STATE DOES NOT MATCH STRIP WALK
    // LOOK DIRECTLY IN FIRESTORE
    // ==========================================================

    if (walkData == null ||
        walkData.isEmpty ||
        _readString(walkData['walkId']) != walkId) {
      walkData = await _findActiveWalk(walkId);
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================

    walkData ??= appState.activeWalkData;

    if (walkData == null ||
        walkData.isEmpty) {
      debugPrint(
        'MainNavigation: current walk data not found.',
      );

      if (mounted) {
        _showMessage(
          'Current walk information is unavailable.',
        );
      }

      return;
    }

    // ==========================================================
    // BUILD REQUEST MODEL
    // ==========================================================

    final InstaWalkRequest request =
        _buildRequest(
      walkId,
      walkData,
    );

    if (request.id.isEmpty) {
      debugPrint(
        'MainNavigation: request id is empty.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    // ==========================================================
    // ALWAYS OPEN LIVE WALK FOR CURRENT ACTIVE/LIVE WALK
    //
    // There is no ActiveWalkDetailsScreen now.
    //
    // The LiveWalkScreen itself handles:
    //
    // Before Start:
    //     Reach / Start Walk state
    //
    // After Start:
    //     Live map
    //
    // Bottom:
    //     Slide to Complete Walk
    // ==========================================================

    final Map<String, dynamic>? sessionData =
        appState.activeSessionData;

    final String sessionId =
        _firstNonEmpty(
      <dynamic>[
        request.liveWalkSessionId,
        appState.activeSessionId,
        _readString(
          sessionData?['sessionId'],
        ),
        'session-$walkId',
      ],
    );

    // ==========================================================
    // OWNER UID
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

    // ==========================================================
    // OWNER NAME
    // ==========================================================

    final String ownerName =
        request.ownerName.isEmpty
            ? _firstNonEmpty(
                <dynamic>[
                  walkData['ownerName'],
                  'Owner',
                ],
              )
            : request.ownerName;

    // ==========================================================
    // DOG NAME
    // ==========================================================

    final String dogName =
        request.dogName.isEmpty
            ? _firstNonEmpty(
                <dynamic>[
                  walkData['dogName'],
                  walkData['petName'],
                  'Dog',
                ],
              )
            : request.dogName;

    // ==========================================================
    // DOG BREED
    // ==========================================================

    final String dogBreed =
        request.dogBreed.isEmpty
            ? _firstNonEmpty(
                <dynamic>[
                  walkData['dogBreed'],
                  walkData['breed'],
                ],
              )
            : request.dogBreed;

    // ==========================================================
    // OWNER PHONE
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
    // OPEN LIVE WALK
    // ==========================================================

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
                ownerPhone.isEmpty
                    ? null
                    : ownerPhone,
            sessionId:
                sessionId.isEmpty
                    ? null
                    : sessionId,
          );
        },
      ),
    );

    // ==========================================================
    // REFRESH AFTER RETURNING
    // ==========================================================

    if (mounted) {
      await AppStateService.instance.refresh();
    }
  }

  // ============================================================
  // FIND ACTIVE WALK
  // ============================================================

  Future<Map<String, dynamic>?> _findActiveWalk(
    String walkId,
  ) async {
    final String id = walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    try {
      // ========================================================
      // FIRST:
      // active_walks where walkId == current walk
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await FirebaseFirestore.instance
              .collection('active_walks')
              .where(
                'walkId',
                isEqualTo: id,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }

      // ========================================================
      // FALLBACK:
      // active_walks document ID == walkId
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          direct =
          await FirebaseFirestore.instance
              .collection('active_walks')
              .doc(id)
              .get();

      if (direct.exists) {
        return direct.data();
      }

      return null;
    } on FirebaseException catch (error) {
      debugPrint(
        'MainNavigation active walk lookup error: '
        '${error.code} ${error.message}',
      );

      return null;
    } catch (error) {
      debugPrint(
        'MainNavigation active walk lookup error: $error',
      );

      return null;
    }
  }

  // ============================================================
  // BUILD INSTA WALK REQUEST
  // ============================================================

  InstaWalkRequest _buildRequest(
    String id,
    Map<String, dynamic> data,
  ) {
    final String walkId =
        id.trim();

    return InstaWalkRequest(
      id: walkId,

      // --------------------------------------------------------
      // OWNER
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // WALKER
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // DOG
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      status: _readString(
        data['status'],
      ),

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // DISTANCE
      // --------------------------------------------------------

      distanceKm:
          _readDouble(
                data['distanceKm'],
              ) ??
              0.0,

      // --------------------------------------------------------
      // DURATION
      // --------------------------------------------------------

      durationMinutes: _readInt(
        data['durationMinutes'],
      ),

      timeFormatted: _readString(
        data['timeFormatted'],
      ),

      date: _readString(
        data['date'],
      ),

      // --------------------------------------------------------
      // ACTIVE WALK
      // --------------------------------------------------------

      activeWalkId: _firstNonEmpty(
        <dynamic>[
          data['activeWalkId'],
          data['walkId'],
        ],
      ),

      // --------------------------------------------------------
      // LIVE SESSION
      // --------------------------------------------------------

      liveWalkSessionId: _firstNonEmpty(
        <dynamic>[
          data['liveWalkSessionId'],
          data['sessionId'],
          AppStateService
              .instance
              .activeSessionId,
        ],
      ),

      // --------------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------------

      createdAt: _readTimestamp(
        data['createdAt'],
      ),

      acceptedAt: _readTimestamp(
        data['acceptedAt'],
      ),

      startedAt: _readTimestamp(
        data['startedAt'],
      ),

      endedAt: _readTimestamp(
        data['endedAt'],
      ),

      cancelledAt: _readTimestamp(
        data['cancelledAt'],
      ),

      rejectedAt: _readTimestamp(
        data['rejectedAt'],
      ),

      updatedAt: _readTimestamp(
        data['updatedAt'],
      ),
    );
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
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
