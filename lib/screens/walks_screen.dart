// File: lib/screens/walks_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/insta_walk/models/insta_walk_request.dart';
import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../services/walker_availability_service.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({
    super.key,
  });

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // WALKER
  // ============================================================

  String? _walkerUid;
  String? _walkerId;

  // ============================================================
  // SEARCH
  // ============================================================

  bool _searching = false;
  bool _loading = false;

  // ============================================================
  // REQUESTS
  //
  // Kept for InstaWalkContainer compatibility.
  //
  // Incoming requests are handled globally by app.dart.
  // ============================================================

  final List<InstaWalkRequest> _requests =
      <InstaWalkRequest>[];

  // ============================================================
  // RADAR
  // ============================================================

  late final AnimationController _radarController;

  Timer? _dotTimer;
  Timer? _dotGlowTimer;

  final math.Random _random = math.Random();

  double _dotX = 0;
  double _dotY = 0;

  bool _dotVisible = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _walkerUid = _auth.currentUser?.uid;

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _dotTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (_searching && mounted) {
          _moveRadarDot();
        }
      },
    );

    unawaited(_loadWalkerState());
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.detached &&
        _searching) {
      unawaited(_stopSearchState());
    }
  }

  // ============================================================
  // LOAD WALKER STATE
  // ============================================================

  Future<void> _loadWalkerState() async {
    final String? uid = _walkerUid;

    if (uid == null || uid.trim().isEmpty) {
      return;
    }

    try {
      // --------------------------------------------------------
      // WALKER ID
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>>
          account =
          await _firestore
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      final Map<String, dynamic>? accountData =
          account.data();

      final String savedWalkerId =
          accountData?['walkerId']
                  ?.toString()
                  .trim() ??
              '';

      if (savedWalkerId.isNotEmpty) {
        _walkerId = savedWalkerId;
      }

      // --------------------------------------------------------
      // SEARCH STATE
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>>
          userDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .get();

      final Map<String, dynamic>? userData =
          userDoc.data();

      final bool searching =
          userData?['instaWalkSearching'] == true;

      if (!mounted) {
        return;
      }

      setState(() {
        _searching = searching;
      });

      if (searching) {
        _moveRadarDot();
      }
    } catch (e) {
      debugPrint(
        'Walker state error: $e',
      );
    }
  }

  // ============================================================
  // GET WALKER ID
  // ============================================================

  Future<String?> _getWalkerId() async {
    final String cached =
        _walkerId?.trim() ?? '';

    if (cached.isNotEmpty) {
      return cached;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
              .collection('phoneAccounts')
              .doc(user.uid)
              .get();

      final String id =
          snapshot.data()?['walkerId']
                  ?.toString()
                  .trim() ??
              '';

      if (id.isEmpty) {
        return null;
      }

      _walkerId = id;

      return id;
    } catch (e) {
      debugPrint(
        'Walker ID error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // START SEARCH
  //
  // This only enables the Walker's search state.
  //
  // Incoming request detection is handled globally by app.dart.
  // ============================================================

  Future<void> _startSearch() async {
    if (_loading) {
      return;
    }

    // ----------------------------------------------------------
    // GLOBAL AVAILABILITY GUARD
    // ----------------------------------------------------------

    final WalkerAvailabilityService availability =
        WalkerAvailabilityService.instance;

    if (!availability.isOnline) {
      _showMessage(
        'You are Offline. Go Online to search for Insta Walk requests.',
      );
      return;
    }

    if (!availability.canPerformWalkAction()) {
      _showMessage(
        availability.unavailableMessage,
      );
      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final String? walkerId =
        await _getWalkerId();

    if (walkerId == null ||
        walkerId.isEmpty) {
      _showMessage(
        'Walker ID is not available. '
        'Please complete your Walker profile.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // CHECK AGAIN AFTER ASYNC WALKER ID LOAD
    //
    // Availability could have changed while awaiting Firestore.
    // ----------------------------------------------------------

    if (!availability.isOnline) {
      _showMessage(
        'You are Offline. Go Online to search for Insta Walk requests.',
      );
      return;
    }

    if (!availability.canPerformWalkAction()) {
      _showMessage(
        availability.unavailableMessage,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // --------------------------------------------------------
      // FINAL ONLINE CHECK BEFORE FIRESTORE WRITE
      // --------------------------------------------------------

      if (!availability.isOnline) {
        if (mounted) {
          setState(() {
            _loading = false;
          });

          _showMessage(
            'You are Offline. Go Online to search for Insta Walk requests.',
          );
        }
        return;
      }

      if (!availability.canPerformWalkAction()) {
        if (mounted) {
          setState(() {
            _loading = false;
          });

          _showMessage(
            availability.unavailableMessage,
          );
        }
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        <String, dynamic>{
          'walkerId': walkerId,
          'instaWalkSearching': true,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _walkerUid = user.uid;
        _walkerId = walkerId;
        _searching = true;
        _loading = false;
        _requests.clear();
      });

      _moveRadarDot();
    } catch (e) {
      debugPrint(
        'Start Insta Walk error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to start Insta Walk search.',
      );
    }
  }

  // ============================================================
  // STOP SEARCH STATE
  // ============================================================

  Future<void> _stopSearchState({
    bool clearRequests = true,
  }) async {
    final String? uid =
        _walkerUid ??
            _auth.currentUser?.uid;

    if (uid == null ||
        uid.trim().isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(
        <String, dynamic>{
          'instaWalkSearching': false,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searching = false;

        if (clearRequests) {
          _requests.clear();
        }

        _dotVisible = false;
      });
    } catch (e) {
      debugPrint(
        'Stop search error: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // SEARCH BUTTON
  // ============================================================

  void _searchButtonPressed() {
    if (_searching) {
      _showStopDialog();
    } else {
      _startSearch();
    }
  }

  // ============================================================
  // STOP DIALOG
  // ============================================================

  Future<void> _showStopDialog() async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Stop Searching?',
          ),
          content: const Text(
            'You will stop receiving nearby '
            'Insta Walk requests.',
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
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Confirm',
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

    try {
      await _stopSearchState();
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to stop searching.',
        );
      }
    }
  }

  // ============================================================
  // RADAR DOT
  // ============================================================

  void _moveRadarDot() {
    _dotGlowTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _dotX =
          -.78 +
              _random.nextDouble() * 1.56;

      _dotY =
          -.65 +
              _random.nextDouble() * 1.30;

      _dotVisible = true;
    });

    _dotGlowTimer = Timer(
      const Duration(
        milliseconds: 1200,
      ),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _dotVisible = false;
        });
      },
    );
  }

  // ============================================================
  // REQUEST UI
  //
  // Kept for InstaWalkContainer compatibility.
  //
  // Incoming request screen is NOT opened here.
  // Global app.dart handles incoming requests.
  // ============================================================

  Widget _buildRequests(
    BuildContext context,
  ) {
    if (_requests.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          top: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: .55,
          ),
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Row(
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                'Waiting for nearby walk requests...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
    WidgetsBinding.instance
        .removeObserver(this);

    _dotTimer?.cancel();
    _dotGlowTimer?.cancel();

    _radarController.dispose();

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
      backgroundColor:
          const Color(0xFFF5F6F8),
      body: ListView(
        padding: const EdgeInsets.only(
          bottom: 30,
        ),
        children: <Widget>[
          InstaWalkContainer(
            searching: _searching,
            loading: _loading,
            radarAnimation:
                _radarController,
            dotVisible: _dotVisible,
            dotX: _dotX,
            dotY: _dotY,
            requests: _requests,
            onSearchPressed:
                _searchButtonPressed,
            requestListBuilder:
                _buildRequests,
          ),
        ],
      ),
    );
  }
}
