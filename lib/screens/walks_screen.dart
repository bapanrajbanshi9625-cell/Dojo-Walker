// File: lib/screens/walks_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/insta_walk/models/insta_walk_request.dart';
import '../features/insta_walk/screens/active_walk_details_screen.dart';
import '../features/insta_walk/services/insta_walk_accept_service.dart';
import '../features/insta_walk/services/insta_walk_reject_service.dart';
import '../features/insta_walk/services/insta_walk_service.dart';
import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../features/insta_walk/widgets/insta_walk_request_card.dart';
import '../features/walker_home/containers/walker_home_header.dart';
import 'qr_scanner_screen.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({super.key});

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

  final InstaWalkService _instaWalkService =
      InstaWalkService.instance;

  final InstaWalkAcceptService _acceptService =
      InstaWalkAcceptService.instance;

  final InstaWalkRejectService _rejectService =
      InstaWalkRejectService.instance;

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
  // QR
  // ============================================================

  bool _openingQrScanner = false;

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

  final math.Random _random =
      math.Random();

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

    _walkerUid =
        _auth.currentUser?.uid;

    _radarController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 3),
    )..repeat();

    _dotTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (_searching && mounted) {
          _moveRadarDot();
        }
      },
    );

    _loadWalkerState();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================
  //
  // Background करने पर search बंद नहीं होगी.
  //
  // App/Flutter engine detached होने पर search बंद करने की
  // कोशिश की जाएगी.
  //
  // dispose() में भी best-effort cleanup है.
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
            AppLifecycleState.detached &&
        _searching) {
      unawaited(
        _stopSearchState(),
      );
    }
  }

  // ============================================================
  // LOAD WALKER STATE
  // ============================================================

  Future<void> _loadWalkerState() async {
    final String? uid =
        _walkerUid;

    if (uid == null ||
        uid.trim().isEmpty) {
      return;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> account =
          await _firestore
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      final Map<String, dynamic>?
          accountData =
          account.data();

      final String savedWalkerId =
          accountData?['walkerId']
                  ?.toString()
                  .trim() ??
              '';

      if (savedWalkerId.isNotEmpty) {
        _walkerId = savedWalkerId;
      }

      final DocumentSnapshot<
          Map<String, dynamic>> userDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .get();

      final Map<String, dynamic>?
          userData =
          userDoc.data();

      final bool searching =
          userData?[
                  'instaWalkSearching'] ==
              true;

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

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
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

    final User? user =
        _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
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
  // ============================================================
  //
  // IMPORTANT:
  //
  // Direct walk_requests query नहीं.
  //
  // InstaWalkService.pendingRequestsStream()
  // use किया गया है.
  //
  // यही rejected requests को filter करता है.
  // ============================================================

  void _startRequestListener() {
    _requestSubscription?.cancel();

    _requestSubscription =
        _instaWalkService
            .pendingRequestsStream()
            .listen(
      (
        List<InstaWalkRequest> requests,
      ) {
        if (!mounted ||
            !_searching) {
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
            ) =>
                a.distanceKm.compareTo(
              b.distanceKm,
            ),
          );

        setState(() {
          _requests
            ..clear()
            ..addAll(
              sortedRequests,
            );
        });
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
  // ACCEPT REQUEST
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
      // --------------------------------------------------------
      // ACCEPT SERVICE
      // --------------------------------------------------------

      await _acceptService.acceptWalk(
        request.id,
      );

      // --------------------------------------------------------
      // STOP WALKER SEARCH
      // --------------------------------------------------------

      await _stopSearchState(
        clearRequests: false,
      );

      // --------------------------------------------------------
      // LOAD ACCEPTED REQUEST
      // --------------------------------------------------------

      final InstaWalkRequest?
          accepted =
          await _instaWalkService
              .getWalkRequest(
        request.id,
      );

      if (accepted == null) {
        throw Exception(
          'Accepted walk could not be loaded.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _requests.removeWhere(
          (
            InstaWalkRequest item,
          ) =>
              item.id ==
              request.id,
        );
      });

      // --------------------------------------------------------
      // ACTIVE WALK
      // --------------------------------------------------------

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ActiveWalkDetailsScreen(
            request: accepted,
          ),
        ),
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
  //
  // Main walk request rejected नहीं होगी.
  //
  // Reject service:
  //
  // walk_requests/{walkId}/rejections/{walkerId}
  //
  // में rejection save करेगा.
  // ============================================================

  Future<void> _rejectRequest(
    InstaWalkRequest request,
  ) async {
    try {
      await _rejectService.rejectWalk(
        request.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests.removeWhere(
          (
            InstaWalkRequest item,
          ) =>
              item.id ==
              request.id,
        );
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
      builder:
          (
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
      _showMessage(
        'Unable to stop searching.',
      );
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
          _random.nextDouble() *
              1.56;

      _dotY =
          -.65 +
          _random.nextDouble() *
              1.30;

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
  // QR SCANNER
  // ============================================================

  Future<void> _openQrScanner() async {
    if (_openingQrScanner ||
        !mounted) {
      return;
    }

    if (_auth.currentUser == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    setState(() {
      _openingQrScanner = true;
    });

    try {
      final dynamic result =
          await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const QrScannerScreen(),
        ),
      );

      if (!mounted) {
        return;
      }

      if (result != null) {
        await _stopSearchState();
      }
    } catch (e) {
      debugPrint(
        'QR scanner error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to open QR scanner.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingQrScanner = false;
        });
      }
    }
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
        margin:
            const EdgeInsets.only(
          top: 8,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white.withOpacity(.55),
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
            SizedBox(width: 10),
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
          padding:
              EdgeInsets.only(
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
              onAccept: () =>
                  _acceptRequest(
                request,
              ),
              onReject: () =>
                  _rejectRequest(
                request,
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // QR BUTTON
  // ============================================================

  Widget _buildFloatingQrButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 22,
      child: Center(
        child: GestureDetector(
          onTap:
              _openingQrScanner
                  ? null
                  : _openQrScanner,
          child: Container(
            width: 76,
            height: 76,
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFF4511E),
              shape:
                  BoxShape.circle,
              boxShadow:
                  <BoxShadow>[
                BoxShadow(
                  color:
                      Colors.black26,
                  blurRadius: 16,
                  offset:
                      Offset(0, 7),
                ),
              ],
            ),
            child:
                _openingQrScanner
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<
                                  Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: <Widget>[
                          Icon(
                            Icons
                                .qr_code_scanner_rounded,
                            color:
                                Colors.white,
                            size: 29,
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            'SCAN',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .w900,
                              letterSpacing:
                                  .8,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
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
          content:
              Text(message),
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

    // Best-effort cleanup.
    // dispose async नहीं हो सकता, इसलिए unawaited().
    if (_searching) {
      unawaited(
        _stopSearchState(),
      );
    }

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
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              const WalkerHomeHeader(),

              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.only(
                    bottom: 120,
                  ),
                  children: <Widget>[
                    InstaWalkContainer(
                      searching:
                          _searching,
                      loading:
                          _loading,
                      radarAnimation:
                          _radarController,
                      dotVisible:
                          _dotVisible,
                      dotX: _dotX,
                      dotY: _dotY,
                      requests:
                          _requests,
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

          _buildFloatingQrButton(),
        ],
      ),
    );
  }
}
