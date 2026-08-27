import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../screens/main_navigation_screen.dart';
import '../../../screens/mobile_login_screen.dart';
import '../widgets/pending_verification_content.dart';
import '../widgets/pending_verification_support.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({
    super.key,
  });

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState
    extends State<PendingVerificationScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // FIREBASE
  // ============================================================

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _verificationSubscription;

  // ============================================================
  // ANIMATION
  // ============================================================

  late final AnimationController _animationController;

  late final Animation<double> _pulseAnimation;

  late final Animation<double> _scaleAnimation;

  // ============================================================
  // STATE
  // ============================================================

  String verificationStatus = 'pending';

  bool walkerIdActive = false;

  bool _openingMain = false;

  bool _handlingRejected = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat();

    _listenForVerification();
  }

  // ============================================================
  // FIRESTORE LISTENER
  // ============================================================

  void _listenForVerification() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        'PendingVerification: Firebase user is null.',
      );
      return;
    }

    final String uid = user.uid;

    debugPrint(
      'PendingVerification: listening walkers/$uid',
    );

    _verificationSubscription?.cancel();

    _verificationSubscription =
        FirebaseFirestore.instance
            .collection('walkers')
            .doc(uid)
            .snapshots()
            .listen(
      _handleWalkerSnapshot,
      onError: (Object error) {
        debugPrint(
          'PendingVerification listener error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // SNAPSHOT
  // ============================================================

  void _handleWalkerSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!mounted) {
      return;
    }

    if (!snapshot.exists) {
      debugPrint(
        'PendingVerification: walkers document missing.',
      );

      setState(() {
        verificationStatus = 'pending';
        walkerIdActive = false;
      });

      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    final String status =
        _readVerificationStatus(data);

    final bool active =
        _readWalkerActive(data);

    debugPrint(
      'PendingVerification status=$status active=$active',
    );

    setState(() {
      verificationStatus = status;
      walkerIdActive = active;
    });

    // ----------------------------------------------------------
    // APPROVED
    // ----------------------------------------------------------

    if (_isApprovedState(
      data,
      status,
      active,
    )) {
      _openMainNavigation();
      return;
    }

    // ----------------------------------------------------------
    // REJECTED
    // ----------------------------------------------------------

    if (status == 'rejected') {
      _handleRejected();
      return;
    }
  }

  // ============================================================
  // READ STATUS
  // ============================================================

  String _readVerificationStatus(
    Map<String, dynamic> data,
  ) {
    const List<String> keys = <String>[
      'verificationStatus',
      'verification_status',
      'approvalStatus',
      'approval_status',
      'status',
      'Status',
    ];

    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String normalized =
          value.toString().trim().toLowerCase();

      if (normalized.isEmpty ||
          normalized == 'null') {
        continue;
      }

      if (normalized.contains('approve') ||
          normalized.contains('verified') ||
          normalized.contains('accepted')) {
        return 'approved';
      }

      if (normalized.contains('reject') ||
          normalized.contains('blocked') ||
          normalized.contains('suspend')) {
        return 'rejected';
      }

      if (normalized.contains('pending') ||
          normalized.contains('review') ||
          normalized.contains('waiting')) {
        return 'pending';
      }

      return normalized;
    }

    if (_readBool(
      data,
      'approved',
    )) {
      return 'approved';
    }

    if (_readBool(
      data,
      'rejected',
    )) {
      return 'rejected';
    }

    return 'pending';
  }

  // ============================================================
  // READ ACTIVE
  // ============================================================

  bool _readWalkerActive(
    Map<String, dynamic> data,
  ) {
    const List<String> keys = <String>[
      'walkerIdActive',
      'walker_id_active',
      'active',
      'isActive',
      'is_active',
    ];

    for (final String key in keys) {
      if (data.containsKey(key)) {
        return _readBool(
          data,
          key,
        );
      }
    }

    if (_readBool(
      data,
      'approved',
    )) {
      return true;
    }

    return false;
  }

  // ============================================================
  // SAFE BOOL
  // ============================================================

  bool _readBool(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic value = data[key];

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final String normalized =
          value.trim().toLowerCase();

      return normalized == 'true' ||
          normalized == 'yes' ||
          normalized == '1' ||
          normalized == 'active' ||
          normalized == 'approved';
    }

    return false;
  }

  // ============================================================
  // APPROVAL
  // ============================================================

  bool _isApprovedState(
    Map<String, dynamic> data,
    String status,
    bool active,
  ) {
    if (status == 'approved') {
      return true;
    }

    if (_readBool(
      data,
      'approved',
    )) {
      return true;
    }

    if (active &&
        (status == 'verified' ||
            status == 'accepted' ||
            status == 'active')) {
      return true;
    }

    return false;
  }

  // ============================================================
  // OPEN MAIN
  // ============================================================

  void _openMainNavigation() {
    if (!mounted || _openingMain) {
      return;
    }

    _openingMain = true;

    _verificationSubscription?.cancel();
    _verificationSubscription = null;

    _animationController.stop();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) =>
                const MainNavigationScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      },
    );
  }

  // ============================================================
  // REJECTED
  // ============================================================

  void _handleRejected() {
    if (!mounted ||
        _openingMain ||
        _handlingRejected) {
      return;
    }

    _handlingRejected = true;

    _verificationSubscription?.cancel();
    _verificationSubscription = null;

    _animationController.stop();

    Future<void>.delayed(
      const Duration(
        seconds: 3,
      ),
      () async {
        if (!mounted) {
          return;
        }

        try {
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          debugPrint(
            'Rejected logout error: $e',
          );
        }

        if (!mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) =>
                const MobileLoginScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      },
    );
  }

  // ============================================================
  // STATE HELPERS
  // ============================================================

  bool get isApproved =>
      verificationStatus == 'approved';

  bool get isRejected =>
      verificationStatus == 'rejected';

  bool get isPending =>
      verificationStatus == 'pending';

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            AppColors.background,

        appBar: _buildAppBar(),

        body: SafeArea(
          child: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              return SingleChildScrollView(
                primary: true,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 40,
                ),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                            32,
                  ),
                  child: PendingVerificationContent(
                    isApproved:
                        isApproved,
                    isRejected:
                        isRejected,
                    isPending:
                        isPending,
                    verificationStatus:
                        verificationStatus,
                    walkerIdActive:
                        walkerIdActive,
                    animationController:
                        _animationController,
                    pulseAnimation:
                        _pulseAnimation,
                    scaleAnimation:
                        _scaleAnimation,
                    onSupport:
                        _showSupport,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      toolbarHeight: 68,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: AppColors.orange,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 10),

          const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'DOJO Platform',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      AppColors.textDark,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'DOJO Walker',
                style: TextStyle(
                  fontSize: 10.5,
                  color:
                      AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  void _showSupport() {
    showPendingVerificationSupport(
      context,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _verificationSubscription?.cancel();

    _verificationSubscription = null;

    _animationController.dispose();

    super.dispose();
  }
}
