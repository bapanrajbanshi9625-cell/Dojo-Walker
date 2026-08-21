// File location: lib/screens/qr_scanner_screen.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  // COLLECTIONS
  // ==========================================================

  CollectionReference<Map<String, dynamic>> get _qrCodes =>
      _firestore.collection('qr_codes');

  CollectionReference<Map<String, dynamic>> get _activeWalks =>
      _firestore.collection('active_walk');

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  // ==========================================================
  // PROCESS OWNER QR
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
          decodedData['type']?.toString().trim() ?? '';

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
      // 6. PREVENT WALKER FROM SCANNING OWN QR
      // ======================================================

      if (walkerUid == ownerUid) {
        throw Exception(
          'You cannot scan your own Owner QR Code.',
        );
      }

      // ======================================================
      // 7. READ VERIFIED OWNER QR FROM FIRESTORE
      //
      // qr_codes/{ownerUid}
      // ======================================================

      final DocumentReference<Map<String, dynamic>>
          ownerQrRef =
          _qrCodes.doc(ownerUid);

      final DocumentSnapshot<Map<String, dynamic>>
          ownerQR =
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
      // 9. GET VERIFIED OWNER INFORMATION
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
      // 10. CHECK IF QR IS ALREADY SCANNED
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
      // 11. GET WALKER ID
      //
      // phoneAccounts/{walkerUid}
      // ======================================================

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot =
          await _firestore
              .collection('phoneAccounts')
              .doc(walkerUid)
              .get();

      final Map<String, dynamic>? accountData =
          accountSnapshot.data();

      final String walkerId =
          accountData?['walkerId']
                  ?.toString()
                  .trim() ??
              '';

      if (walkerId.isEmpty) {
        throw Exception(
          'Walker ID not found.',
        );
      }

      // ======================================================
      // 12. CREATE ONE ACTIVE WALK ID
      //
      // This same ID is used everywhere:
      //
      // active_walk/{walkId}
      // liveWalkSessions/{sessionId}
      // ======================================================

      final DocumentReference<Map<String, dynamic>>
          activeWalkRef =
          _activeWalks.doc();

      final String activeWalkId =
          activeWalkRef.id;

      final String sessionId =
          'session-$activeWalkId';

      final DocumentReference<Map<String, dynamic>>
          sessionRef =
          _liveWalkSessions.doc(sessionId);

      // ======================================================
      // 13. MARK OWNER QR AS SCANNED
      // ======================================================

      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        ownerQrRef,
        {
          'scanned': true,
          'scannedBy': walkerUid,
          'scannedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // ======================================================
      // 14. CREATE ACTIVE WALK
      //
      // active_walk/{activeWalkId}
      // ======================================================

      batch.set(
        activeWalkRef,
        {
          // --------------------------------------------------
          // WALK
          // --------------------------------------------------

          'walkId':
              activeWalkId,

          'qrWalkId':
              firebaseWalkId,

          // --------------------------------------------------
          // OWNER
          // --------------------------------------------------

          'ownerId':
              ownerUserId,

          'ownerUserId':
              ownerUserId,

          'ownerUid':
              ownerUid,

          'ownerName':
              firebaseOwnerName,

          'ownerPhone':
              firebaseOwnerPhone,

          // --------------------------------------------------
          // WALKER
          // --------------------------------------------------

          'walkerId':
              walkerId,

          'walkerUid':
              walkerUid,

          // --------------------------------------------------
          // STATUS
          // --------------------------------------------------

          'status':
              'active',

          'walkStarted':
              true,

          'walkEnded':
              false,

          // --------------------------------------------------
          // TRACKING
          // --------------------------------------------------

          'trackingStarted':
              false,

          'trackingEnded':
              false,

          // --------------------------------------------------
          // LOCATION
          // --------------------------------------------------

          'currentLat':
              0.0,

          'currentLng':
              0.0,

          // --------------------------------------------------
          // WALK STATS
          // --------------------------------------------------

          'distance':
              '0.0 km',

          'duration':
              '00:00:00',

          'peeCount':
              0,

          'poopCount':
              0,

          // --------------------------------------------------
          // SESSION
          // --------------------------------------------------

          'liveWalkSessionId':
              sessionId,

          // --------------------------------------------------
          // TIMESTAMPS
          // --------------------------------------------------

          'startedAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      // ======================================================
      // 15. CREATE LIVE WALK SESSION
      //
      // liveWalkSessions/{sessionId}
      // ======================================================

      batch.set(
        sessionRef,
        {
          // --------------------------------------------------
          // SESSION
          // --------------------------------------------------

          'id':
              sessionId,

          'sessionId':
              sessionId,

          'walkId':
              activeWalkId,

          'qrWalkId':
              firebaseWalkId,

          // --------------------------------------------------
          // OWNER
          // --------------------------------------------------

          'ownerId':
              ownerUserId,

          'ownerUserId':
              ownerUserId,

          'ownerUid':
              ownerUid,

          'ownerName':
              firebaseOwnerName,

          'ownerPhone':
              firebaseOwnerPhone,

          // --------------------------------------------------
          // WALKER
          // --------------------------------------------------

          'walkerId':
              walkerId,

          'walkerUid':
              walkerUid,

          // --------------------------------------------------
          // DOG
          // --------------------------------------------------

          'dogName':
              '',

          // --------------------------------------------------
          // CURRENT LOCATION
          // --------------------------------------------------

          'currentLocation': {
            'lat': 0.0,
            'lng': 0.0,
          },

          // --------------------------------------------------
          // STATS
          // --------------------------------------------------

          'distanceKm':
              0.0,

          'elapsedSeconds':
              0,

          'peeCount':
              0,

          'poopCount':
              0,

          // --------------------------------------------------
          // EVENTS
          // --------------------------------------------------

          'events':
              <Map<String, dynamic>>[],

          // --------------------------------------------------
          // ROUTE
          // --------------------------------------------------

          'routeCoordinates':
              <Map<String, dynamic>>[],

          // --------------------------------------------------
          // STATUS
          // --------------------------------------------------

          'status':
              'ACTIVE',

          // --------------------------------------------------
          // TIMESTAMPS
          // --------------------------------------------------

          'startedAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      // ======================================================
      // 16. COMMIT EVERYTHING TO FIRESTORE
      // ======================================================

      await batch.commit();

      // ======================================================
      // 17. SUCCESS
      // ======================================================

      if (!mounted) {
        return;
      }

      final Map<String, dynamic> result =
          <String, dynamic>{
        'ownerUid':
            ownerUid,

        'ownerUserId':
            ownerUserId,

        'ownerId':
            ownerUserId,

        'ownerName':
            firebaseOwnerName,

        'ownerPhone':
            firebaseOwnerPhone,

        'walkerUid':
            walkerUid,

        'walkerId':
            walkerId,

        'walkId':
            activeWalkId,

        'qrWalkId':
            firebaseWalkId,

        'sessionId':
            sessionId,

        'status':
            'active',
      };

      // ======================================================
      // RETURN TO LIVE WALK SCREEN
      // ======================================================

      Navigator.pop(
        context,
        jsonEncode(result),
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

  void _showError(String message) {
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
  Widget build(BuildContext context) {
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
                    child:
                        _corner(
                      top: true,
                      left: true,
                    ),
                  ),

                  Positioned(
                    top: 0,
                    right: 0,
                    child:
                        _corner(
                      top: true,
                      left: false,
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    child:
                        _corner(
                      top: false,
                      left: true,
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child:
                        _corner(
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
                    Icons
                        .qr_code_scanner_rounded,
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
                      'Connecting to Owner...',
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
                      'Verifying QR and creating Live Walk.',
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
                      Icons
                          .camera_alt_rounded,
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
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
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
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
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
