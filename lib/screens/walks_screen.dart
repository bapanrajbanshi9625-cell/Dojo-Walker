// File: lib/screens/walks_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/insta_walk/models/insta_walk_request.dart';
import '../features/insta_walk/screens/incoming_walk_request_screen.dart';
import '../features/insta_walk/services/insta_walk_accept_service.dart';
import '../features/insta_walk/services/insta_walk_reject_service.dart';
import '../features/insta_walk/services/insta_walk_request_service.dart';
import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../features/insta_walk/widgets/insta_walk_request_card.dart';
import '../features/walker_home/containers/walker_home_header.dart';

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
  // INSTA WALK SERVICES
  // ============================================================

  final InstaWalkRequestService _requestService =
      InstaWalkRequestService.instance;

  final InstaWalkAcceptService _acceptService =
      InstaWalkAcceptService.instance;

  final InstaWalkRejectService _rejectService =
      InstaWalkRejectService.instance;

  // ============================================================
  // REQUEST SUBSCRIPTION
  // ============================================================

  StreamSubscription<List<InstaWalkRequest>>?
      _requestSubscription;

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
  // FULL SCREEN REQUEST
  // ============================================================

  bool _openingIncomingRequest = false;

  String? _shownRequestId;

  // ============================================================
  // REQUESTS
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
        _startRequestListener();
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
  // ============================================================

  Future<void> _startSearch() async {
    if (_loading) {
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

    setState(() {
      _loading = true;
    });

    try {
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
        _shownRequestId = null;
      });

      _startRequestListener();
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
  // REQUEST LISTENER
  //
  // Firestore:
  //
  // walk_request
  //
  // status:
  // searching
  //
  // NEW REQUEST:
  // full screen incoming request opens.
  // ============================================================

  void _startRequestListener() {
    _requestSubscription?.cancel();

    _requestSubscription =
        _requestService
            .pendingRequestsStream()
            .listen(
      (
        List<InstaWalkRequest> requests,
      ) {
        if (!mounted || !_searching) {
          return;
        }

        final List<InstaWalkRequest>
            sortedRequests =
            List<InstaWalkRequest>.from(
          requests,
        )..sort(
            (
              InstaWalkRequest a,
              InstaWalkRequest b,
            ) {
              return a.distanceKm.compareTo(
                b.distanceKm,
              );
            },
          );

        setState(() {
          _requests
            ..clear()
            ..addAll(sortedRequests);
        });

        // ------------------------------------------------------
        // FULL SCREEN INCOMING REQUEST
        // ------------------------------------------------------

        if (sortedRequests.isNotEmpty) {
          final InstaWalkRequest request =
              sortedRequests.first;

          unawaited(
            _openIncomingRequest(request),
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'Insta Walk listener error: $error',
        );

        if (mounted) {
          _showMessage(
            'Unable to receive walk requests.',
          );
        }
      },
    );
  }

  // ============================================================
  // OPEN FULL SCREEN REQUEST
  // ============================================================

  Future<void> _openIncomingRequest(
    InstaWalkRequest request,
  ) async {
    if (!mounted) {
      return;
    }

    if (_openingIncomingRequest) {
      return;
    }

    if (_shownRequestId == request.id) {
      return;
    }

    _openingIncomingRequest = true;
    _shownRequestId = request.id;

    // Stop search while request screen is open.
    try {
      await _stopSearchState(
        clearRequests: false,
      );
    } catch (e) {
      debugPrint(
        'Stop search before incoming screen error: $e',
      );
    }

    if (!mounted) {
      _openingIncomingRequest = false;
      return;
    }

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return IncomingWalkRequestScreen(
              request: request,
            );
          },
          fullscreenDialog: true,
        ),
      );
    } catch (e) {
      debugPrint(
        'Incoming request screen error: $e',
      );
    } finally {
      _openingIncomingRequest = false;
    }
  }

  // ============================================================
  // ACCEPT REQUEST
  //
  // Accept service handles:
  //
  // walk_request/{walkId}
  // status = accepted
  //
  // After acceptance the next flow can open
  // pickup/reach screen.
  // ============================================================

  Future<void> _acceptRequest(
    InstaWalkRequest request,
  ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    try {
      await _acceptService.acceptWalk(
        request.id,
      );

      await _stopSearchState(
        clearRequests: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests.removeWhere(
          (InstaWalkRequest item) {
            return item.id == request.id;
          },
        );
      });

      _showMessage(
        'Walk request accepted.',
      );
    } catch (e) {
      debugPrint(
        'Accept Insta Walk error: $e',
      );

      if (mounted) {
        _showMessage(
          e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }
    }
  }

  // ============================================================
  // REJECT REQUEST
  // ============================================================

  Future<void> _rejectRequest(
    InstaWalkRequest request,
  ) async {
    try {
      await _rejectService.rejectWalk(
        request.id,
      );

      await _requestService.stopRequestSound(
        request.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests.removeWhere(
          (InstaWalkRequest item) {
            return item.id == request.id;
          },
        );

        if (_shownRequestId == request.id) {
          _shownRequestId = null;
        }
      });
    } catch (e) {
      debugPrint(
        'Reject Insta Walk error: $e',
      );

      if (mounted) {
        _showMessage(
          e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }
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

      await _requestSubscription?.cancel();

      _requestSubscription = null;

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
              child:
                  CircularProgressIndicator(
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
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(
            left: 3,
            bottom: 9,
          ),
          child: Text(
            'AVAILABLE WALK REQUESTS',
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ..._requests.map(
          (
            InstaWalkRequest request,
          ) {
            return InstaWalkRequestCard(
              request: request,
              onAccept: () {
                _acceptRequest(request);
              },
              onReject: () {
                _rejectRequest(request);
              },
            );
          },
        ),
      ],
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
    WidgetsBinding.instance
        .removeObserver(this);

    _requestSubscription?.cancel();

    _requestSubscription = null;

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
      body: Column(
        children: <Widget>[
          const WalkerHomeHeader(),

          Expanded(
            child: ListView(
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
          ),
        ],
      ),
    );
  }
}
