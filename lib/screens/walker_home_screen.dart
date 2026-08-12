// File location: lib/screens/walker_home_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_colors.dart';
import '../widgets/activity_card.dart';
import '../widgets/map_view.dart';

import 'qr_scanner_screen.dart';
import 'live_walk_screen.dart';

class WalkerHomeScreen extends StatefulWidget {
  const WalkerHomeScreen({super.key});

  @override
  State<WalkerHomeScreen> createState() =>
      _WalkerHomeScreenState();
}

class _WalkerHomeScreenState extends State<WalkerHomeScreen> {
  bool _isWalkStarted = false;

  String? _ownerName;
  String? _ownerUid;
  String? _ownerPhone;

  // Active walk ID
  String? _walkId;

  // ====================================================
  // OPEN QR SCANNER
  // ====================================================

  Future<void> _openCameraScanner() async {
    final String? scannedData =
        await Navigator.push<String>(
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
      final dynamic decoded = jsonDecode(scannedData);

      if (decoded is! Map) {
        throw Exception('Invalid scan data');
      }

      // ==================================================
      // OWNER INFORMATION FROM QR
      // ==================================================

      final String ownerName =
          decoded['ownerName']?.toString() ?? 'Owner';

      final String ownerUid =
          decoded['ownerUid']?.toString() ?? '';

      final String ownerPhone =
          decoded['ownerPhone']?.toString() ?? '';

      // ==================================================
      // WALK ID FROM QR
      // ==================================================

      final String walkId =
          decoded['walkId']?.toString() ?? '';

      // ==================================================
      // WALKER UID FROM FIREBASE AUTH
      // ==================================================

      final User? walkerUser =
          FirebaseAuth.instance.currentUser;

      if (walkerUser == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      final String walkerUid = walkerUser.uid;

      // ==================================================
      // VALIDATION
      // ==================================================

      if (ownerUid.isEmpty) {
        throw Exception(
          'Owner UID is missing from scan data.',
        );
      }

      if (walkId.isEmpty) {
        throw Exception(
          'Walk ID is missing from scan data.',
        );
      }

      if (walkerUid.isEmpty) {
        throw Exception(
          'Walker UID is missing.',
        );
      }

      // ==================================================
      // SAVE ACTIVE WALK STATE
      // ==================================================

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

      // ==================================================
      // OPEN LIVE WALK SCREEN
      // ==================================================

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveWalkScreen(
            // Owner UID
            ownerUid: ownerUid,

            // Walker UID
            walkerUid: walkerUid,

            // Walk ID
            walkId: walkId,

            // Owner information
            ownerName: ownerName,

            ownerPhone:
                ownerPhone.isEmpty
                    ? null
                    : ownerPhone,
          ),
        ),
      );

      // ==================================================
      // WHEN LIVE WALK SCREEN CLOSES
      // ==================================================

      if (!mounted) return;

      setState(() {
        _isWalkStarted = false;

        _ownerName = null;

        _ownerUid = null;

        _ownerPhone = null;

        _walkId = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isWalkStarted = false;

        _ownerName = null;

        _ownerUid = null;

        _ownerPhone = null;

        _walkId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open Live Walk: $e',
          ),
        ),
      );
    }
  }

  // ====================================================
  // OPEN EXISTING ACTIVE WALK
  // ====================================================

  Future<void> _openActiveWalk() async {
    if (!_isWalkStarted ||
        _ownerUid == null ||
        _ownerUid!.isEmpty ||
        _walkId == null ||
        _walkId!.isEmpty) {
      return;
    }

    // ==================================================
    // GET CURRENT WALKER UID
    // ==================================================

    final User? walkerUser =
        FirebaseAuth.instance.currentUser;

    if (walkerUser == null) {
      return;
    }

    final String walkerUid = walkerUser.uid;

    if (walkerUid.isEmpty) {
      return;
    }

    // ==================================================
    // OPEN LIVE WALK
    // ==================================================

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveWalkScreen(
          // Owner UID
          ownerUid: _ownerUid!,

          // Walker UID
          walkerUid: walkerUid,

          // Walk ID
          walkId: _walkId!,

          // Owner information
          ownerName:
              _ownerName ?? 'Owner',

          ownerPhone: _ownerPhone,
        ),
      ),
    );

    // ==================================================
    // RESET AFTER LIVE WALK CLOSES
    // ==================================================

    if (!mounted) return;

    setState(() {
      _isWalkStarted = false;

      _ownerName = null;

      _ownerUid = null;

      _ownerPhone = null;

      _walkId = null;
    });
  }

  // ====================================================
  // BUILD
  // ====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,

        title: Text(
          _isWalkStarted
              ? 'Active Walk'
              : 'Dojo Walker - Buddy',

          style: const TextStyle(
            color: Colors.white,
          ),
        ),

        automaticallyImplyLeading: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          children: [
            // ==========================================
            // TODAY'S ACTIVITY
            // ==========================================

            const ActivityCard(),

            const SizedBox(height: 20),

            // ==========================================
            // MAP
            // ==========================================

            const MapViewWidget(),

            // ==========================================
            // CONNECTED OWNER
            // ==========================================

            if (_isWalkStarted &&
                _ownerName != null) ...[
              const SizedBox(height: 20),

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,

                  borderRadius:
                      BorderRadius.circular(12),

                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),

                child: Column(
                  children: [
                    const Icon(
                      Icons.person,

                      size: 35,

                      color: Colors.blue,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Connected to Owner',

                      style: TextStyle(
                        fontSize: 13,

                        color:
                            Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _ownerName!,

                      style: const TextStyle(
                        fontSize: 18,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    // ==================================
                    // OWNER UID
                    // ==================================

                    if (_ownerUid != null &&
                        _ownerUid!.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Text(
                        'Owner UID: $_ownerUid',

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 11,

                          color:
                              Colors.black45,
                        ),
                      ),
                    ],

                    // ==================================
                    // WALKER UID
                    // ==================================

                    if (FirebaseAuth
                            .instance
                            .currentUser !=
                        null) ...[
                      const SizedBox(height: 3),

                      Text(
                        'Walker UID: '
                        '${FirebaseAuth.instance.currentUser!.uid}',

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 11,

                          color:
                              Colors.black45,
                        ),
                      ),
                    ],

                    // ==================================
                    // WALK ID
                    // ==================================

                    if (_walkId != null &&
                        _walkId!.isNotEmpty) ...[
                      const SizedBox(height: 3),

                      Text(
                        'Walk ID: $_walkId',

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 11,

                          color:
                              Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // ==========================================
            // ACTIVE WALK BAR
            // ==========================================

            if (_isWalkStarted)
              GestureDetector(
                onTap: _openActiveWalk,

                child: Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,

                    borderRadius:
                        BorderRadius.circular(12),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.blue.withAlpha(
                          80,
                        ),

                        blurRadius: 10,

                        offset:
                            const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: const Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,

                            color: Colors.white,

                            size: 28,
                          ),

                          SizedBox(width: 12),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                'Live Walk in Progress',

                                style: TextStyle(
                                  color:
                                      Colors.white,

                                  fontSize: 16,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 2),

                              Text(
                                'Tap to view live details',

                                style: TextStyle(
                                  color:
                                      Colors.white70,

                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Icon(
                        Icons.arrow_forward_ios,

                        color: Colors.white,

                        size: 18,
                      ),
                    ],
                  ),
                ),
              )

            // ==========================================
            // SCAN OWNER QR BUTTON
            // ==========================================

            else
              SizedBox(
                width: double.infinity,

                height: 55,

                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  onPressed:
                      _openCameraScanner,

                  child: const Text(
                    'Scan Owner QR Code',

                    style: TextStyle(
                      fontSize: 16,

                      color: Colors.white,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
