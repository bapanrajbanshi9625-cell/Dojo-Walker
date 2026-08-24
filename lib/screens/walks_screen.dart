// File: lib/screens/walks_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/insta_walk/models/insta_walk_request.dart';

import 'active_walk_details_screen.dart';
import 'qr_scanner_screen.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  // ============================================================
  // WALKER IDENTITY
  // ============================================================

  String? _walkerUid;
  String? _walkerId;

  // ============================================================
  // SEARCH STATE
  // ============================================================

  bool _searching = false;
  bool _loading = false;

  // ============================================================
  // QR STATE
  // ============================================================

  bool _openingQrScanner = false;

  // ============================================================
  // WALK REQUESTS
  // ============================================================

  final List<WalkRequest> _requests = <WalkRequest>[];

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
      // --------------------------------------------------------
      // GET WALKER ID
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>> accountSnapshot =
          await _firestore.collection('phoneAccounts').doc(uid).get();

      final Map<String, dynamic>? accountData =
          accountSnapshot.data();

      final dynamic savedWalkerId = accountData?['walkerId'];

      if (savedWalkerId != null) {
        final String id = savedWalkerId.toString().trim();

        if (id.isNotEmpty) {
          _walkerId = id;
        }
      }

      // --------------------------------------------------------
      // LOAD SEARCH STATE
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await _firestore.collection('users').doc(uid).get();

      final Map<String, dynamic>? userData = userSnapshot.data();

      final bool searching =
          userData?['instaWalkSearching'] == true;

      // --------------------------------------------------------
      // KEEP WALKER ID IN USERS
      // --------------------------------------------------------

      if (_walkerId != null && _walkerId!.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set(
          <String, dynamic>{
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

      // --------------------------------------------------------
      // RESTORE ACTIVE SEARCH
      // --------------------------------------------------------

      if (searching) {
        _startRequestListener();
        _moveRadarDot();
      }
    } catch (e) {
      debugPrint('Walker State Load Error: $e');
    }
  }

  // ============================================================
  // GET WALKER ID
  // ============================================================

  Future<String?> _getWalkerId() async {
    if (_walkerId != null && _walkerId!.trim().isNotEmpty) {
      return _walkerId;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('phoneAccounts')
              .doc(user.uid)
              .get();

      final Map<String, dynamic>? data = snapshot.data();
      final dynamic value = data?['walkerId'];

      if (value != null) {
        final String id = value.toString().trim();

        if (id.isNotEmpty) {
          _walkerId = id;

          if (mounted) {
            setState(() {});
          }

          return id;
        }
      }
    } catch (e) {
      debugPrint('Walker ID Load Error: $e');
    }

    return null;
  }

  // ============================================================
  // OPEN QR SCANNER
  // ============================================================

  Future<void> _openQrScanner() async {
    if (_openingQrScanner || !mounted) {
      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final String? walkerId = await _getWalkerId();

    if (walkerId == null || walkerId.trim().isEmpty) {
      _showMessage(
        'Walker ID is not available. Please complete your Walker profile.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _openingQrScanner = true;
    });

    try {
      final dynamic result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const QrScannerScreen(),
        ),
      );

      if (!mounted) {
        return;
      }

      if (result != null) {
        await _handleQrResult(result);
      }
    } catch (e) {
      debugPrint('Open QR Scanner Error: $e');

      if (mounted) {
        _showMessage('Unable to open QR scanner.');
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
  // HANDLE QR RESULT
  // ============================================================

  Future<void> _handleQrResult(dynamic result) async {
    try {
      Map<String, dynamic> data = <String, dynamic>{};

      if (result is String) {
        final dynamic decoded = jsonDecode(result);

        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      }

      if (result is Map) {
        data = Map<String, dynamic>.from(result);
      }

      if (data.isEmpty) {
        return;
      }

      final String ownerId =
          data['ownerId']?.toString().trim() ?? '';

      final String walkerId =
          data['walkerId']?.toString().trim() ?? '';

      final String sessionId =
          data['sessionId']?.toString().trim() ?? '';

      final String walkId =
          data['walkId']?.toString().trim() ?? '';

      final String ownerName =
          data['ownerName']?.toString().trim() ?? 'Owner';

      // --------------------------------------------------------
      // VALIDATE QR
      // --------------------------------------------------------

      if (sessionId.isEmpty && walkId.isEmpty) {
        _showMessage('QR connection was not completed.');
        return;
      }

      // --------------------------------------------------------
      // VERIFY WALKER
      // --------------------------------------------------------

      final String? currentWalkerId = await _getWalkerId();

      if (currentWalkerId != null &&
          walkerId.isNotEmpty &&
          walkerId != currentWalkerId) {
        _showMessage(
          'This QR connection belongs to another walker.',
        );
        return;
      }

      // --------------------------------------------------------
      // STOP INSTA WALK
      // --------------------------------------------------------

      final User? user = _auth.currentUser;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(
          <String, dynamic>{
            'walkerId': currentWalkerId,
            'instaWalkSearching': false,
            'instaWalkSearchUpdatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // --------------------------------------------------------
      // STOP LISTENER
      // --------------------------------------------------------

      await _requestSubscription?.cancel();
      _requestSubscription = null;

      // --------------------------------------------------------
      // STOP SOUNDS
      // --------------------------------------------------------

      await WalkRequestSoundService.instance.stopAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _searching = false;
        _requests.clear();
        _dotVisible = false;
      });

      _showMessage(
        ownerId.isNotEmpty
            ? 'Connected with $ownerName.'
            : 'Live Walk connected successfully.',
      );
    } catch (e) {
      debugPrint('QR Result Error: $e');

      if (mounted) {
        _showMessage('Invalid QR connection result.');
      }
    }
  }

  // ============================================================
  // START INSTA WALK SEARCH
  // ============================================================

  Future<void> _startSearch() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    if (_loading) {
      return;
    }

    final String? walkerId = await _getWalkerId();

    if (walkerId == null || walkerId.trim().isEmpty) {
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
      await _firestore.collection('users').doc(user.uid).set(
        <String, dynamic>{
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

      await WalkRequestSoundService.instance.stopAll();

      _startRequestListener();
      _moveRadarDot();
    } catch (e) {
      debugPrint('Start Insta Walk Error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage('Unable to start Insta Walk search.');
    }
  }

  // ============================================================
  // REQUEST LISTENER
  // ============================================================

  void _startRequestListener() {
    _requestSubscription?.cancel();

    _requestSubscription = _firestore
        .collection('walk_requests')
        .where('status', isEqualTo: 'searching')
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) {
          return;
        }

        final List<WalkRequest> incoming = <WalkRequest>[];

        // ------------------------------------------------------
        // READ REQUESTS
        // ------------------------------------------------------

        for (
          final QueryDocumentSnapshot<Map<String, dynamic>> document
              in snapshot.docs
        ) {
          final Map<String, dynamic> data = document.data();

          final double distance = _readDistance(
            data['distanceKm'],
          );

          if (distance > WalksConstants.searchRadiusKm) {
            continue;
          }

          final WalkRequest request =
              WalkRequest.fromFirestore(document);

          incoming.add(request);
        }

        // ------------------------------------------------------
        // SORT BY DISTANCE
        // ------------------------------------------------------

        incoming.sort(
          (a, b) => a.distanceKm.compareTo(b.distanceKm),
        );

        // ------------------------------------------------------
        // SOUND MANAGEMENT
        // ------------------------------------------------------

        final Set<String> incomingIds = incoming
            .map((request) => request.id)
            .toSet();

        for (final WalkRequest request in incoming) {
          final bool alreadyExists = _requests.any(
            (oldRequest) => oldRequest.id == request.id,
          );

          if (!alreadyExists) {
            WalkRequestSoundService.instance.playForRequest(
              request.id,
            );
          }
        }

        for (
          final WalkRequest oldRequest
              in List<WalkRequest>.from(_requests)
        ) {
          if (!incomingIds.contains(oldRequest.id)) {
            WalkRequestSoundService.instance.stopRequest(
              oldRequest.id,
            );
          }
        }

        // ------------------------------------------------------
        // UPDATE UI
        // ------------------------------------------------------

        setState(() {
          _requests
            ..clear()
            ..addAll(incoming);
        });
      },
      onError: (Object error) {
        debugPrint('Walk Request Listener Error: $error');

        if (mounted) {
          _showMessage(
            'Unable to receive walk requests.',
          );
        }
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

  Future<void> _acceptRequest(WalkRequest request) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final String? walkerId = await _getWalkerId();

    if (walkerId == null || walkerId.trim().isEmpty) {
      _showMessage('Walker ID is not available.');
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> requestRef =
          _firestore.collection('walk_requests').doc(request.id);

      await _firestore.runTransaction(
        (transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(requestRef);

          if (!snapshot.exists) {
            throw Exception('Request no longer exists.');
          }

          final Map<String, dynamic>? data = snapshot.data();

          if (data == null) {
            throw Exception('Walk request data is empty.');
          }

          final String status =
              data['status']?.toString() ?? '';

          if (status != 'searching') {
            throw Exception('Request already accepted.');
          }

          transaction.update(
            requestRef,
            <String, dynamic>{
              'status': 'accepted',
              'walkerId': walkerId,
              'walkerUid': user.uid,
              'acceptedBy': walkerId,
              'acceptedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        },
      );

      await WalkRequestSoundService.instance.stopRequest(
        request.id,
      );

      await _firestore.collection('users').doc(user.uid).set(
        <String, dynamic>{
          'walkerId': walkerId,
          'instaWalkSearching': false,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _requestSubscription?.cancel();
      _requestSubscription = null;

      await WalkRequestSoundService.instance.stopAll();

      final DocumentSnapshot<Map<String, dynamic>> acceptedSnapshot =
          await requestRef.get();

      if (!acceptedSnapshot.exists) {
        throw Exception(
          'Accepted walk could not be loaded.',
        );
      }

      final WalkRequest acceptedRequest =
          WalkRequest.fromFirestore(acceptedSnapshot);

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

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWalkDetailsScreen(
            request: acceptedRequest,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Accept Walk Request Error: $e');

      await WalkRequestSoundService.instance.stopRequest(
        request.id,
      );

      if (mounted) {
        _showMessage(
          'This walk request is no longer available.',
        );
      }
    }
  }

  // ============================================================
  // REJECT REQUEST
  // ============================================================

  Future<void> _rejectRequest(WalkRequest request) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final String? walkerId = await _getWalkerId();

    if (walkerId == null || walkerId.trim().isEmpty) {
      _showMessage('Walker ID is not available.');
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> requestRef =
          _firestore.collection('walk_requests').doc(request.id);

      await _firestore.runTransaction(
        (transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(requestRef);

          if (!snapshot.exists) {
            throw Exception('Request no longer exists.');
          }

          final Map<String, dynamic>? data = snapshot.data();

          if (data == null) {
            throw Exception('Walk request data is empty.');
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
            <String, dynamic>{
              'status': 'rejected',
              'rejectedBy': walkerId,
              'rejectedWalkerUid': user.uid,
              'rejectedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        },
      );

      await WalkRequestSoundService.instance.stopRequest(
        request.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests.removeWhere(
          (item) => item.id == request.id,
        );
      });
    } catch (e) {
      debugPrint('Reject Walk Request Error: $e');

      await WalkRequestSoundService.instance.stopRequest(
        request.id,
      );

      if (mounted) {
        _showMessage(
          'This walk request is no longer available.',
        );
      }
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

    await WalkRequestSoundService.instance.stopAll();

    try {
      await _firestore.collection('users').doc(uid).set(
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
        _requests.clear();
        _dotVisible = false;
      });
    } catch (e) {
      debugPrint('Stop Insta Walk Error: $e');

      if (mounted) {
        _showMessage('Unable to stop searching.');
      }
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
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(.48),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
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
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: WalksConstants.buttonBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
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
      _dotX = -.78 + _random.nextDouble() * 1.56;
      _dotY = -.65 + _random.nextDouble() * 1.30;
      _dotVisible = true;
    });

    _dotGlowTimer = Timer(
      const Duration(milliseconds: 1200),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // REQUEST LIST
  // ============================================================

  Widget _buildRequests(BuildContext context) {
    if (_requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.52),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  WalksConstants.radarGreen,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Waiting for nearby walk requests...',
                style: TextStyle(
                  color: Color(0xFF35443A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(
            left: 3,
            bottom: 9,
          ),
          child: Text(
            'AVAILABLE WALK REQUESTS',
            style: TextStyle(
              color: Color(0xFF26352A),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ..._requests.map(
          (WalkRequest request) => WalkRequestCard(
            request: request,
            onAccept: () => _acceptRequest(request),
            onReject: () => _rejectRequest(request),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FLOATING QR BUTTON
  // ============================================================

  Widget _buildFloatingQrButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 22,
      child: Center(
        child: GestureDetector(
          onTap: _openingQrScanner
              ? null
              : _openQrScanner,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFF4511E),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: _openingQrScanner
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'SCAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _dotTimer?.cancel();
    _dotGlowTimer?.cancel();

    WalkRequestSoundService.instance.stopAll();

    _radarController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              const WalkerHomeHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    bottom: 120,
                  ),
                  children: <Widget>[
                    InstaWalkContainer(
                      searching: _searching,
                      loading: _loading,
                      radarAnimation: _radarController,
                      dotVisible: _dotVisible,
                      dotX: _dotX,
                      dotY: _dotY,
                      requests: _requests,
                      onSearchPressed: _searchButtonPressed,
                      requestListBuilder: _buildRequests,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // CENTER FLOATING QR SCAN BUTTON
          _buildFloatingQrButton(),
        ],
      ),
    );
  }
}
