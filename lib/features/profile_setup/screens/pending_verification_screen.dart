import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../screens/main_navigation_screen.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState
    extends State<PendingVerificationScreen> {
  static const Color orange = Color(0xFFFF6600);
  static const Color blue = Color(0xFF1976D2);
  static const Color green = Color(0xFF22A447);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _verificationSubscription;

  String verificationStatus = 'pending';
  bool walkerIdActive = false;
  bool _openingMain = false;

  @override
  void initState() {
    super.initState();
    _listenForVerification();
  }

  // ============================================================
  // FIREBASE REALTIME LISTENER
  // ============================================================

  void _listenForVerification() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    _verificationSubscription = FirebaseFirestore.instance
        .collection('walkers')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists || !mounted) {
          return;
        }

        final Map<String, dynamic>? data = snapshot.data();

        final String status =
            data?['verificationStatus']?.toString().toLowerCase() ??
                'pending';

        final bool active = data?['walkerIdActive'] == true;

        setState(() {
          verificationStatus = status;
          walkerIdActive = active;
        });

        // APPROVED → MAIN NAVIGATION
        if (status == 'approved' && active) {
          _openMainNavigation();
        }
      },
      onError: (error) {
        debugPrint(
          'Verification listener error: $error',
        );
      },
    );
  }

  // ============================================================
  // OPEN MAIN NAVIGATION
  // ============================================================

  void _openMainNavigation() {
    if (!mounted || _openingMain) {
      return;
    }

    _openingMain = true;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _verificationSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool approved =
        verificationStatus == 'approved' && walkerIdActive;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: _appBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                  approved
                      ? 'Verification Approved'
                      : 'Verification Pending',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17202A),
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  approved
                      ? 'Your DOJO Walker account is now active.'
                      : 'Your profile has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF667085),
                  ),
                ),

                const SizedBox(height: 24),

                _mainStatusCard(),

                const SizedBox(height: 18),

                _statusCard(),

                const SizedBox(height: 18),

                _nextStepCard(),

                const SizedBox(height: 18),

                if (!approved) _lockedCard(),

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
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DOJO Platform',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17202A),
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
    return Container(
      width: 135,
      height: 135,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF3FF),
        border: Border.all(
          color: blue.withOpacity(.15),
          width: 7,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(17),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: blue,
        ),
        child: const Icon(
          Icons.verified_user_rounded,
          color: Colors.white,
          size: 52,
        ),
      ),
    );
  }

  // ============================================================
  // MAIN STATUS
  // ============================================================

  Widget _mainStatusCard() {
    final bool approved =
        verificationStatus == 'approved' && walkerIdActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: blue.withOpacity(.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: blue,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approved
                          ? 'DOJO Platform Verification Approved'
                          : 'Waiting for DOJO Platform Verification',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17202A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      approved
                          ? 'Your Walker account is active.'
                          : 'Verification is currently in progress.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A8491),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: blue,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    approved
                        ? 'Your profile has been approved by DOJO Platform. Walker ID activation is complete.'
                        : 'DOJO Platform is verifying your profile and submitted documents. Please wait for verification to complete.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF34506E),
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
        verificationStatus == 'approved' && walkerIdActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _step(
            icon: Icons.check_circle_rounded,
            color: green,
            title: 'Profile Submitted',
            subtitle: 'Completed successfully',
          ),
          _line(),
          _step(
            icon: approved
                ? Icons.check_circle_rounded
                : Icons.verified_user_rounded,
            color: approved ? green : blue,
            title: 'DOJO Platform Verification',
            subtitle: approved
                ? 'Verification approved'
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
            title: 'Walker ID Activation',
            subtitle: approved
                ? 'Walker ID is active'
                : 'Waiting for DOJO Platform approval',
          ),
        ],
      ),
    );
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line() {
    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        top: 3,
        bottom: 3,
      ),
      width: 2,
      height: 22,
      color: const Color(0xFFE0E4E8),
    );
  }

  // ============================================================
  // NEXT STEP
  // ============================================================

  Widget _nextStepCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF7F1),
            Color(0xFFF1F7FF),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            '✓ Your profile has been submitted.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.7,
              color: Color(0xFF667085),
            ),
          ),
          Text(
            '✓ DOJO Platform will verify your information.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.7,
              color: Color(0xFF667085),
            ),
          ),
          Text(
            '✓ Your Walker ID will activate after approval.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.7,
              color: Color(0xFF667085),
            ),
          ),
          Text(
            '✓ You can then enter the DOJO Walker app.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.7,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCKED
  // ============================================================

  Widget _lockedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: orange,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Walker account is locked until DOJO Platform verification is completed.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF7A4A2A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  Widget _supportButton() {
    return OutlinedButton.icon(
      onPressed: _showSupport,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(
          double.infinity,
          52,
        ),
        foregroundColor: blue,
        side: BorderSide(
          color: blue.withOpacity(.25),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: const Icon(
        Icons.support_agent_rounded,
      ),
      label: const Text(
        'Need Help? Contact Support',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showSupport() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: blue,
                  size: 45,
                ),
                const SizedBox(height: 12),
                const Text(
                  'DOJO Support',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Need help with your verification? Our support team is here to help.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(
                      Icons.chat_rounded,
                    ),
                    label: const Text(
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
