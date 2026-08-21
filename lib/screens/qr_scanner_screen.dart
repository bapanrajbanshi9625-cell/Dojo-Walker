// File location: lib/screens/qr_scanner_screen.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'live_walk_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool isScanCompleted = false;
  bool isProcessing = false;

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // PROCESS OWNER QR
  //
  // QR SCAN
  //    ↓
  // VERIFY OWNER
  //    ↓
  // active_walk/{walkId}
  //    ↓
  // liveWalkSessions/{walkId}
  //    ↓
  // DIRECT LIVE WALK
  // ==========================================================

  Future<void> _processOwnerQR(String rawData) async {
    if (isScanCompleted || isProcessing) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isScanCompleted = true;
      isProcessing = true;
    });

    try {
      // ======================================================
      // 1. DECODE QR JSON
      // ======================================================

      dynamic decodedData;

      try {
        decodedData = jsonDecode(rawData);
      } catch (_) {
        throw Exception(
          'Invalid QR Code format.',
        );
      }

      if (decodedData is! Map) {
        throw Exception(
          'Invalid Owner QR Code.',
        );
      }

      // ======================================================
      // 2. READ QR DATA
      // ======================================================

      final String type =
          decodedData['type']
                  ?.toString()
                  .trim() ??
              '';

      final String ownerUid =
          (
            decodedData['ownerUid'] ??
            decodedData['uid'] ??
            decodedData['userId'] ??
            ''
          )
              .toString()
              .trim();

      final String ownerName =
          (
            decodedData['ownerName'] ??
            decodedData['name'] ??
            'Owner'
          )
              .toString()
              .trim();

      final String ownerPhone =
          (
            decodedData['ownerPhone'] ??
            decodedData['phoneNumber'] ??
            ''
          )
              .toString()
              .trim();

      final String ownerUserId =
          (
            decodedData['userId'] ??
            ownerUid
          )
              .toString()
              .trim();

      final String qrWalkId =
          decodedData['walkId']
                  ?.toString()
                  .trim() ??
              '';

      // ======================================================
      // 3. VERIFY QR TYPE
      // ======================================================

      if (type != 'owner') {
        throw Exception(
          'This is not a valid Owner QR Code.',
        );
      }

      // ======================================================
      // 4. VERIFY OWNER UID
      // ======================================================

      if (ownerUid.isEmpty) {
        throw Exception(
          'Owner UID is missing from QR Code.',
        );
      }

      // ======================================================
      // 5. CHECK WALKER LOGIN
      // ======================================================

      final User? walker =
          FirebaseAuth.instance.currentUser;

      if (walker == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      final String walkerUid =
          walker.uid.trim();

      if (walkerUid.isEmpty) {
        throw Exception(
          'Walker UID is missing.',
        );
      }

      // ======================================================
      // 6. PREVENT SELF SCAN
      // ======================================================

      if (walkerUid == ownerUid) {
        throw Exception(
          'You cannot scan your own Owner QR Code.',
        );
      }

      // ======================================================
      // 7. READ OWNER QR FROM FIRESTORE
      //
      // qr_codes/{ownerUid}
      // ======================================================

      final DocumentReference<
          Map<String, dynamic>> ownerQrRef =
          _firestore
              .collection('qr_codes')
              .doc(ownerUid);

      final DocumentSnapshot<
          Map<String, dynamic>> ownerQR =
          await ownerQrRef.get();

      if (!ownerQR.exists) {
        throw Exception(
          'Owner QR not found in Firebase.',
        );
      }

      final Map<String, dynamic> firebaseData =
          ownerQR.data() ??
              <String, dynamic>{};

      // ======================================================
      // 8. VERIFY OWNER UID FROM FIRESTORE
      // ======================================================

      final String firebaseOwnerUid =
          (
            firebaseData['ownerUid'] ??
            firebaseData['uid'] ??
            firebaseData['userId'] ??
            ''
          )
              .toString()
              .trim();

      if (firebaseOwnerUid.isEmpty) {
        throw Exception(
          'Owner UID is missing in Firebase.',
        );
      }

      if (firebaseOwnerUid != ownerUid) {
        throw Exception(
          'Owner QR verification failed.',
        );
      }

      // ======================================================
      // 9. VERIFIED OWNER INFORMATION
      // ======================================================

      String firebaseOwnerName =
          (
            firebaseData['ownerName'] ??
            firebaseData['name'] ??
            ownerName
          )
              .toString()
              .trim();

      if (firebaseOwnerName.isEmpty) {
        firebaseOwnerName = 'Owner';
      }

      final String firebaseOwnerPhone =
          (
            firebaseData['ownerPhone'] ??
            firebaseData['phoneNumber'] ??
            ownerPhone
          )
              .toString()
              .trim();

      final String firebaseWalkId =
          (
            firebaseData['walkId'] ??
            qrWalkId
          )
              .toString()
              .trim();

      // ======================================================
      // 10. CHECK QR ALREADY SCANNED
      // ======================================================

      final bool alreadyScanned =
          firebaseData['scanned'] == true;

      final String? previousWalker =
          firebaseData['scannedBy']
              ?.toString()
              .trim();

      if (alreadyScanned &&
          previousWalker != null &&
          previousWalker.isNotEmpty &&
          previousWalker != walkerUid) {
        throw Exception(
          'This Owner QR is already connected with another walker.',
        );
      }

      // ======================================================
      // 11. CHECK EXISTING ACTIVE WALK FOR THIS WALKER
      //
      // Prevent accidental duplicate Live Walk.
      // ======================================================

      final QuerySnapshot<
          Map<String, dynamic>> existingWalkSnapshot =
          await _firestore
              .collection('active_walk')
              .where(
                'walkerUid',
                isEqualTo: walkerUid,
              )
              .where(
                'status',
                isEqualTo: 'active',
              )
              .limit(1)
              .get();

      if (existingWalkSnapshot.docs.isNotEmpty) {
        throw Exception(
          'You already have an active Live Walk.',
        );
      }

      // ======================================================
      // 12. MARK OWNER QR AS SCANNED
      // ======================================================

      await ownerQrRef.update({
        'scanned': true,
        'scannedBy': walkerUid,
        'scannedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      // ======================================================
      // 13. CREATE ONE COMMON WALK ID
      //
      // Same ID will be used for:
      //
      // active_walk/{walkId}
      // liveWalkSessions/{walkId}
      //
      // This is important because LiveWalkScreen reads
      // active_walk/{walkId} and liveWalkSessions/{sessionId}.
      // ======================================================

      final DocumentReference<
          Map<String, dynamic>> walkRef =
          _firestore
              .collection('active_walk')
              .doc();

      final String walkId =
          walkRef.id;

      final String sessionId =
          walkId;

      // ======================================================
      // 14. CREATE ACTIVE WALK DATA
      // ======================================================

      final Map<String, dynamic> activeWalkData =
          <String, dynamic>{
        // ----------------------------------------------------
        // WALK
        // ----------------------------------------------------

        'walkId':
            walkId,

        'qrWalkId':
            firebaseWalkId,

        'source':
            'owner_qr',

        'walkType':
            'QR Walk',

        // ----------------------------------------------------
        // OWNER
        // ----------------------------------------------------

        'ownerUid':
            ownerUid,

        'ownerUserId':
            ownerUserId,

        'ownerName':
            firebaseOwnerName,

        'ownerPhone':
            firebaseOwnerPhone,

        // ----------------------------------------------------
        // WALKER
        // ----------------------------------------------------

        'walkerUid':
            walkerUid,

        // ----------------------------------------------------
        // STATUS
        // ----------------------------------------------------

        'status':
            'active',

        'walkStarted':
            true,

        'walkEnded':
            false,

        // ----------------------------------------------------
        // TRACKING
        // ----------------------------------------------------

        'trackingStarted':
            false,

        'trackingEnded':
            false,

        'elapsedSeconds':
            0,

        'distanceKm':
            0.0,

        'distance':
            '0.0 km',

        'peeCount':
            0,

        'poopCount':
            0,

        'routeCoordinates':
            <Map<String, dynamic>>[],

        // ----------------------------------------------------
        // LOCATION
        // ----------------------------------------------------

        'currentLocation':
            <String, dynamic>{
          'lat': 0.0,
          'lng': 0.0,
        },

        'currentLat':
            0.0,

        'currentLng':
            0.0,

        // ----------------------------------------------------
        // SESSION
        // ----------------------------------------------------

        'sessionId':
            sessionId,

        // ----------------------------------------------------
        // TIMESTAMPS
        // ----------------------------------------------------

        'startedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      // ======================================================
      // 15. CREATE LIVE SESSION DATA
      // ======================================================

      final DocumentReference<
          Map<String, dynamic>> sessionRef =
          _firestore
              .collection('liveWalkSessions')
              .doc(sessionId);

      final Map<String, dynamic> liveSessionData =
          <String, dynamic>{
        // ----------------------------------------------------
        // SESSION
        // ----------------------------------------------------

        'sessionId':
            sessionId,

        'walkId':
            walkId,

        // ----------------------------------------------------
        // OWNER
        // ----------------------------------------------------

        'ownerUid':
            ownerUid,

        'ownerUserId':
            ownerUserId,

        'ownerName':
            firebaseOwnerName,

        'ownerPhone':
            firebaseOwnerPhone,

        // ----------------------------------------------------
        // WALKER
        // ----------------------------------------------------

        'walkerUid':
            walkerUid,

        // ----------------------------------------------------
        // STATUS
        // ----------------------------------------------------

        'status':
            'active',

        // ----------------------------------------------------
        // TIMER
        // ----------------------------------------------------

        'elapsedSeconds':
            0,

        // ----------------------------------------------------
        // DISTANCE
        // ----------------------------------------------------

        'distanceKm':
            0.0,

        // ----------------------------------------------------
        // DOG EVENTS
        // ----------------------------------------------------

        'peeCount':
            0,

        'poopCount':
            0,

        // ----------------------------------------------------
        // LOCATION
        // ----------------------------------------------------

        'currentLocation':
            <String, dynamic>{
          'lat': 0.0,
          'lng': 0.0,
        },

        // ----------------------------------------------------
        // ROUTE
        // ----------------------------------------------------

        'routeCoordinates':
            <Map<String, dynamic>>[],

        // ----------------------------------------------------
        // TRACKING
        // ----------------------------------------------------

        'trackingStarted':
            false,

        'trackingEnded':
            false,

        // ----------------------------------------------------
        // TIMESTAMPS
        // ----------------------------------------------------

        'startedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      // ======================================================
      // 16. WRITE BOTH DOCUMENTS
      //
      // Batch makes the creation much safer.
      // ======================================================

      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        walkRef,
        activeWalkData,
      );

      batch.set(
        sessionRef,
        liveSessionData,
      );

      await batch.commit();

      // ======================================================
      // 17. VERIFY ACTIVE WALK
      // ======================================================

      final DocumentSnapshot<
          Map<String, dynamic>> createdWalk =
          await walkRef.get();

      if (!createdWalk.exists) {
        throw Exception(
          'Active Live Walk could not be created.',
        );
      }

      // ======================================================
      // 18. VERIFY LIVE SESSION
      // ======================================================

      final DocumentSnapshot<
          Map<String, dynamic>> createdSession =
          await sessionRef.get();

      if (!createdSession.exists) {
        throw Exception(
          'Live Walk session could not be created.',
        );
      }

      // ======================================================
      // 19. OPEN LIVE WALK DIRECTLY
      // ======================================================

      if (!mounted) {
        return;
      }

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveWalkScreen(
            ownerUid:
                ownerUid,
            ownerName:
                firebaseOwnerName.isEmpty
                    ? 'Owner'
                    : firebaseOwnerName,
            walkId:
                walkId,
            ownerPhone:
                firebaseOwnerPhone.isEmpty
                    ? null
                    : firebaseOwnerPhone,
            sessionId:
                sessionId,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'QR Firebase error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isScanCompleted = false;
        isProcessing = false;
      });

      _showError(
        e.code == 'permission-denied'
            ? 'Permission denied. Please check Firebase rules.'
            : 'Firebase error: ${e.message ?? e.code}',
      );
    } catch (e) {
      debugPrint(
        'QR processing error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isScanCompleted = false;
        isProcessing = false;
      });

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor:
              const Color(0xFFB91C1C),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.black,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF4511E),

        elevation:
            0,

        title: const Text(
          'Scan Owner QR Code',
          style: TextStyle(
            color:
                Colors.white,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color:
              Colors.white,
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================
          // CAMERA
          // ==================================================

          MobileScanner(
            onDetect:
                (BarcodeCapture capture) {
              if (isScanCompleted ||
                  isProcessing) {
                return;
              }

              for (
                final Barcode barcode
                    in capture.barcodes
              ) {
                final String? rawData =
                    barcode.rawValue;

                if (rawData != null &&
                    rawData.trim().isNotEmpty) {
                  _processOwnerQR(
                    rawData,
                  );

                  break;
                }
              }
            },
          ),

          // ==================================================
          // DARK OVERLAY
          // ==================================================

          IgnorePointer(
            child: Container(
              color:
                  Colors.black.withOpacity(
                .18,
              ),
            ),
          ),

          // ==================================================
          // SCAN FRAME
          // ==================================================

          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  Container(
                    decoration:
                        BoxDecoration(
                      border:
                          Border.all(
                        color:
                            Colors.transparent,
                        width: 2,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 0,
                    left: 0,
                    child: _corner(
                      top: true,
                      left: true,
                    ),
                  ),

                  Positioned(
                    top: 0,
                    right: 0,
                    child: _corner(
                      top: true,
                      left: false,
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _corner(
                      top: false,
                      left: true,
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _corner(
                      top: false,
                      left: false,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // TOP INSTRUCTION
          // ==================================================

          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.black.withOpacity(
                  .58,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color:
                        Colors.white,
                    size: 21,
                  ),
                  SizedBox(
                    width: 9,
                  ),
                  Expanded(
                    child: Text(
                      'Scan the Owner QR Code',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // PROCESSING
          // ==================================================

          if (isProcessing)
            Center(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 35,
                ),
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color:
                          Colors.black38,
                      blurRadius:
                          20,
                      offset:
                          Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            3,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Color(
                            0xFFF4511E,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      'Starting Live Walk...',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        fontSize:
                            15,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(
                          0xFF263746,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Verifying Owner QR and connecting the walk.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        fontSize:
                            11,
                        color:
                            Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ==================================================
          // BOTTOM MESSAGE
          // ==================================================

          if (!isProcessing)
            Positioned(
              bottom: 35,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.black.withOpacity(
                    .68,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      color:
                          Colors.white,
                      size: 19,
                    ),
                    SizedBox(
                      width: 9,
                    ),
                    Expanded(
                      child: Text(
                        "Point your camera at the Owner's QR Code",
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // SCAN CORNER
  // ==========================================================

  Widget _corner({
    required bool top,
    required bool left,
  }) {
    const Color orange =
        Color(0xFFFF6600);

    const double length =
        42;

    const double thickness =
        4;

    return SizedBox(
      width: length,
      height: length,
      child: Stack(
        children: [
          Positioned(
            top:
                top ? 0 : null,
            bottom:
                top ? null : 0,
            left:
                left ? 0 : null,
            right:
                left ? null : 0,
            child: Container(
              width: length,
              height: thickness,
              decoration:
                  BoxDecoration(
                color: orange,
                borderRadius:
                    BorderRadius.circular(
                  4,
                ),
              ),
            ),
          ),
          Positioned(
            top:
                top ? 0 : null,
            bottom:
                top ? null : 0,
            left:
                left ? 0 : null,
            right:
                left ? null : 0,
            child: Container(
              width: thickness,
              height: length,
              decoration:
                  BoxDecoration(
                color: orange,
                borderRadius:
                    BorderRadius.circular(
                  4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
