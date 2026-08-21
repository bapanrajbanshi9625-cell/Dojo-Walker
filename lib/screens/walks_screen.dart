// File: lib/screens/walks_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/walker_home/containers/walker_home_header.dart';

import '../features/walks/constants/walks_constants.dart';
import '../features/walks/models/walk_request.dart';
import '../features/walks/services/walk_request_sound_service.dart';

import '../features/walks/widgets/insta_walk_container.dart';
import '../features/walks/widgets/walk_request_card.dart';

import 'active_walk_details_screen.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({super.key});

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  // ============================================================
  // WALKER IDENTITY
  // ============================================================

  String? _walkerUid;

  /// MAIN BUSINESS WALKER ID
  ///
  /// Source:
  /// phoneAccounts/{UID}.walkerId
  String? _walkerId;

  // ============================================================
  // SEARCH STATE
  // ============================================================

  bool _searching = false;
  bool _loading = false;

  // ============================================================
  // WALK REQUESTS
  // ============================================================

  final List<WalkRequest> _requests = [];

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

    final User? user = _auth.currentUser;

    _walkerUid = user?.uid;

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Move radar dot every 10 seconds while searching.
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
  // LOAD WALKER STATE
  // ============================================================

  Future<void> _loadWalkerState() async {
    final String? uid = _walkerUid;

    if (uid == null) {
      return;
    }

    try {
      // ========================================================
      // 1. GET WALKER ID
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot = await _firestore
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      final Map<String, dynamic>? accountData =
          accountSnapshot.data();

      final dynamic savedWalkerId =
          accountData?['walkerId'];

      if (savedWalkerId != null) {
        final String id =
            savedWalkerId.toString().trim();

        if (id.isNotEmpty) {
          _walkerId = id;
        }
      }

      // ========================================================
      // 2. LOAD SEARCH STATE
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          userSnapshot = await _firestore
              .collection('users')
              .doc(uid)
              .get();

      final Map<String, dynamic>? userData =
          userSnapshot.data();

      final bool searching =
          userData?['instaWalkSearching'] == true;

      // ========================================================
      // 3. KEEP WALKER ID IN USERS DOCUMENT
      // ========================================================

      if (_walkerId != null &&
          _walkerId!.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(uid)
            .set(
          {
            'walkerId': _walkerId,
          },
          SetOptions(merge: true),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _searching = searching;
      });

      // ========================================================
      // 4. RESTORE ACTIVE SEARCH
      // ========================================================

      if (searching) {
        _startRequestListener();
        _moveRadarDot();
      }
    } catch (e) {
      debugPrint(
        'Walker State Load Error: $e',
      );
    }
  }

  // ============================================================
  // GET WALKER ID
  // ============================================================

  Future<String?> _getWalkerId() async {
    if (_walkerId != null &&
        _walkerId!.trim().isNotEmpty) {
      return _walkerId;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection('phoneAccounts')
              .doc(user.uid)
              .get();

      final Map<String, dynamic>? data =
          snapshot.data();

      final dynamic value =
          data?['walkerId'];

      if (value != null) {
        final String id =
            value.toString().trim();

        if (id.isNotEmpty) {
          _walkerId = id;

          if (mounted) {
            setState(() {});
          }

          return id;
        }
      }
    } catch (e) {
      debugPrint(
        'Walker ID Load Error: $e',
      );
    }

    return null;
  }

  // ============================================================
  // START INSTA WALK SEARCH
  // ============================================================

  Future<void> _startSearch() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    if (_loading) {
      return;
    }

    final String? walkerId =
        await _getWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      _showMessage(
        'Walker ID is not available. Please complete your Walker profile.',
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
      // ========================================================
      // SAVE SEARCH STATE
      // ========================================================

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'walkerId': walkerId,
          'instaWalkSearching': true,
          'instaWalkSearchRadiusKm':
              WalksConstants.searchRadiusKm,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _walkerId = walkerId;
        _searching = true;
        _loading = false;
        _requests.clear();
      });

      // Stop any old request sound.
      await WalkRequestSoundService.instance
          .stopAll();

      // Start request listener.
      _startRequestListener();

      // Show radar dot.
      _moveRadarDot();
    } catch (e) {
      debugPrint(
        'Start Insta Walk Error: $e',
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

  void _startRequestListener() {
    _requestSubscription?.cancel();

    _requestSubscription = _firestore
        .collection('walk_requests')
        .where(
          'status',
          isEqualTo: 'searching',
        )
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) {
          return;
        }

        final List<WalkRequest> incoming = [];

        // ======================================================
        // READ REQUESTS
        // ======================================================

        for (final QueryDocumentSnapshot<
                Map<String, dynamic>> document
            in snapshot.docs) {
          final Map<String, dynamic> data =
              document.data();

          // ====================================================
          // DISTANCE FILTER
          // ====================================================

          final double distance =
              _readDistance(
            data['distanceKm'],
          );

          if (distance >
              WalksConstants.searchRadiusKm) {
            continue;
          }

          // ====================================================
          // CONVERT FIRESTORE DOCUMENT
          // ====================================================

          final WalkRequest request =
              WalkRequest.fromFirestore(
            document,
          );

          incoming.add(request);
        }

        // ======================================================
        // SORT NEAREST REQUEST FIRST
        // ======================================================

        incoming.sort(
          (a, b) =>
              a.distanceKm.compareTo(
            b.distanceKm,
          ),
        );

        // ======================================================
        // SOUND MANAGEMENT
        // ======================================================

        final Set<String> incomingIds =
            incoming
                .map(
                  (request) => request.id,
                )
                .toSet();

        // ======================================================
        // PLAY SOUND FOR NEW REQUEST
        // ======================================================

        for (final WalkRequest request
            in incoming) {
          final bool alreadyExists =
              _requests.any(
            (oldRequest) =>
                oldRequest.id == request.id,
          );

          if (!alreadyExists) {
            WalkRequestSoundService.instance
                .playForRequest(
              request.id,
            );
          }
        }

        // ======================================================
        // STOP SOUND FOR REMOVED REQUEST
        // ======================================================

        for (final WalkRequest oldRequest
            in List<WalkRequest>.from(_requests)) {
          if (!incomingIds.contains(
            oldRequest.id,
          )) {
            WalkRequestSoundService.instance
                .stopRequest(
              oldRequest.id,
            );
          }
        }

        // ======================================================
        // UPDATE UI
        // ======================================================

        setState(() {
          _requests
            ..clear()
            ..addAll(incoming);
        });
      },
      onError: (Object error) {
        debugPrint(
          'Walk Request Listener Error: $error',
        );

        if (!mounted) {
          return;
        }

        _showMessage(
          'Unable to receive walk requests.',
        );
      },
    );
  }

  // ============================================================
  // READ DISTANCE
  // ============================================================

  double _readDistance(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        999;
  }

  // ============================================================
  // ACCEPT REQUEST
  // ============================================================

  Future<void> _acceptRequest(
    WalkRequest request,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    final String? walkerId =
        await _getWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      _showMessage(
        'Walker ID is not available.',
      );
      return;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection('walk_requests')
              .doc(request.id);

      // ========================================================
      // TRANSACTION
      // ========================================================

      await _firestore.runTransaction(
        (transaction) async {
          final DocumentSnapshot<
              Map<String, dynamic>> snapshot =
              await transaction.get(
            requestRef,
          );

          if (!snapshot.exists) {
            throw Exception(
              'Request no longer exists.',
            );
          }

          final Map<String, dynamic>? data =
              snapshot.data();

          if (data == null) {
            throw Exception(
              'Walk request data is empty.',
            );
          }

          final String status =
              data['status']?.toString() ?? '';

          if (status != 'searching') {
            throw Exception(
              'Request already accepted.',
            );
          }

          transaction.update(
            requestRef,
            {
              'status': 'accepted',
              'walkerId': walkerId,
              'walkerUid': user.uid,
              'acceptedBy': walkerId,
              'acceptedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );

      // ========================================================
      // STOP SOUND
      // ========================================================

      await WalkRequestSoundService.instance
          .stopRequest(
        request.id,
      );

      // ========================================================
      // STOP WALKER SEARCH
      // ========================================================

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'walkerId': walkerId,
          'instaWalkSearching': false,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // ========================================================
      // CANCEL REQUEST LISTENER
      // ========================================================

      await _requestSubscription?.cancel();

      _requestSubscription = null;

      // ========================================================
      // STOP ALL REMAINING SOUNDS
      // ========================================================

      await WalkRequestSoundService.instance
          .stopAll();

      // ========================================================
      // READ UPDATED REQUEST
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          acceptedSnapshot =
          await requestRef.get();

      if (!acceptedSnapshot.exists) {
        throw Exception(
          'Accepted walk could not be loaded.',
        );
      }

      final WalkRequest acceptedRequest =
          WalkRequest.fromFirestore(
        acceptedSnapshot,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searching = false;

        _requests.removeWhere(
          (item) => item.id == request.id,
        );

        _dotVisible = false;
      });

      // ========================================================
      // OPEN ACTIVE WALK
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ActiveWalkDetailsScreen(
            request: acceptedRequest,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Accept Walk Request Error: $e',
      );

      await WalkRequestSoundService.instance
          .stopRequest(
        request.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'This walk request is no longer available.',
      );
    }
  }

  // ============================================================
  // REJECT REQUEST
  // ============================================================

  Future<void> _rejectRequest(
    WalkRequest request,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    final String? walkerId =
        await _getWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      _showMessage(
        'Walker ID is not available.',
      );
      return;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection('walk_requests')
              .doc(request.id);

      // ========================================================
      // TRANSACTION
      // ========================================================

      await _firestore.runTransaction(
        (transaction) async {
          final DocumentSnapshot<
              Map<String, dynamic>> snapshot =
              await transaction.get(
            requestRef,
          );

          if (!snapshot.exists) {
            throw Exception(
              'Request no longer exists.',
            );
          }

          final Map<String, dynamic>? data =
              snapshot.data();

          if (data == null) {
            throw Exception(
              'Walk request data is empty.',
            );
          }

          final String status =
              data['status']?.toString() ?? '';

          if (status != 'searching') {
            throw Exception(
              'Request is no longer available.',
            );
          }

          transaction.update(
            requestRef,
            {
              'status': 'rejected',
              'rejectedBy': walkerId,
              'rejectedWalkerUid': user.uid,
              'rejectedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );

      // ========================================================
      // STOP ONLY THIS REQUEST SOUND
      // ========================================================

      await WalkRequestSoundService.instance
          .stopRequest(
        request.id,
      );

      // ========================================================
      // REMOVE FROM LOCAL LIST
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _requests.removeWhere(
          (item) => item.id == request.id,
        );
      });
    } catch (e) {
      debugPrint(
        'Reject Walk Request Error: $e',
      );

      await WalkRequestSoundService.instance
          .stopRequest(
        request.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'This walk request is no longer available.',
      );
    }
  }

  // ============================================================
  // STOP SEARCH
  // ============================================================

  Future<void> _stopSearch() async {
    final String? uid = _walkerUid;

    if (uid == null) {
      return;
    }

    // Stop sounds immediately.
    await WalkRequestSoundService.instance
        .stopAll();

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(
        {
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
        _requests.clear();
        _dotVisible = false;
      });
    } catch (e) {
      debugPrint(
        'Stop Insta Walk Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to stop searching.',
      );
    }
  }

  // ============================================================
  // SEARCH BUTTON
  // ============================================================

  void _searchButtonPressed() {
    if (!_searching) {
      _startSearch();
    } else {
      _showStopDialog();
    }
  }

  // ============================================================
  // STOP SEARCH DIALOG
  // ============================================================

  Future<void> _showStopDialog() async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor:
          Colors.black.withOpacity(.48),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(26),
          ),
          title: const Text(
            'Stop Searching?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WalksConstants.darkText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'You will stop receiving nearby Insta Walk requests.',
            textAlign: TextAlign.center,
          ),
          actions: [
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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    WalksConstants.buttonBlue,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Confirm',
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await _stopSearch();
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
  // MESSAGE
  // ============================================================

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
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // REQUEST LIST
  // ============================================================

  Widget _buildRequests() {
    if (_requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color:
              Colors.white.withOpacity(.52),
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<
                        Color>(
                  WalksConstants.radarGreen,
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                'Waiting for nearby walk requests...',
                style: TextStyle(
                  color:
                      Color(0xFF35443A),
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
      children: [
        const Padding(
          padding: EdgeInsets.only(
            left: 3,
            bottom: 9,
          ),
          child: Text(
            'AVAILABLE WALK REQUESTS',
            style: TextStyle(
              color:
                  Color(0xFF26352A),
              fontSize: 10,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),

        ..._requests.map(
          (request) => WalkRequestCard(
            request: request,

            // ACCEPT
            onAccept: () =>
                _acceptRequest(request),

            // REJECT
            onReject: () =>
                _rejectRequest(request),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _requestSubscription?.cancel();

    _dotTimer?.cancel();

    _dotGlowTimer?.cancel();

    WalkRequestSoundService.instance
        .stopAll();

    _radarController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),
      body: Column(
        children: [
          const WalkerHomeHeader(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                bottom: 30,
              ),
              children: [
                // ==================================================
                // DIVIDED INSTA WALK CONTAINER
                // ==================================================

                InstaWalkContainer(
                  searching: _searching,
                  loading: _loading,
                  radarAnimation:
                      _radarController,
                  dotVisible: _dotVisible,
                  dotX: _dotX,
                  dotY: _dotY,
                  requests: _requests,

                  // SEARCH / STOP
                  onSearchPressed:
                      _searchButtonPressed,

                  // REQUEST LIST
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
