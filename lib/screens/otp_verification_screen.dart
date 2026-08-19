import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../screens/main_navigation_screen.dart';
import '../../../screens/mobile_login_screen.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState
    extends State<PendingVerificationScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF6600);
  static const Color blue = Color(0xFF1976D2);
  static const Color green = Color(0xFF22A447);
  static const Color red = Color(0xFFD92D20);

  static const Color background = Color(0xFFF6F8FC);
  static const Color textDark = Color(0xFF17202A);
  static const Color muted = Color(0xFF667085);

  // ============================================================
  // FIREBASE
  // ============================================================

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _verificationSubscription;

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

    _listenForVerification();
  }

  // ============================================================
  // REALTIME VERIFICATION LISTENER
  // ============================================================

  void _listenForVerification() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        'PendingVerification: Firebase user is null.',
      );
      return;
    }

    final String uid = user.uid;

    debugPrint(
      'PendingVerification: Listening to walkers/$uid',
    );

    _verificationSubscription = FirebaseFirestore.instance
        .collection('walkers')
        .doc(uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) {
          return;
        }

        if (!snapshot.exists) {
          debugPrint(
            'PendingVerification: walkers/$uid does not exist.',
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
          'PendingVerification: Firestore data = $data',
        );

        // ========================================================
        // READ VERIFICATION STATUS
        // ========================================================

        final String status = _readVerificationStatus(data);

        // ========================================================
        // READ ACTIVE STATE
        // ========================================================

        final bool active = _readWalkerActive(data);

        // ========================================================
        // DEBUG
        // ========================================================

        debugPrint(
          'PendingVerification: '
          'status=$status, '
          'walkerIdActive=$active',
        );

        setState(() {
          verificationStatus = status;
          walkerIdActive = active;
        });

        // ========================================================
        // APPROVED
        //
        // IMPORTANT:
        // Approved verification is enough to enter the app.
        //
        // If admin already activated the Walker ID, active=true
        // is accepted.
        //
        // If your Admin app only changes approval status and does
        // not write walkerIdActive, we still allow approved users
        // to continue.
        // ========================================================

        if (status == 'approved') {
          _openMainNavigation();
          return;
        }

        // ========================================================
        // REJECTED
        // ========================================================

        if (status == 'rejected') {
          _handleRejected();
          return;
        }
      },
      onError: (Object error) {
        debugPrint(
          'PendingVerification listener error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // READ VERIFICATION STATUS
  // ============================================================

  String _readVerificationStatus(
    Map<String, dynamic> data,
  ) {
    const List<String> statusKeys = <String>[
      'verificationStatus',
      'verification_status',
      'approvalStatus',
      'approval_status',
      'status',
      'Status',
    ];

    for (final String key in statusKeys) {
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

      // Approved
      if (normalized.contains('approve') ||
          normalized.contains('approved') ||
          normalized.contains('verify') ||
          normalized.contains('verified') ||
          normalized.contains('accept') ||
          normalized.contains('accepted') ||
          normalized == 'active') {
        return 'approved';
      }

      // Rejected
      if (normalized.contains('reject') ||
          normalized.contains('rejected') ||
          normalized.contains('block') ||
          normalized.contains('blocked') ||
          normalized.contains('suspend') ||
          normalized.contains('suspended')) {
        return 'rejected';
      }

      // Pending
      if (normalized.contains('pending') ||
          normalized.contains('review') ||
          normalized.contains('waiting') ||
          normalized.contains('submitted')) {
        return 'pending';
      }
    }

    // ============================================================
    // BOOLEAN FALLBACKS
    // ============================================================

    if (_readBool(
      data,
      'approved',
    )) {
      return 'approved';
    }

    if (_readBool(
      data,
      'verified',
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
  // READ WALKER ACTIVE STATE
  // ============================================================

  bool _readWalkerActive(
    Map<String, dynamic> data,
  ) {
    const List<String> activeKeys = <String>[
      'walkerIdActive',
      'walker_id_active',
      'active',
      'isActive',
      'is_active',
      'accountActive',
      'account_active',
    ];

    for (final String key in activeKeys) {
      if (_readBool(data, key)) {
        return true;
      }
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
  // OPEN MAIN NAVIGATION
  // ============================================================

  void _openMainNavigation() {
    if (!mounted || _openingMain) {
      return;
    }

    _openingMain = true;

    debugPrint(
      'PendingVerification: APPROVED → opening MainNavigationScreen',
    );

    _verificationSubscription?.cancel();
    _verificationSubscription = null;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                const MainNavigationScreen(),
          ),
          (route) => false,
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
      'PendingVerification: Walker verification REJECTED',
    );

    _verificationSubscription?.cancel();
    _verificationSubscription = null;

    Future<void>.delayed(
      const Duration(seconds: 3),
      () async {
        if (!mounted) {
          return;
        }

        try {
          await FirebaseAuth.instance.signOut();
        } catch (error) {
          debugPrint(
            'Rejected logout error: $error',
          );
        }

        if (!mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                const MobileLoginScreen(),
          ),
          (route) => false,
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
        backgroundColor: background,
        appBar: _appBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              24,
              18,
              30,
            ),
            child: Column(
              children: [
                _verificationIcon(),

                const SizedBox(height: 25),

                Text(
                  _pageTitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  _pageSubtitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: muted,
                  ),
                ),

                const SizedBox(height: 24),

                _mainStatusCard(),

                const SizedBox(height: 18),

                _statusCard(),

                const SizedBox(height: 18),

                _nextStepCard(),

                const SizedBox(height: 18),

                if (!isApproved)
                  _lockedCard(),

                const SizedBox(height: 20),

                _supportButton(),

                const SizedBox(height: 25),

                const Text(
                  'DOJO Platform',
                  style: TextStyle(
                    color: orange,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Trusted walks. Happy dogs. 🐾',
                  style: TextStyle(
                    color: Color(0xFF98A0AA),
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

    return 'Your profile has been submitted successfully.';
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
              color: orange,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 11),

          const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'DOJO Platform',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'DOJO Walker',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7A8491),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFICATION ICON
  // ============================================================

  Widget _verificationIcon() {
    final Color iconColor = isApproved
        ? green
        : isRejected
            ? red
            : blue;

    final Color outerColor = isApproved
        ? const Color(0xFFEAF8EE)
        : isRejected
            ? const Color(0xFFFFEEEE)
            : const Color(0xFFEAF3FF);

    return Container(
      width: 135,
      height: 135,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outerColor,
        border: Border.all(
          color: iconColor.withOpacity(.15),
          width: 7,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor,
        ),
        child: Icon(
          isApproved
              ? Icons.check_rounded
              : isRejected
                  ? Icons.close_rounded
                  : Icons.verified_user_rounded,
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
    final bool approved = isApproved;
    final bool rejected = isRejected;

    final Color cardColor = approved
        ? green
        : rejected
            ? red
            : blue;

    final Color lightColor = approved
        ? const Color(0xFFEAF8EE)
        : rejected
            ? const Color(0xFFFFEEEE)
            : const Color(0xFFEAF3FF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: cardColor.withOpacity(.12),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.04),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  approved
                      ? Icons.verified_rounded
                      : rejected
                          ? Icons.error_outline_rounded
                          : Icons.verified_user_rounded,
                  color: cardColor,
                  size: 27,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      approved
                          ? 'DOJO Platform Verification Approved'
                          : rejected
                              ? 'Verification Requires Attention'
                              : 'Waiting for DOJO Platform Verification',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      approved
                          ? 'Your Walker account is active.'
                          : rejected
                              ? 'Please contact support.'
                              : 'Verification is currently in progress.',
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF7A8491),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  approved
                      ? Icons.check_circle_outline_rounded
                      : rejected
                          ? Icons.error_outline_rounded
                          : Icons.info_outline_rounded,
                  color: cardColor,
                  size: 20,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    approved
                        ? 'Your profile has been approved by DOJO Platform. You can now enter the Walker app.'
                        : rejected
                            ? 'Your submitted profile needs attention. Please contact DOJO Platform support.'
                            : 'DOJO Platform is verifying your profile and submitted documents. Please wait for verification to complete.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: approved
                          ? const Color(
                              0xFF315C3C,
                            )
                          : rejected
                              ? const Color(
                                  0xFF7A3030,
                                )
                              : const Color(
                                  0xFF34506E,
                                ),
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
    final bool approved = isApproved;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
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
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 20),

          _step(
            icon:
                Icons.check_circle_rounded,
            color: green,
            title:
                'Profile Submitted',
            subtitle:
                'Completed successfully',
          ),

          _line(),

          _step(
            icon: approved
                ? Icons.check_circle_rounded
                : isRejected
                    ? Icons.error_rounded
                    : Icons.verified_user_rounded,
            color: approved
                ? green
                : isRejected
                    ? red
                    : blue,
            title:
                'DOJO Platform Verification',
            subtitle: approved
                ? 'Verification approved'
                : isRejected
                    ? 'Verification requires attention'
                    : 'Waiting for DOJO Platform verification',
          ),

          _line(),

          _step(
            icon: approved
                ? Icons.check_circle_rounded
                : Icons.lock_rounded,
            color: approved
                ? green
                : const Color(0xFF98A0AA),
            title:
                'Walker ID Activation',
            subtitle: approved
                ? 'Walker account is active'
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
  }) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: color,
                  fontWeight:
                      FontWeight.w600,
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
          const Color(0xFFE0E4E8),
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
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFFFFF7F1),
            Color(0xFFF1F7FF),
          ],
        ),
        borderRadius:
            BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: orange,
              ),
              SizedBox(width: 9),
              Text(
                'What happens next?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _nextLine(
            'Your profile has been submitted.',
            true,
          ),

          _nextLine(
            'DOJO Platform will verify your information.',
            isApproved,
          ),

          _nextLine(
            'Your Walker account will activate after approval.',
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
            style: TextStyle(
              fontSize: 12.5,
              color: completed
                  ? green
                  : const Color(
                      0xFF98A0AA,
                    ),
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.7,
                color:
                    Color(0xFF667085),
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

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: rejected
            ? const Color(0xFFFFEEEE)
            : const Color(0xFFFFF4EA),
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            rejected
                ? Icons.error_outline_rounded
                : Icons.lock_outline_rounded,
            color:
                rejected ? red : orange,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              rejected
                  ? 'Walker account needs verification attention. Please contact DOJO Platform support.'
                  : 'Walker account is locked until DOJO Platform verification is completed.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: rejected
                    ? const Color(
                        0xFF7A3030,
                      )
                    : const Color(
                        0xFF7A4A2A,
                      ),
                fontWeight:
                    FontWeight.w600,
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
        foregroundColor: blue,
        side: BorderSide(
          color:
              blue.withOpacity(.25),
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
              FontWeight.w700,
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
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: blue,
                  size: 45,
                ),

                const SizedBox(
                  height: 12,
                ),

                const Text(
                  'DOJO Support',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Need help with your verification? Our support team is here to help.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: muted,
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
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    icon: const Icon(
                      Icons.chat_rounded,
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
