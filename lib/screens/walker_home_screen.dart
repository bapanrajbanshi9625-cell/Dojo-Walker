// File location: lib/screens/walker_home_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/activity_card.dart';
import '../widgets/map_view.dart';
import 'qr_scanner_screen.dart';

class WalkerHomeScreen extends StatefulWidget {
  const WalkerHomeScreen({super.key});

  @override
  State<WalkerHomeScreen> createState() =>
      _WalkerHomeScreenState();
}

class _WalkerHomeScreenState
    extends State<WalkerHomeScreen> {

  bool _isWalkStarted = false;

  String? _ownerName;
  String? _ownerUid;
  String? _walkId;

  // ====================================================
  // OPEN QR SCANNER
  // ====================================================

  Future<void> _openCameraScanner(
      BuildContext context) async {

    final String? scannedData =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const QrScannerScreen(),
      ),
    );

    if (scannedData == null ||
        scannedData.isEmpty ||
        !mounted) {
      return;
    }

    try {
      final dynamic decoded =
          jsonDecode(scannedData);

      if (decoded is! Map) {
        throw Exception(
          'Invalid scan data',
        );
      }

      final String ownerName =
          decoded['ownerName']?.toString() ??
              'Owner';

      final String ownerUid =
          decoded['ownerUid']?.toString() ??
              '';

      final String walkId =
          decoded['walkId']?.toString() ??
              '';

      // ================================================
      // SAVE LOCAL STATE
      // ================================================

      setState(() {
        _isWalkStarted = true;
        _ownerName = ownerName;
        _ownerUid = ownerUid;
        _walkId = walkId;
      });

      // ================================================
      // DIRECTLY OPEN LIVE WALK
      // ================================================

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LiveWalkDetailsScreen(
            ownerName:
                _ownerName ?? 'Owner',
            ownerUid:
                _ownerUid ?? '',
            walkId:
                _walkId ?? '',
            onWalkCompleted:
                _completeWalk,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not open Live Walk: $e',
          ),
        ),
      );
    }
  }

  // ====================================================
  // COMPLETE WALK
  // ====================================================

  void _completeWalk() {
    if (!mounted) return;

    setState(() {
      _isWalkStarted = false;
      _ownerName = null;
      _ownerUid = null;
      _walkId = null;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,

        title: Text(
          _isWalkStarted
              ? 'Active Walk'
              : 'Dojo Walker - Buddy',

          style: const TextStyle(
            color: Colors.white,
          ),
        ),

        automaticallyImplyLeading:
            false,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16.0),

        child: Column(
          children: [

            // ==========================================
            // TODAY'S ACTIVITY
            // ==========================================

            const ActivityCard(),

            const SizedBox(
              height: 20,
            ),

            // ==========================================
            // MAP
            // ==========================================

            const MapViewWidget(),

            // ==========================================
            // CONNECTED OWNER
            // ==========================================

            if (_isWalkStarted &&
                _ownerName != null) ...[
              const SizedBox(
                height: 20,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  16,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.blue.shade50,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),

                  border: Border.all(
                    color:
                        Colors.blue.shade200,
                  ),
                ),

                child: Column(
                  children: [

                    const Icon(
                      Icons.person,
                      size: 35,
                      color:
                          Colors.blue,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Connected to Owner',
                      style:
                          TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      _ownerName!,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(
              height: 30,
            ),

            // ==========================================
            // ACTIVE WALK BAR
            // ==========================================

            if (_isWalkStarted)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LiveWalkDetailsScreen(
                        ownerName:
                            _ownerName ??
                                'Owner',
                        ownerUid:
                            _ownerUid ??
                                '',
                        walkId:
                            _walkId ??
                                '',
                        onWalkCompleted:
                            _completeWalk,
                      ),
                    ),
                  );
                },

                child: Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.blue.shade700,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.blue
                                .withAlpha(80),
                        blurRadius: 10,
                        offset:
                            const Offset(
                          0,
                          5,
                        ),
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
                            Icons
                                .directions_walk,
                            color:
                                Colors.white,
                            size: 28,
                          ),

                          SizedBox(
                            width: 12,
                          ),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                'Live Walk in Progress',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              SizedBox(
                                height: 2,
                              ),

                              Text(
                                'Tap to view live details',
                                style:
                                    TextStyle(
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
                        Icons
                            .arrow_forward_ios,
                        color:
                            Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              )

            // ==========================================
            // SCAN BUTTON
            // ==========================================

            else
              SizedBox(
                width:
                    double.infinity,
                height: 55,

                child:
                    ElevatedButton(
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

                  onPressed: () =>
                      _openCameraScanner(
                    context,
                  ),

                  child:
                      const Text(
                    'Scan Owner QR Code',
                    style:
                        TextStyle(
                      fontSize: 16,
                      color:
                          Colors.white,
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

// ======================================================
// LIVE WALK DETAILS SCREEN
// ======================================================

class LiveWalkDetailsScreen
    extends StatelessWidget {

  const LiveWalkDetailsScreen({
    super.key,
    required this.ownerName,
    required this.ownerUid,
    required this.walkId,
    required this.onWalkCompleted,
  });

  final String ownerName;
  final String ownerUid;
  final String walkId;
  final VoidCallback onWalkCompleted;

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor:
            Colors.blue.shade700,

        title: const Text(
          'Live Walk',
          style: TextStyle(
            color: Colors.white,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              'Live Walk in Progress',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==========================================
            // OWNER CARD
            // ==========================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                18,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.blue.shade50,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                border: Border.all(
                  color:
                      Colors.blue.shade200,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'Active Owner',
                    style:
                        TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    ownerName,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Owner ID: $ownerUid',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Walk ID: $walkId',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==========================================
            // LIVE STATUS
            // ==========================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                16,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.green.shade50,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: const Row(
                children: [

                  Icon(
                    Icons.circle,
                    color:
                        Colors.green,
                    size: 14,
                  ),

                  SizedBox(
                    width: 10,
                  ),

                  Text(
                    'Walk is currently active',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ==========================================
            // END WALK
            // ==========================================

            SizedBox(
              width:
                  double.infinity,
              height: 55,

              child:
                  ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.redAccent,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),

                onPressed:
                    onWalkCompleted,

                child:
                    const Text(
                  'Complete / End Walk',
                  style:
                      TextStyle(
                    fontSize: 16,
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
