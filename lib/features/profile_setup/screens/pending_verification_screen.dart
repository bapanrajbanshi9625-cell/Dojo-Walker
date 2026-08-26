import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../screens/main_navigation_screen.dart';
import '../../../screens/mobile_login_screen.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

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
  // REALTIME VERIFICATION LISTENER
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
      '================================================',
    );
    debugPrint(
      'PendingVerification: START LISTENER',
    );
    debugPrint(
      'PendingVerification: collection = walkers',
    );
    debugPrint(
      'PendingVerification: document = $uid',
    );
    debugPrint(
      '================================================',
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
  // HANDLE WALKER SNAPSHOT
  // ============================================================

  void _handleWalkerSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!mounted) {
      return;
    }

    debugPrint(
      'PendingVerification: Firestore snapshot received.',
    );

    // ==========================================================
    // DOCUMENT NOT FOUND
    // ==========================================================

    if (!snapshot.exists) {
      debugPrint(
        'PendingVerification: walkers/'
        '${FirebaseAuth.instance.currentUser?.uid} '
        'DOES NOT EXIST.',
      );

      setState(() {
        verificationStatus = 'pending';
        walkerIdActive = false;
      });

      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    debugPrint(
      'PendingVerification: walkers document data = $data',
    );

    // ==========================================================
    // STATUS
    // ==========================================================

    final String status =
        _readVerificationStatus(data);

    // ==========================================================
    // ACTIVE
    // ==========================================================

    final bool active =
        _readWalkerActive(data);

    debugPrint(
      '------------------------------------------------',
    );
    debugPrint(
      'PendingVerification:',
    );
    debugPrint(
      'status = $status',
    );
    debugPrint(
      'walkerIdActive = $active',
    );
    debugPrint(
      '------------------------------------------------',
    );

    setState(() {
      verificationStatus = status;
      walkerIdActive = active;
    });

    // ==========================================================
    // APPROVED
    // ==========================================================

    if (_isApprovedState(
      data,
      status,
      active,
    )) {
      debugPrint(
        'PendingVerification: APPROVED detected.',
      );

      _openMainNavigation();

      return;
    }

    // ==========================================================
    // REJECTED
    // ==========================================================

    if (status == 'rejected') {
      debugPrint(
        'PendingVerification: REJECTED detected.',
      );

      _handleRejected();

      return;
    }

    // ==========================================================
    // PENDING
    // ==========================================================

    debugPrint(
      'PendingVerification: Still pending.',
    );
  }

  // ============================================================
  // READ VERIFICATION STATUS
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
  // READ WALKER ACTIVE
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
  // SAFE BOOLEAN
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
  // APPROVAL STATE
  // ============================================================

  bool _isApprovedState(
    Map<String, dynamic> data,
    String status,
    bool active,
  ) {
    if (status == 'approved' && active) {
      return true;
    }

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
  // OPEN MAIN NAVIGATION
  // ============================================================

  void _openMainNavigation() {
    if (!mounted || _openingMain) {
      return;
    }

    _openingMain = true;

    debugPrint(
      'PendingVerification: '
      'Opening MainNavigationScreen.',
    );

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
  // HANDLE REJECTED
  // ============================================================

  void _handleRejected() {
    if (!mounted ||
        _openingMain ||
        _handlingRejected) {
      return;
    }

    _handlingRejected = true;

    debugPrint(
      'PendingVerification: '
      'Walker verification REJECTED.',
    );

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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _verificationSubscription?.cancel();
    _verificationSubscription = null;

    _animationController.dispose();

    super.dispose();
  }

  // ============================================================
  // CURRENT STATE
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
        appBar: _appBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              30,
            ),
            child: Column(
              children: [
                _verificationIcon(),

                const SizedBox(
                  height: 24,
                ),

                Text(
                  _pageTitle(),
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.15,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  _pageSubtitle(),
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color:
                        AppColors.muted,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                _mainStatusCard(),

                const SizedBox(
                  height: 16,
                ),

                _statusCard(),

                const SizedBox(
                  height: 16,
                ),

                _nextStepCard(),

                const SizedBox(
                  height: 16,
                ),

                if (!isApproved)
                  _lockedCard(),

                if (!isApproved)
                  const SizedBox(
                    height: 18,
                  ),

                _supportButton(),

                const SizedBox(
                  height: 25,
                ),

                const Text(
                  'DOJO Platform',
                  style: TextStyle(
                    color:
                        AppColors.orange,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Trusted walks. Happy dogs. 🐾',
                  style: TextStyle(
                    color:
                        AppColors.muted
                            .withOpacity(.75),
                    fontSize: 11,
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
  // PAGE TITLE
  // ============================================================

  String _pageTitle() {
    if (isApproved) {
      return 'Verification Approved';
    }

    if (isRejected) {
      return 'Verification Needs Attention';
    }

    return 'Verification Pending';
  }

  // ============================================================
  // PAGE SUBTITLE
  // ============================================================

  String _pageSubtitle() {
    if (isApproved) {
      return 'Your DOJO Walker account is now active.';
    }

    if (isRejected) {
      return 'Please contact DOJO Platform support for more information.';
    }

    return 'Your profile has been submitted successfully. '
        'We are reviewing your information.';
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _appBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      titleSpacing: 18,
      title: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color:
                  AppColors.orange,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

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
              SizedBox(
                height: 2,
              ),
              Text(
                'DOJO Walker',
                style: TextStyle(
                  fontSize: 11,
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
  // ANIMATED VERIFICATION ICON
  // ============================================================

  Widget _verificationIcon() {
    final Color iconColor =
        isApproved
            ? AppColors.green
            : isRejected
                ? AppColors.red
                : AppColors.blue;

    final Color outerColor =
        isApproved
            ? AppColors.green
                .withOpacity(.10)
            : isRejected
                ? AppColors.red
                    .withOpacity(.10)
                : AppColors.blue
                    .withOpacity(.10);

    // ==========================================================
    // APPROVED
    // ==========================================================

    if (isApproved) {
      return _staticVerificationIcon(
        iconColor: iconColor,
        outerColor: outerColor,
        icon: Icons.check_rounded,
      );
    }

    // ==========================================================
    // REJECTED
    // ==========================================================

    if (isRejected) {
      return _staticVerificationIcon(
        iconColor: iconColor,
        outerColor: outerColor,
        icon: Icons.close_rounded,
      );
    }

    // ==========================================================
    // PENDING ANIMATION
    // ==========================================================

    return AnimatedBuilder(
      animation:
          _animationController,
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        final double progress =
            _pulseAnimation.value;

        final double ringSize =
            135 + (progress * 35);

        final double ringOpacity =
            (1.0 - progress) * .28;

        return SizedBox(
          width: 175,
          height: 175,
          child: Stack(
            alignment:
                Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration:
                    BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor
                        .withOpacity(
                      ringOpacity,
                    ),
                    width: 3,
                  ),
                ),
              ),

              Container(
                width: 145,
                height: 145,
                decoration:
                    BoxDecoration(
                  shape: BoxShape.circle,
                  color: outerColor,
                  border: Border.all(
                    color: iconColor
                        .withOpacity(.12),
                    width: 6,
                  ),
                ),
              ),

              Transform.scale(
                scale:
                    _scaleAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color: iconColor,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor
                            .withOpacity(
                          .22,
                        ),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child:
                      const Icon(
                    Icons
                        .verified_user_rounded,
                    color:
                        Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // STATIC VERIFICATION ICON
  // ============================================================

  Widget _staticVerificationIcon({
    required Color iconColor,
    required Color outerColor,
    required IconData icon,
  }) {
    return Container(
      width: 135,
      height: 135,
      decoration:
          BoxDecoration(
        shape: BoxShape.circle,
        color: outerColor,
        border: Border.all(
          color:
              iconColor.withOpacity(.15),
          width: 7,
        ),
      ),
      child: Container(
        margin:
            const EdgeInsets.all(17),
        decoration:
            BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor,
          boxShadow: [
            BoxShadow(
              color:
                  iconColor.withOpacity(.18),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 52,
        ),
      ),
    );
  }

  // ============================================================
  // MAIN STATUS CARD
  // ============================================================

  Widget _mainStatusCard() {
    final bool approved =
        isApproved;

    final bool rejected =
        isRejected;

    final Color cardColor =
        approved
            ? AppColors.green
            : rejected
                ? AppColors.red
                : AppColors.blue;

    final Color lightColor =
        cardColor.withOpacity(.08);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              cardColor.withOpacity(.12),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.035),
            blurRadius: 18,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration:
                    BoxDecoration(
                  color: lightColor,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  approved
                      ? Icons
                          .verified_rounded
                      : rejected
                          ? Icons
                              .error_outline_rounded
                          : Icons
                              .verified_user_rounded,
                  color: cardColor,
                  size: 27,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      approved
                          ? 'DOJO Platform Verification Approved'
                          : rejected
                              ? 'Verification Requires Attention'
                              : 'Waiting for DOJO Platform Verification',
                      style:
                          const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            AppColors.textDark,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      approved
                          ? 'Your Walker account is active.'
                          : rejected
                              ? 'Please contact support.'
                              : 'Verification is currently in progress.',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 17,
          ),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              color: lightColor,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Icon(
                  approved
                      ? Icons
                          .check_circle_outline_rounded
                      : rejected
                          ? Icons
                              .error_outline_rounded
                          : Icons
                              .info_outline_rounded,
                  color: cardColor,
                  size: 20,
                ),

                const SizedBox(
                  width: 9,
                ),

                Expanded(
                  child: Text(
                    approved
                        ? 'Your profile has been approved by DOJO Platform. Walker ID activation is complete.'
                        : rejected
                            ? 'Your submitted profile needs attention. Please contact DOJO Platform support.'
                            : 'DOJO Platform is verifying your profile and submitted documents. Please wait for verification to complete.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color:
                          cardColor.withOpacity(.80),
                      fontWeight:
                          FontWeight.w600,
                    ),
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
  // STATUS CARD
  // ============================================================

  Widget _statusCard() {
    final bool approved =
        isApproved;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
              color:
                  AppColors.textDark,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          _step(
            icon:
                Icons.check_circle_rounded,
            color:
                AppColors.green,
            title:
                'Profile Submitted',
            subtitle:
                'Completed successfully',
          ),

          _line(),

          _step(
            icon: approved
                ? Icons
                    .check_circle_rounded
                : isRejected
                    ? Icons
                        .error_rounded
                    : Icons
                        .verified_user_rounded,
            color: approved
                ? AppColors.green
                : isRejected
                    ? AppColors.red
                    : AppColors.blue,
            title:
                'DOJO Platform Verification',
            subtitle: approved
                ? 'Verification approved'
                : isRejected
                    ? 'Verification requires attention'
                    : 'Waiting for DOJO Platform verification',
            animated:
                isPending,
          ),

          _line(),

          _step(
            icon: approved
                ? Icons
                    .check_circle_rounded
                : Icons.lock_rounded,
            color: approved
                ? AppColors.green
                : AppColors.muted,
            title:
                'Walker ID Activation',
            subtitle: approved
                ? 'Walker ID is active'
                : 'Waiting for DOJO Platform approval',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP
  // ============================================================

  Widget _step({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool animated = false,
  }) {
    Widget iconWidget =
        Container(
      width: 43,
      height: 43,
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );

    if (animated) {
      iconWidget =
          AnimatedBuilder(
        animation:
            _animationController,
        builder: (
          BuildContext context,
          Widget? child,
        ) {
          return Transform.scale(
            scale:
                0.94 +
                    (_animationController
                            .value *
                        .10),
            child:
                iconWidget,
          );
        },
      );
    }

    return Row(
      children: [
        iconWidget,

        const SizedBox(
          width: 13,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      AppColors.textDark,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                style:
                    TextStyle(
                  fontSize: 11.5,
                  color: color,
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
  // LINE
  // ============================================================

  Widget _line() {
    return Container(
      margin:
          const EdgeInsets.only(
        left: 20,
        top: 3,
        bottom: 3,
      ),
      width: 2,
      height: 22,
      color:
          AppColors.border,
    );
  }

  // ============================================================
  // NEXT STEP CARD
  // ============================================================

  Widget _nextStepCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(19),
      decoration:
          BoxDecoration(
        color:
            AppColors.orange.withOpacity(.05),
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color:
              AppColors.orange.withOpacity(.10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .lightbulb_outline_rounded,
                color:
                    AppColors.orange,
              ),
              SizedBox(
                width: 9,
              ),
              Text(
                'What happens next?',
                style:
                    TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      AppColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          _nextLine(
            'Your profile has been submitted.',
            true,
          ),

          _nextLine(
            'DOJO Platform will verify your information.',
            isApproved,
          ),

          _nextLine(
            'Your Walker ID will activate after approval.',
            isApproved,
          ),

          _nextLine(
            'You can then enter the DOJO Walker app.',
            isApproved,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEXT LINE
  // ============================================================

  Widget _nextLine(
    String text,
    bool completed,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 3,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            completed
                ? '✓ '
                : '• ',
            style:
                TextStyle(
              fontSize: 12.5,
              color: completed
                  ? AppColors.green
                  : AppColors.muted,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(
                fontSize: 12.5,
                height: 1.7,
                color:
                    AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCKED CARD
  // ============================================================

  Widget _lockedCard() {
    final bool rejected =
        isRejected;

    final Color color =
        rejected
            ? AppColors.red
            : AppColors.orange;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.07),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              color.withOpacity(.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            rejected
                ? Icons
                    .error_outline_rounded
                : Icons
                    .lock_outline_rounded,
            color: color,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              rejected
                  ? 'Walker account needs verification attention. Please contact DOJO Platform support.'
                  : 'Walker account is locked until DOJO Platform verification is completed.',
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.45,
                color:
                    color.withOpacity(.85),
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUPPORT BUTTON
  // ============================================================

  Widget _supportButton() {
    return OutlinedButton.icon(
      onPressed: _showSupport,
      style:
          OutlinedButton.styleFrom(
        minimumSize:
            const Size(
          double.infinity,
          52,
        ),
        foregroundColor:
            AppColors.blue,
        side: BorderSide(
          color:
              AppColors.blue
                  .withOpacity(.25),
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),
      icon: const Icon(
        Icons.support_agent_rounded,
      ),
      label: const Text(
        'Need Help? Contact Support',
        style: TextStyle(
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // SUPPORT SHEET
  // ============================================================

  void _showSupport() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons
                      .support_agent_rounded,
                  color:
                      AppColors.blue,
                  size: 45,
                ),

                const SizedBox(
                  height: 12,
                ),

                const Text(
                  'DOJO Support',
                  style:
                      TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Need help with your verification? Our support team is here to help.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color:
                        AppColors.muted,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 50,
                  child:
                      FilledButton.icon(
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          AppColors.blue,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .chat_rounded,
                    ),
                    label:
                        const Text(
                      'Open Support Chat',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
