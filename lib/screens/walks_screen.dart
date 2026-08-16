import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/walker_home/containers/walker_home_header.dart';
import '../features/walks/constants/walks_constants.dart';
import '../features/walks/models/walk_request.dart';
import '../features/walks/widgets/insta_walk_header.dart';
import '../features/walks/widgets/insta_walk_info.dart';
import '../features/walks/widgets/insta_walk_radar.dart';
import '../features/walks/widgets/insta_walk_search_button.dart';
import '../features/walks/widgets/walk_request_card.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({super.key});

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  bool _searching = false;
  bool _loading = false;

  String? _walkerUid;

  final List<WalkRequest> _requests = [];

  late final AnimationController _radarController;

  Timer? _dotTimer;
  Timer? _dotGlowTimer;

  final math.Random _random = math.Random();

  double _dotX = 0;
  double _dotY = 0;

  bool _dotVisible = false;

  @override
  void initState() {
    super.initState();

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

    _loadWalkerState();
  }

  Future<void> _loadWalkerState() async {
    final String? uid = _walkerUid;

    if (uid == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      final data = snapshot.data();

      if (!mounted) return;

      final bool searching =
          data?['instaWalkSearching'] == true;

      setState(() {
        _searching = searching;
      });

      if (searching) {
        _startRequestListener();
        _moveRadarDot();
      }
    } catch (_) {}
  }

  Future<void> _startSearch() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'instaWalkSearching': true,
          'instaWalkSearchRadiusKm':
              WalksConstants.searchRadiusKm,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _searching = true;
        _loading = false;
      });

      _startRequestListener();
      _moveRadarDot();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to start Insta Walk search.',
      );
    }
  }

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
        if (!mounted) return;

        final List<WalkRequest> incoming = [];

        for (final document in snapshot.docs) {
          final data = document.data();

          final double distance =
              _readDistance(data['distanceKm']);

          if (distance <= WalksConstants.searchRadiusKm) {
            incoming.add(
              WalkRequest.fromFirestore(
                document.id,
                data,
              ),
            );
          }
        }

        incoming.sort(
          (a, b) =>
              a.distanceKm.compareTo(b.distanceKm),
        );

        setState(() {
          _requests
            ..clear()
            ..addAll(incoming);
        });
      },
      onError: (_) {
        if (!mounted) return;

        _showMessage(
          'Unable to receive walk requests.',
        );
      },
    );
  }

  double _readDistance(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        999;
  }

  Future<void> _acceptRequest(
    WalkRequest request,
  ) async {
    final String? uid = _walkerUid;

    if (uid == null) {
      _showMessage('Please login first.');
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          requestRef = _firestore
              .collection('walk_requests')
              .doc(request.id);

      await _firestore.runTransaction(
        (transaction) async {
          final snapshot =
              await transaction.get(requestRef);

          if (!snapshot.exists) {
            throw Exception(
              'Request no longer exists.',
            );
          }

          final data = snapshot.data();

          final String status =
              data?['status']?.toString() ?? '';

          if (status != 'searching') {
            throw Exception(
              'Request already accepted.',
            );
          }

          transaction.update(
            requestRef,
            {
              'status': 'accepted',
              'acceptedBy': uid,
              'walkerUid': uid,
              'acceptedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );

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

      if (!mounted) return;

      setState(() {
        _searching = false;
        _requests.removeWhere(
          (item) => item.id == request.id,
        );
      });

      _showMessage(
        'Walk request accepted successfully.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'This walk request is no longer available.',
      );
    }
  }

  Future<void> _stopSearch() async {
    final String? uid = _walkerUid;

    if (uid == null) return;

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

      if (!mounted) return;

      setState(() {
        _searching = false;
        _requests.clear();
        _dotVisible = false;
      });
    } catch (_) {
      _showMessage(
        'Unable to stop searching.',
      );
    }
  }

  void _searchButtonPressed() {
    if (!_searching) {
      _startSearch();
    } else {
      _showStopDialog();
    }
  }

  Future<void> _showStopDialog() async {
    final bool? confirm =
        await showDialog<bool>(
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
              child: const Text('Cancel'),
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

  void _moveRadarDot() {
    _dotGlowTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _dotX = -.78 + _random.nextDouble() * 1.56;
      _dotY = -.65 + _random.nextDouble() * 1.30;
      _dotVisible = true;
    });

    _dotGlowTimer = Timer(
      const Duration(milliseconds: 1200),
      () {
        if (!mounted) return;

        setState(() {
          _dotVisible = false;
        });
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

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

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _dotTimer?.cancel();
    _dotGlowTimer?.cancel();
    _radarController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          const WalkerHomeHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                bottom: 30,
              ),
              children: [
                _buildMainContainer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContainer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        10,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            WalksConstants.lightBlue,
            WalksConstants.lightBlue2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InstaWalkHeader(
            searching: _searching,
          ),
          const SizedBox(height: 18),
          if (!_searching)
            const InstaWalkInfo(),
          if (_searching) ...[
            InstaWalkRadar(
              animation: _radarController,
              dotVisible: _dotVisible,
              dotX: _dotX,
              dotY: _dotY,
            ),
            const SizedBox(height: 14),
            _buildRequests(),
          ],
          const SizedBox(height: 16),
          InstaWalkSearchButton(
            loading: _loading,
            searching: _searching,
            onPressed: _searchButtonPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildRequests() {
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
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(
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
      children: [
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
          (request) => WalkRequestCard(
            request: request,
            onAccept: () =>
                _acceptRequest(request),
          ),
        ),
      ],
    );
  }
}
