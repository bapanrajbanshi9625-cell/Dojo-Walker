import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/app_state_service.dart';
import '../features/insta_walk/models/insta_walk_request.dart';
import '../features/insta_walk/screens/active_walk_details_screen.dart';
import '../features/live_walk/screens/live_walk_screen.dart';
import '../widgets/active_walk_strip.dart';
import 'walker_home_screen.dart';
import 'walks_screen.dart';
import 'menu_screen.dart';

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
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WalkerHomeScreen(),
    WalksScreen(),
    MenuScreen(),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: _screens[_currentIndex],

      // ========================================================
      // BOTTOM AREA
      // ========================================================

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ------------------------------------------------------
          // ACTIVE / LIVE WALK STRIP
          // ------------------------------------------------------

          ActiveWalkStrip(
            onTap: _openCurrentWalk,
          ),

          // ------------------------------------------------------
          // NAVIGATION BAR
          // ------------------------------------------------------

          BottomNavigationBar(
            currentIndex: _currentIndex,

            selectedItemColor:
                _selectedColor,

            unselectedItemColor:
                AppColors.textGrey,

            onTap: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },

            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home,
                ),
                label: 'Home',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons
                      .directions_walk_rounded,
                ),
                label: 'Walks',
              ),

              BottomNavigationBarItem(
                icon: Icon(
                  Icons.menu,
                ),
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
  // ============================================================

  void _openCurrentWalk() {
    final AppStateService state =
        AppStateService.instance;

    final Map<String, dynamic>? walkData =
        state.activeWalkData;

    if (walkData == null ||
        walkData.isEmpty) {
      return;
    }

    final InstaWalkRequest request =
        _buildRequest(
      state.activeWalkId ?? '',
      walkData,
    );

    if (request.id.isEmpty) {
      return;
    }

    final String walkStatus =
        _readString(
      walkData['status'],
    ).toLowerCase();

    final Map<String, dynamic>? sessionData =
        state.activeSessionData;

    final String sessionStatus =
        _readString(
      sessionData?['status'],
    ).toLowerCase();

    final bool live =
        sessionStatus == 'live' ||
        sessionStatus == 'started';

    // ==========================================================
    // LIVE WALK
    // ==========================================================

    if (live) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return LiveWalkScreen(
              ownerUid:
                  _firstNonEmpty(
                <String>[
                  request.ownerUid,
                  request.ownerAuthUid,
                  request.ownerId,
                ],
              ),
              ownerName:
                  request.ownerName,
              walkId:
                  request.id,
              dogName:
                  request.dogName,
              dogBreed:
                  request.dogBreed,
              ownerPhone:
                  request.ownerPhone.isEmpty
                      ? null
                      : request.ownerPhone,
              sessionId:
                  request.liveWalkSessionId
                          .isEmpty
                      ? state.activeSessionId
                      : request
                          .liveWalkSessionId,
            );
          },
        ),
      );

      return;
    }

    // ==========================================================
    // ACTIVE WALK
    // ==========================================================

    if (walkStatus == 'accepted' ||
        walkStatus == 'active') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return ActiveWalkDetailsScreen(
              request: request,
            );
          },
        ),
      );

      return;
    }
  }

  // ============================================================
  // BUILD REQUEST FROM APP STATE
  // ============================================================

  InstaWalkRequest _buildRequest(
    String id,
    Map<String, dynamic> data,
  ) {
    return InstaWalkRequest(
      id: id,

      ownerId:
          _readString(
        data['ownerId'],
      ),

      ownerAuthUid:
          _firstNonEmpty(
        <String>[
          data['ownerAuthUid'],
          data['ownerUid'],
        ],
      ),

      ownerUid:
          _readString(
        data['ownerUid'],
      ),

      ownerName:
          _readString(
        data['ownerName'],
      ),

      ownerPhone:
          _firstNonEmpty(
        <String>[
          data['ownerPhone'],
          data['ownerMobile'],
          data['mobileNumber'],
        ],
      ),

      walkerUid:
          _readString(
        data['walkerUid'],
      ),

      walkerId:
          _readString(
        data['walkerId'],
      ),

      dogName:
          _readString(
        data['dogName'],
      ),

      dogBreed:
          _readString(
        data['dogBreed'],
      ),

      dogPhoto:
          _firstNonEmpty(
        <String>[
          data['dogPhoto'],
          data['dogPhotoUrl'],
          data['dogImage'],
        ],
      ),

      status:
          _readString(
        data['status'],
      ),

      pickupAddress:
          _firstNonEmpty(
        <String>[
          data['pickupAddress'],
          data['pickupLocation'],
        ],
      ),

      address:
          _firstNonEmpty(
        <String>[
          data['address'],
          data['ownerAddress'],
        ],
      ),

      latitude:
          _readDouble(
        data['latitude'] ??
            data['lat'] ??
            data['pickupLatitude'],
      ),

      longitude:
          _readDouble(
        data['longitude'] ??
            data['lng'] ??
            data['pickupLongitude'],
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

      activeWalkId:
          _readString(
        data['activeWalkId'],
      ),

      liveWalkSessionId:
          _firstNonEmpty(
        <String>[
          data['liveWalkSessionId'],
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
  // STRING
  // ============================================================

  String _readString(
    dynamic value,
  ) {
    return value
            ?.toString()
            .trim() ??
        '';
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
}
