// File location:
// lib/screens/walker_home_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/walker_home/containers/walker_home_header.dart';
import '../features/walker_home/containers/welcome_container.dart';
import '../features/walker_home/containers/today_summary_container.dart';
import '../features/walker_home/containers/live_location_container.dart';
import '../features/walker_home/containers/past_walks_container.dart';

import 'qr_scanner_screen.dart';
import 'live_walk_screen.dart';

class WalkerHomeScreen extends StatefulWidget {
  const WalkerHomeScreen({super.key});

  @override
  State<WalkerHomeScreen> createState() =>
      _WalkerHomeScreenState();
}

class _WalkerHomeScreenState extends State<WalkerHomeScreen> {
  // ============================================================
  // ACTIVE WALK STATE
  // ============================================================

  bool _isWalkStarted = false;

  String? _ownerName;
  String? _ownerUid;
  String? _ownerPhone;
  String? _walkId;

  // ============================================================
  // OPEN CAMERA QR SCANNER
  // ============================================================

  Future<void> _openCameraScanner() async {
    final String? scannedData = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (!mounted ||
        scannedData == null ||
        scannedData.isEmpty) {
      return;
    }

    try {
      // ========================================================
      // DECODE QR
      // ========================================================

      final dynamic decoded = jsonDecode(scannedData);

      if (decoded is! Map) {
        throw Exception('Invalid QR data.');
      }

      // ========================================================
      // QR TYPE
      // ========================================================

      final String type =
          decoded['type']?.toString() ?? '';

      if (type.isNotEmpty && type != 'owner') {
        throw Exception(
          'This is not a valid Owner QR Code.',
        );
      }

      // ========================================================
      // OWNER DATA
      // ========================================================

      final String ownerName =
          decoded['ownerName']?.toString() ??
          decoded['name']?.toString() ??
          'Owner';

      final String ownerUid =
          decoded['ownerUid']?.toString() ??
          decoded['uid']?.toString() ??
          '';

      final String ownerPhone =
          decoded['ownerPhone']?.toString() ??
          decoded['phoneNumber']?.toString() ??
          '';

      final String walkId =
          decoded['walkId']?.toString() ??
          '';

      // ========================================================
      // WALKER AUTH
      // ========================================================

      final User? walkerUser =
          FirebaseAuth.instance.currentUser;

      if (walkerUser == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      final String walkerUid = walkerUser.uid;

      if (walkerUid.isEmpty) {
        throw Exception(
          'Walker UID is missing.',
        );
      }

      // ========================================================
      // VALIDATE OWNER
      // ========================================================

      if (ownerUid.isEmpty) {
        throw Exception(
          'Owner UID is missing from QR.',
        );
      }

      // ========================================================
      // WALK ID
      //
      // QR scanner already creates/validates the active walk.
      // If QR has no walkId, scanner should normally return one.
      // ========================================================

      if (walkId.isEmpty) {
        throw Exception(
          'Walk ID is missing from QR.',
        );
      }

      // ========================================================
      // SAVE ACTIVE WALK
      // ========================================================

      if (!mounted) return;

      setState(() {
        _isWalkStarted = true;

        _ownerName = ownerName;

        _ownerUid = ownerUid;

        _ownerPhone =
            ownerPhone.isEmpty
                ? null
                : ownerPhone;

        _walkId = walkId;
      });

      // ========================================================
      // OPEN LIVE WALK
      // ========================================================

      await _openLiveWalk();

    } catch (e) {
      if (!mounted) return;

      _resetActiveWalk();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open Live Walk: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // OPEN LIVE WALK
  // ============================================================

  Future<void> _openLiveWalk() async {
    if (_ownerUid == null ||
        _ownerUid!.isEmpty ||
        _walkId == null ||
        _walkId!.isEmpty) {
      return;
    }

    // ==========================================================
    // CHECK AUTH
    // ==========================================================

    final User? walkerUser =
        FirebaseAuth.instance.currentUser;

    if (walkerUser == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Walker is not logged in.',
          ),
        ),
      );

      return;
    }

    if (walkerUser.uid.isEmpty) {
      return;
    }

    // ==========================================================
    // OPEN LIVE WALK SCREEN
    // ==========================================================

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveWalkScreen(
          ownerUid: _ownerUid!,
          walkId: _walkId!,
          ownerName: _ownerName ?? 'Owner',
          ownerPhone: _ownerPhone,
        ),
      ),
    );

    // ==========================================================
    // RESET AFTER LIVE WALK
    // ==========================================================

    if (!mounted) return;

    _resetActiveWalk();
  }

  // ============================================================
  // OPEN EXISTING ACTIVE WALK
  // ============================================================

  Future<void> _openActiveWalk() async {
    if (!_isWalkStarted) {
      return;
    }

    await _openLiveWalk();
  }

  // ============================================================
  // RESET ACTIVE WALK
  // ============================================================

  void _resetActiveWalk() {
    if (!mounted) return;

    setState(() {
      _isWalkStarted = false;
      _ownerName = null;
      _ownerUid = null;
      _ownerPhone = null;
      _walkId = null;
    });
  }

  // ============================================================
  // DETAILS BOTTOM SHEET
  // ============================================================

  void _showDetails(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    const Color orange = Color(0xFFFF4B16);
    const Color dark = Color(0xFF27394A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HANDLE
              // ==================================================

              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TITLE
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          orange.withOpacity(.12),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: orange,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================================================
              // DESCRIPTION
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF7F8FA),
                  borderRadius:
                      BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        const Color(0xFFE5E7EA),
                  ),
                ),
                child: Text(
                  description,
                  style: const TextStyle(
                    color:
                        Color(0xFF596574),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // CLOSE
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),

      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ==================================================
            // MAIN CONTENT
            // ==================================================

            Column(
              children: [
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                const WalkerHomeHeader(),

                // ------------------------------------------------
                // SCROLLABLE CONTENT
                // ------------------------------------------------

                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      115,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ========================================
                        // WELCOME
                        // ========================================

                        const WelcomeContainer(),

                        const SizedBox(height: 18),

                        // ========================================
                        // TODAY SUMMARY
                        // ========================================

                        TodaySummaryContainer(
                          onDetails: ({
                            required String title,
                            required String description,
                            required IconData icon,
                          }) {
                            _showDetails(
                              context,
                              title: title,
                              description:
                                  description,
                              icon: icon,
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // ========================================
                        // LIVE LOCATION
                        // ========================================

                        LiveLocationContainer(
                          isWalkStarted:
                              _isWalkStarted,
                        ),

                        const SizedBox(height: 18),

                        // ========================================
                        // PAST WALKS
                        // ========================================

                        PastWalksContainer(
                          onDetails: ({
                            required String title,
                            required String description,
                            required IconData icon,
                          }) {
                            _showDetails(
                              context,
                              title: title,
                              description:
                                  description,
                              icon: icon,
                            );
                          },
                        ),

                        // ========================================
                        // ACTIVE WALK BUTTON
                        // ========================================

                        if (_isWalkStarted) ...[
                          const SizedBox(height: 14),

                          _ActiveWalkButton(
                            ownerName:
                                _ownerName ??
                                    'Owner',
                            onTap:
                                _openActiveWalk,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ==================================================
            // FLOATING QR BUTTON
            // ==================================================

            if (!_isWalkStarted)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _FloatingQrButton(
                  onTap:
                      _openCameraScanner,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FLOATING QR BUTTON
// ================================================================

class _FloatingQrButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingQrButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color orange =
        Color(0xFFFF4B16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: orange,
            borderRadius:
                BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:
                    orange.withOpacity(.30),
                blurRadius: 16,
                offset:
                    const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 27,
              ),

              const SizedBox(width: 10),

              const Text(
                'Scan Owner QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
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

// ================================================================
// ACTIVE WALK BUTTON
// ================================================================

class _ActiveWalkButton
    extends StatelessWidget {
  final String ownerName;
  final VoidCallback onTap;

  const _ActiveWalkButton({
    required this.ownerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color orange =
        Color(0xFFFF4B16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 15,
          ),
          decoration: BoxDecoration(
            color: orange,
            borderRadius:
                BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:
                    orange.withOpacity(.22),
                blurRadius: 12,
                offset:
                    const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      Colors.white
                          .withOpacity(.16),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons
                      .directions_walk_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Walk in Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Walking with '
                      '$ownerName'
                      ' • Tap to view',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
