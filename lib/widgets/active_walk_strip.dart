import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ActiveWalkStrip extends StatefulWidget {
  const ActiveWalkStrip({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<ActiveWalkStrip> createState() =>
      _ActiveWalkStripState();
}

class _ActiveWalkStripState
    extends State<ActiveWalkStrip> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _activeWalkSubscription;

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _liveSessionSubscription;

  // ============================================================
  // STATE
  // ============================================================

  bool _activeWalkFound = false;
  bool _liveSessionFound = false;

  String _activeWalkId = '';
  String _sessionWalkId = '';

  @override
  void initState() {
    super.initState();

    _listenToActiveWalks();
    _listenToLiveSessions();
  }

  // ============================================================
  // CURRENT WALKER UID
  // ============================================================

  String get _walkerUid {
    return _auth.currentUser?.uid.trim() ?? '';
  }

  // ============================================================
  // ACTIVE WALKS
  //
  // Collection:
  // active_walks
  //
  // Required field:
  // walkerUid
  //
  // Status:
  // ACCEPTED
  // ACTIVE
  // ON_THE_WAY
  // ============================================================

  void _listenToActiveWalks() {
    final String uid = _walkerUid;

    if (uid.isEmpty) {
      debugPrint(
        'ActiveWalkStrip: Walker UID is empty.',
      );
      return;
    }

    _activeWalkSubscription = _firestore
        .collection('active_walks')
        .where(
          'walkerUid',
          isEqualTo: uid,
        )
        .snapshots()
        .listen(
      _handleActiveWalks,
      onError: (Object error) {
        debugPrint(
          'ActiveWalkStrip active_walks error: $error',
        );
      },
    );
  }

  // ============================================================
  // LIVE WALK SESSIONS
  //
  // Collection:
  // liveWalkSessions
  //
  // Required field:
  // walkerUid
  //
  // Status:
  // ACTIVE
  // STARTED
  // LIVE
  // ============================================================

  void _listenToLiveSessions() {
    final String uid = _walkerUid;

    if (uid.isEmpty) {
      debugPrint(
        'ActiveWalkStrip: Walker UID is empty.',
      );
      return;
    }

    _liveSessionSubscription = _firestore
        .collection('liveWalkSessions')
        .where(
          'walkerUid',
          isEqualTo: uid,
        )
        .snapshots()
        .listen(
      _handleLiveSessions,
      onError: (Object error) {
        debugPrint(
          'ActiveWalkStrip liveWalkSessions error: $error',
        );
      },
    );
  }

  // ============================================================
  // ACTIVE WALK DATA
  // ============================================================

  void _handleActiveWalks(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    bool found = false;
    String foundWalkId = '';

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc in snapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      final String status =
          _status(data['status']);

      final String walkId =
          _string(data['walkId']);

      // --------------------------------------------------------
      // ACTIVE WALK STATUSES
      // --------------------------------------------------------

      final bool isActive =
          status == 'ACCEPTED' ||
          status == 'ACTIVE' ||
          status == 'ON_THE_WAY';

      // --------------------------------------------------------
      // ENDED STATUSES
      // --------------------------------------------------------

      final bool isEnded =
          status == 'COMPLETED' ||
          status == 'ENDED' ||
          status == 'CANCELLED';

      // --------------------------------------------------------
      // ONLY CURRENT ACTIVE WALK
      // --------------------------------------------------------

      if (isActive && !isEnded) {
        found = true;

        foundWalkId =
            walkId.isNotEmpty
                ? walkId
                : doc.id;

        break;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _activeWalkFound = found;
      _activeWalkId = foundWalkId;
    });

    debugPrint(
      'ActiveWalkStrip: '
      'activeWalkFound=$_activeWalkFound '
      'activeWalkId=$_activeWalkId',
    );
  }

  // ============================================================
  // LIVE SESSION DATA
  // ============================================================

  void _handleLiveSessions(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    bool found = false;
    String foundWalkId = '';

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc in snapshot.docs) {
      final Map<String, dynamic> data =
          doc.data();

      final String status =
          _status(data['status']);

      final String walkId =
          _string(data['walkId']);

      // --------------------------------------------------------
      // LIVE SESSION ENDED?
      // --------------------------------------------------------

      final bool isCompleted =
          status == 'COMPLETED' ||
          status == 'ENDED' ||
          status == 'CANCELLED';

      if (isCompleted) {
        continue;
      }

      // --------------------------------------------------------
      // CURRENT LIVE SESSION
      // --------------------------------------------------------

      final bool isLive =
          status == 'ACTIVE' ||
          status == 'STARTED' ||
          status == 'LIVE';

      if (isLive) {
        found = true;

        foundWalkId =
            walkId.isNotEmpty
                ? walkId
                : doc.id;

        break;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _liveSessionFound = found;
      _sessionWalkId = foundWalkId;
    });

    debugPrint(
      'ActiveWalkStrip: '
      'liveSessionFound=$_liveSessionFound '
      'sessionWalkId=$_sessionWalkId',
    );
  }

  // ============================================================
  // SHOULD SHOW STRIP
  // ============================================================

  bool get _shouldShow {
    // ----------------------------------------------------------
    // LIVE SESSION ACTIVE
    // Highest priority
    // ----------------------------------------------------------

    if (_liveSessionFound) {
      return true;
    }

    // ----------------------------------------------------------
    // ACTIVE WALK
    // ----------------------------------------------------------

    if (_activeWalkFound) {
      return true;
    }

    // ----------------------------------------------------------
    // NOTHING ACTIVE
    // ----------------------------------------------------------

    return false;
  }

  // ============================================================
  // IS LIVE?
  // ============================================================

  bool get _isLive {
    return _liveSessionFound;
  }

  // ============================================================
  // CURRENT WALK ID
  //
  // Live session ID first.
  // Otherwise active walk ID.
  // ============================================================

  String get _currentWalkId {
    if (_sessionWalkId.isNotEmpty) {
      return _sessionWalkId;
    }

    return _activeWalkId;
  }

  // ============================================================
  // TAP
  // ============================================================

  void _handleTap() {
    if (!_shouldShow) {
      return;
    }

    debugPrint(
      'ActiveWalkStrip tapped: '
      'isLive=$_isLive '
      'walkId=$_currentWalkId',
    );

    widget.onTap();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        child: Container(
          width: double.infinity,
          height: 46,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration:
              const BoxDecoration(
            gradient: LinearGradient(
              begin:
                  Alignment.centerLeft,
              end:
                  Alignment.centerRight,
              colors: <Color>[
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isLive
                    ? Icons.location_on_rounded
                    : Icons.directions_walk_rounded,
                color: Colors.white,
                size: 21,
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  _isLive
                      ? 'LIVE WALK'
                      : 'ACTIVE WALK',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS HELPER
  // ============================================================

  String _status(dynamic value) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .toUpperCase();
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _activeWalkSubscription?.cancel();
    _liveSessionSubscription?.cancel();

    super.dispose();
  }
}
