import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/walker_home/containers/walker_home_header.dart';

// ============================================================
// GLOBAL COLORS
// ============================================================

const Color _lightBlue = Color(0xFFBFEAF7);
const Color _lightBlue2 = Color(0xFFA9DFEF);
const Color _buttonBlue = Color(0xFF238EAE);
const Color _radarGreen = Color(0xFF16A34A);
const Color _darkText = Color(0xFF263746);

// ============================================================
// WALKS SCREEN
// ============================================================

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
  // SEARCH STATE
  // ============================================================

  bool _searching = false;
  bool _loading = false;

  String? _walkerUid;

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

    _walkerUid = _auth.currentUser?.uid;

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _dotTimer = Timer.periodic(
      const Duration(seconds: 7),
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
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      final data = snapshot.data();

      if (!mounted) {
        return;
      }

      final bool searching =
          data?['instaWalkSearching'] == true;

      setState(() {
        _searching = searching;
      });

      if (searching) {
        _startRequestListener();
        _moveRadarDot();
      }
    } catch (_) {
      // Firebase unavailable.
    }
  }

  // ============================================================
  // START SEARCH
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
          'instaWalkSearchRadiusKm': 3.5,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searching = true;
        _loading = false;
      });

      _startRequestListener();
      _moveRadarDot();
    } catch (_) {
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
  // FIREBASE REQUEST LISTENER
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

        for (final document in snapshot.docs) {
          final data = document.data();

          final double distance =
              _readDistance(data['distanceKm']);

          if (distance <= 3.5) {
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
              a.distanceKm.compareTo(
            b.distanceKm,
          ),
        );

        setState(() {
          _requests
            ..clear()
            ..addAll(incoming);
        });
      },
      onError: (_) {
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
  // DISTANCE
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

      _showMessage(
        'Walk request accepted successfully.',
      );
    } catch (_) {
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

      if (!mounted) {
        return;
      }

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
  // STOP DIALOG
  // ============================================================

  Future<void> _showStopDialog() async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(.48),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 28,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(.18),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color:
                        _buttonBlue.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: _buttonBlue,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Stop Searching?',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'You will stop receiving nearby Insta Walk requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              false,
                            );
                          },
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor: _darkText,
                            side: const BorderSide(
                              color: Color(0xFFE1E5E9),
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                13,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                _buttonBlue,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                13,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          -.78 + _random.nextDouble() * 1.56;

      _dotY =
          -.65 + _random.nextDouble() * 1.30;

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
            borderRadius:
                BorderRadius.circular(12),
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
                _buildMainContainer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN CONTAINER
  // ============================================================

  Widget _buildMainContainer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        15,
        16,
        10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _lightBlue,
            _lightBlue2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(.78),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 16),

          if (!_searching)
            _buildNormalInfo(),

          if (_searching) ...[
            _buildRadar(),
            const SizedBox(height: 14),
            _buildRequests(),
          ],

          const SizedBox(height: 15),

          _buildSearchButton(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF151A1F),
            Color(0xFF414850),
            Color(0xFF15181C),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(.13),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Insta Walk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Find a walk request nearby',
                  style: TextStyle(
                    color: Color(0xFFD5D9DD),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_searching)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color:
                    _radarGreen.withOpacity(.18),
                borderRadius:
                    BorderRadius.circular(10),
                border: Border.all(
                  color:
                      _radarGreen.withOpacity(.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: _radarGreen,
                    size: 8,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // NORMAL INFO
  // ============================================================

  Widget _buildNormalInfo() {
    return Column(
      children: [
        const Text(
          'Search for available Insta Walk requests within 3.5 kilometre of your service area.',
          style: TextStyle(
            color: Color(0xFF23404D),
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(.52),
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color:
                  Colors.white.withOpacity(.70),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Color(0xFF23404D),
                size: 19,
              ),
              SizedBox(width: 7),
              Text(
                'Search range: 3.5 kilometre',
                style: TextStyle(
                  color: Color(0xFF23404D),
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRO RADAR + MAP
  // ============================================================

  Widget _buildRadar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3E8),
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withOpacity(.9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.10),
            blurRadius: 17,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 2),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration:
                    const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _radarGreen,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'SEARCHING NEARBY',
                style: TextStyle(
                  color: Color(0xFF26352A),
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          SizedBox(
            height: 255,
            width: double.infinity,
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(
                    painter:
                        ProCityMapPainter(),
                  ),

                  AnimatedBuilder(
                    animation:
                        _radarController,
                    builder:
                        (context, child) {
                      return CustomPaint(
                        painter:
                            ProRadarPainter(
                          rotation:
                              _radarController
                                      .value *
                                  math.pi *
                                  2,
                        ),
                      );
                    },
                  ),

                  if (_dotVisible)
                    _RadarDot(
                      x: _dotX,
                      y: _dotY,
                    ),

                  const Center(
                    child:
                        _CenterLocationDot(),
                  ),

                  Positioned(
                    top: 10,
                    left: 10,
                    child: _MapChip(
                      icon:
                          Icons.layers_rounded,
                      text:
                          '3.5 KM AREA',
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: _MapChip(
                      icon:
                          Icons.near_me_rounded,
                      text: 'LIVE',
                    ),
                  ),

                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: _MapChip(
                      icon:
                          Icons.pets_rounded,
                      text:
                          '${_requests.length} REQUEST${_requests.length == 1 ? '' : 'S'}',
                    ),
                  ),

                  Positioned(
                    bottom: 10,
                    right: 10,
                    child:
                        _MapZoomControls(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.radar_rounded,
                color: Color(0xFF35443A),
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                _requests.isEmpty
                    ? 'Searching within 3.5 kilometre'
                    : '${_requests.length} nearby walk request${_requests.length == 1 ? '' : 's'} found',
                style: const TextStyle(
                  color: Color(0xFF35443A),
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REQUESTS
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
                  _radarGreen,
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
              color: Color(0xFF26352A),
              fontSize: 10,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ..._requests.map(
          _buildRequestCard,
        ),
      ],
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(
    WalkRequest request,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE4E8E5),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color:
                  _radarGreen.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: _radarGreen,
              size: 24,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color:
                          Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${request.distanceKm.toStringAsFixed(1)} km',
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                if (request.address
                    .isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    request.address,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF8A9298),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            height: 39,
            child: ElevatedButton(
              onPressed: () =>
                  _acceptRequest(request),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    _radarGreen,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BUTTON
  // ============================================================

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed:
            _loading
                ? null
                : _searchButtonPressed,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              Colors.white,
          foregroundColor:
              _buttonBlue,
          disabledBackgroundColor:
              Colors.white,
          disabledForegroundColor:
              _buttonBlue,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration:
              const Duration(
            milliseconds: 180,
          ),
          child: _loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 21,
                  height: 21,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      _buttonBlue,
                    ),
                  ),
                )
              : _searching
                  ? const Row(
                      key: ValueKey(
                        'searching',
                      ),
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              _buttonBlue,
                            ),
                          ),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Searching Insta Walk',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      key: ValueKey(
                        'normal',
                      ),
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Insta Walk Search',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

// ============================================================
// MAP CHIP
// ============================================================

class _MapChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MapChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(.90),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              Colors.white.withOpacity(.8),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color:
                const Color(0xFF35443A),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color:
                  Color(0xFF35443A),
              fontSize: 8,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAP ZOOM CONTROLS
// ============================================================

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        borderRadius:
            BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.10),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 28,
            child: Icon(
              Icons.add_rounded,
              size: 18,
              color: Color(0xFF35443A),
            ),
          ),
          Divider(
            height: 1,
            thickness: .7,
          ),
          SizedBox(
            width: 30,
            height: 28,
            child: Icon(
              Icons.remove_rounded,
              size: 18,
              color: Color(0xFF35443A),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RADAR DOT
// ============================================================

class _RadarDot extends StatelessWidget {
  final double x;
  final double y;

  const _RadarDot({
    required this.x,
    required this.y,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(x, y),
      child: Container(
        width: 10,
        height: 10,
        decoration:
            BoxDecoration(
          shape: BoxShape.circle,
          color: _radarGreen,
          boxShadow: [
            BoxShadow(
              color:
                  _radarGreen.withOpacity(.75),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CENTER LOCATION
// ============================================================

class _CenterLocationDot
    extends StatelessWidget {
  const _CenterLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration:
          BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: _radarGreen,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.25),
            blurRadius: 7,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration:
              const BoxDecoration(
            shape: BoxShape.circle,
            color: _radarGreen,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRO RADAR PAINTER
// ============================================================

class ProRadarPainter
    extends CustomPainter {
  final double rotation;

  const ProRadarPainter({
    required this.rotation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        math.min(
              size.width,
              size.height,
            ) *
            .44;

    // RADAR RINGS

    final Paint rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color =
          _radarGreen.withOpacity(.30);

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center,
        radius * i / 4,
        rings,
      );
    }

    // CROSS GRID

    final Paint grid = Paint()
      ..color =
          _radarGreen.withOpacity(.20)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(
        center.dx - radius,
        center.dy,
      ),
      Offset(
        center.dx + radius,
        center.dy,
      ),
      grid,
    );

    canvas.drawLine(
      Offset(
        center.dx,
        center.dy - radius,
      ),
      Offset(
        center.dx,
        center.dy + radius,
      ),
      grid,
    );

    // DIAGONAL GRID

    final Paint diagonal = Paint()
      ..color =
          _radarGreen.withOpacity(.10)
      ..strokeWidth = .8;

    canvas.drawLine(
      Offset(
        center.dx - radius,
        center.dy - radius,
      ),
      Offset(
        center.dx + radius,
        center.dy + radius,
      ),
      diagonal,
    );

    canvas.drawLine(
      Offset(
        center.dx + radius,
        center.dy - radius,
      ),
      Offset(
        center.dx - radius,
        center.dy + radius,
      ),
      diagonal,
    );

    // ROTATING SWEEP

    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(rotation);

    final Path sweep = Path()
      ..moveTo(0, 0)
      ..lineTo(radius, 0)
      ..arcTo(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius,
        ),
        0,
        math.pi / 5,
        false,
      )
      ..close();

    final Paint sweepPaint = Paint()
      ..shader =
          const LinearGradient(
        colors: [
          Color(0x7016A34A),
          Color(0x3016A34A),
          Color(0x0016A34A),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius,
        ),
      );

    canvas.drawPath(
      sweep,
      sweepPaint,
    );

    final Paint sweepLine = Paint()
      ..color =
          _radarGreen.withOpacity(.95)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset.zero,
      Offset(radius, 0),
      sweepLine,
    );

    canvas.restore();

    // OUTER CIRCLE

    final Paint outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color =
          _radarGreen.withOpacity(.45);

    canvas.drawCircle(
      center,
      radius,
      outer,
    );
  }

  @override
  bool shouldRepaint(
    covariant ProRadarPainter oldDelegate,
  ) {
    return oldDelegate.rotation != rotation;
  }
}

// ============================================================
// PRO CITY MAP
// ============================================================

class ProCityMapPainter
    extends CustomPainter {
  const ProCityMapPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // BASE

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color =
            const Color(0xFFEAF2E7),
    );

    // RIVER

    final Path river = Path()
      ..moveTo(
        size.width * .82,
        -20,
      )
      ..cubicTo(
        size.width * .68,
        size.height * .18,
        size.width * .91,
        size.height * .38,
        size.width * .73,
        size.height * .58,
      )
      ..cubicTo(
        size.width * .58,
        size.height * .76,
        size.width * .78,
        size.height * .91,
        size.width * .65,
        size.height + 20,
      )
      ..lineTo(
        size.width * .82,
        size.height + 20,
      )
      ..cubicTo(
        size.width * .92,
        size.height * .90,
        size.width * .75,
        size.height * .76,
        size.width * .88,
        size.height * .56,
      )
      ..cubicTo(
        size.width + .02,
        size.height * .35,
        size.width * .78,
        size.height * .17,
        size.width * .94,
        -20,
      )
      ..close();

    canvas.drawPath(
      river,
      Paint()
        ..color =
            const Color(0xFFC9E7EC),
    );

    // PARKS

    final Paint park = Paint()
      ..color =
          const Color(0xFFCDE6C8);

    final List<Rect> parks = [
      Rect.fromLTWH(
        size.width * .03,
        size.height * .06,
        size.width * .22,
        size.height * .18,
      ),
      Rect.fromLTWH(
        size.width * .62,
        size.height * .04,
        size.width * .18,
        size.height * .15,
      ),
      Rect.fromLTWH(
        size.width * .05,
        size.height * .70,
        size.width * .22,
        size.height * .19,
      ),
      Rect.fromLTWH(
        size.width * .62,
        size.height * .72,
        size.width * .20,
        size.height * .17,
      ),
    ];

    for (final Rect rect in parks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(10),
        ),
        park,
      );
    }

    // MAIN ROADS

    final Paint mainRoad = Paint()
      ..color =
          const Color(0xFFD1D5D6)
      ..strokeWidth = 17
      ..style =
          PaintingStyle.stroke;

    final Path road1 = Path()
      ..moveTo(
        -20,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .22,
        size.height * .35,
        size.width * .53,
        size.height * .55,
        size.width + 20,
        size.height * .39,
      );

    final Path road2 = Path()
      ..moveTo(
        size.width * .43,
        -20,
      )
      ..cubicTo(
        size.width * .38,
        size.height * .30,
        size.width * .58,
        size.height * .66,
        size.width * .48,
        size.height + 20,
      );

    canvas.drawPath(
      road1,
      mainRoad,
    );

    canvas.drawPath(
      road2,
      mainRoad,
    );

    // ROAD CENTER

    final Paint roadLine = Paint()
      ..color =
          Colors.white.withOpacity(.85)
      ..strokeWidth = 1.5
      ..style =
          PaintingStyle.stroke;

    canvas.drawPath(
      road1,
      roadLine,
    );

    canvas.drawPath(
      road2,
      roadLine,
    );

    // SMALL STREETS

    final Paint smallRoad = Paint()
      ..color =
          const Color(0xFFDCE1E1)
      ..strokeWidth = 4
      ..style =
          PaintingStyle.stroke;

    for (int i = 1; i < 9; i++) {
      final double y =
          size.height * i / 9;

      canvas.drawLine(
        Offset(0, y),
        Offset(
          size.width,
          y + (i.isEven ? 8 : -6),
        ),
        smallRoad,
      );
    }

    for (int i = 1; i < 8; i++) {
      final double x =
          size.width * i / 8;

      canvas.drawLine(
        Offset(x, 0),
        Offset(
          x + (i.isEven ? 8 : -6),
          size.height,
        ),
        smallRoad,
      );
    }

    // BUILDINGS

    final Paint building = Paint()
      ..color =
          const Color(0xFFFDFDFB);

    final Paint building2 = Paint()
      ..color =
          const Color(0xFFE3E7E4);

    final math.Random random =
        math.Random(27);

    for (int i = 0; i < 42; i++) {
      final double x =
          size.width *
              (.03 +
                  random.nextDouble() *
                      .88);

      final double y =
          size.height *
              (.04 +
                  random.nextDouble() *
                      .88);

      final double w =
          8 +
          random.nextDouble() * 10;

      final double h =
          5 +
          random.nextDouble() * 8;

      final Rect rect =
          Rect.fromLTWH(
        x,
        y,
        w,
        h,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(2),
        ),
        i.isEven
            ? building
            : building2,
      );
    }

    // TREES

    final Paint tree = Paint()
      ..color =
          const Color(0xFF69A96E);

    final List<Offset> treePoints = [
      Offset(
        size.width * .11,
        size.height * .14,
      ),
      Offset(
        size.width * .16,
        size.height * .18,
      ),
      Offset(
        size.width * .22,
        size.height * .12,
      ),
      Offset(
        size.width * .12,
        size.height * .80,
      ),
      Offset(
        size.width * .20,
        size.height * .84,
      ),
      Offset(
        size.width * .73,
        size.height * .12,
      ),
      Offset(
        size.width * .78,
        size.height * .17,
      ),
      Offset(
        size.width * .72,
        size.height * .81,
      ),
      Offset(
        size.width * .80,
        size.height * .84,
      ),
    ];

    for (final Offset point in treePoints) {
      canvas.drawCircle(
        point,
        4,
        tree,
      );

      final Paint treeBorder = Paint()
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 1
        ..color =
            const Color(0xFF69A96E)
                .withOpacity(.35);

      canvas.drawCircle(
        point,
        6,
        treeBorder,
      );
    }

    // BLOCK BORDERS

    final Paint block = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = .7
      ..color =
          const Color(0xFFCAD3CD)
              .withOpacity(.65);

    for (int i = 0; i < 12; i++) {
      final double x =
          size.width * i / 12;

      canvas.drawLine(
        Offset(x, 0),
        Offset(
          x + 15,
          size.height,
        ),
        block,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant ProCityMapPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================
// WALK REQUEST MODEL
// ============================================================

class WalkRequest {
  final String id;
  final String ownerUid;
  final String address;
  final String status;
  final double distanceKm;

  const WalkRequest({
    required this.id,
    required this.ownerUid,
    required this.address,
    required this.status,
    required this.distanceKm,
  });

  String get title => 'Insta Walk Request';

  factory WalkRequest.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final dynamic distance =
        data['distanceKm'];

    final double distanceKm =
        distance is num
            ? distance.toDouble()
            : double.tryParse(
                  distance?.toString() ?? '',
                ) ??
                0;

    return WalkRequest(
      id: id,
      ownerUid:
          data['ownerUid']?.toString() ?? '',
      address:
          data['address']?.toString() ?? '',
      status:
          data['status']?.toString() ??
              'searching',
      distanceKm: distanceKm,
    );
  }
}
