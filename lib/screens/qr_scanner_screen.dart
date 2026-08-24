// File: lib/screens/qr_scanner_screen.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/qr_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // ==========================================================
  // SCAN STATE
  // ==========================================================

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

  CollectionReference<Map<String, dynamic>>
      get _qrConnections =>
          _firestore.collection('qr_connections');

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  // ==========================================================
  // PROCESS OWNER QR
  // ==========================================================

  Future<void> _processOwnerQR(
    String rawData,
  ) async {
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
      // ========================================================
      // 1. PARSE OWNER QR
      // ========================================================

      final QRData qr =
          QRService.dataFromPayload(rawData);

      // ========================================================
      // 2. OWNER BUSINESS ID
      //
      // IMPORTANT:
      // ownerId = Owner Business ID
      // NOT Firebase Auth UID.
      // ========================================================

      final String ownerId =
          qr.ownerId.trim();

      if (ownerId.isEmpty) {
        throw Exception(
          'Owner Business ID is missing from QR code.',
        );
      }

      // ========================================================
      // 3. QR WALK ID
      // ========================================================

      final String qrWalkId =
          qr.walkId.trim();

      if (qrWalkId.isEmpty) {
        throw Exception(
          'Walk ID is missing from QR code.',
        );
      }

      // ========================================================
      // 4. WALKER LOGIN
      // ========================================================

      final User? walker =
          FirebaseAuth.instance.currentUser;

      if (walker == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      // ========================================================
      // 5. WALKER FIREBASE UID
      //
      // walkerUid = Firebase Auth UID
      // ========================================================

      final String walkerUid =
          walker.uid.trim();

      if (walkerUid.isEmpty) {
        throw Exception(
          'Walker Firebase UID is missing.',
        );
      }

      // ========================================================
      // 6. GET WALKER BUSINESS ID
      //
      // phoneAccounts/{walkerUid}
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot =
          await _firestore
              .collection('phoneAccounts')
              .doc(walkerUid)
              .get();

      final Map<String, dynamic>? accountData =
          accountSnapshot.data();

      final String walkerId =
          (
            accountData?['walkerId'] ??
            accountData?['Walker Id'] ??
            accountData?['Walker ID'] ??
            accountData?['walkerBusinessId'] ??
            accountData?['walkerBusinessID'] ??
            accountData?['businessId'] ??
            accountData?['Business ID'] ??
            ''
          )
              .toString()
              .trim();

      if (walkerId.isEmpty) {
        throw Exception(
          'Walker Business ID not found.',
        );
      }

      // ========================================================
      // 7. WALKER NAME
      // ========================================================

      String walkerName =
          (
            accountData?['walkerName'] ??
            accountData?['name'] ??
            accountData?['Full Name'] ??
            accountData?['Name'] ??
            walker.displayName ??
            'Walker'
          )
              .toString()
              .trim();

      if (walkerName.isEmpty) {
        walkerName = 'Walker';
      }

      // ========================================================
      // 8. GET OWNER QR CONNECTION
      //
      // IMPORTANT:
      // Document ID = OWNER BUSINESS ID
      //
      // qr_connections/{ownerId}
      // ========================================================

      final DocumentReference<Map<String, dynamic>>
          connectionRef =
          _qrConnections.doc(ownerId);

      final DocumentSnapshot<Map<String, dynamic>>
          connectionSnapshot =
          await connectionRef.get();

      if (!connectionSnapshot.exists) {
        throw Exception(
          'Owner QR session has expired or is no longer available.',
        );
      }

      final Map<String, dynamic>
          connectionData =
          connectionSnapshot.data() ??
              <String, dynamic>{};

      // ========================================================
      // 9. VERIFY OWNER BUSINESS ID
      // ========================================================

      final String firebaseOwnerId =
          (
            connectionData['ownerId'] ??
            ''
          )
              .toString()
              .trim();

      if (firebaseOwnerId.isEmpty) {
        throw Exception(
          'Owner Business ID is missing in Firebase.',
        );
      }

      if (firebaseOwnerId != ownerId) {
        throw Exception(
          'Owner Business ID verification failed.',
        );
      }

      // ========================================================
      // 10. GET OWNER FIREBASE UID
      //
      // IMPORTANT:
      // ownerUid = Firebase Auth UID
      // ownerId  = Business ID
      // ========================================================

      final String ownerUid =
          (
            connectionData['ownerUid'] ??
            connectionData['authUid'] ??
            connectionData['ownerAuthUid'] ??
            ''
          )
              .toString()
              .trim();

      if (ownerUid.isEmpty) {
        throw Exception(
          'Owner Firebase UID is missing in Firebase.',
        );
      }

      // ========================================================
      // 11. PREVENT SELF SCAN
      //
      // ownerUid  = Firebase UID
      // walkerUid = Firebase UID
      // ========================================================

      if (walkerUid == ownerUid) {
        throw Exception(
          'You cannot scan your own Owner QR Code.',
        );
      }

      // ========================================================
      // 12. VERIFY QR WALK ID
      // ========================================================

      final String firebaseWalkId =
          (
            connectionData['walkId'] ??
            ''
          )
              .toString()
              .trim();

      if (firebaseWalkId.isEmpty) {
        throw Exception(
          'Owner walk session is missing.',
        );
      }

      if (firebaseWalkId != qrWalkId) {
        throw Exception(
          'Owner QR walk verification failed.',
        );
      }

      // ========================================================
      // 13. CHECK EXISTING CONNECTION
      // ========================================================

      final bool alreadyConnected =
          connectionData['connected'] == true;

      final String existingWalkerId =
          (
            connectionData['walkerId'] ??
            ''
          )
              .toString()
              .trim();

      final String existingWalkerUid =
          (
            connectionData['walkerUid'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // ANOTHER WALKER ALREADY CONNECTED
      // ========================================================

      if (alreadyConnected &&
          existingWalkerUid.isNotEmpty &&
          existingWalkerUid != walkerUid) {
        throw Exception(
          'This Owner QR is already connected with another walker.',
        );
      }

      // ========================================================
      // SAME WALKER ALREADY CONNECTED
      // ========================================================

      final String existingActiveWalkId =
          (
            connectionData['activeWalkId'] ??
            ''
          )
              .toString()
              .trim();

      if (alreadyConnected &&
          existingWalkerUid == walkerUid &&
          existingWalkerId == walkerId &&
          existingActiveWalkId.isNotEmpty) {
        throw Exception(
          'You are already connected to this Owner.',
        );
      }

      // ========================================================
      // 14. GENERATE LIVE WALK SESSION
      // ========================================================

      final DocumentReference<Map<String, dynamic>>
          sessionRef =
          _liveWalkSessions.doc();

      final String sessionId =
          sessionRef.id;

      // ========================================================
      // 15. OWNER DATA
      // ========================================================

      String ownerName =
          (
            connectionData['ownerName'] ??
            qr.ownerName ??
            'Owner'
          )
              .toString()
              .trim();

      if (ownerName.isEmpty) {
        ownerName = 'Owner';
      }

      final String ownerPhone =
          (
            connectionData['ownerPhone'] ??
            qr.ownerPhone ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // 16. DOG DATA
      // ========================================================

      String dogName =
          (
            connectionData['dogName'] ??
            qr.dogName ??
            'Dog'
          )
              .toString()
              .trim();

      if (dogName.isEmpty) {
        dogName = 'Dog';
      }

      final String dogBreed =
          (
            connectionData['dogBreed'] ??
            qr.dogBreed ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // 17. FIRESTORE BATCH
      // ========================================================

      final WriteBatch batch =
          _firestore.batch();

      // ========================================================
      // 18. UPDATE QR CONNECTION
      //
      // qr_connections/{ownerId}
      // ========================================================

      batch.set(
        connectionRef,
        {
          'type': 'dojo_owner_qr',
          'version': 1,

          // ----------------------------------------------------
          // OWNER
          // ----------------------------------------------------

          'ownerId': ownerId,
          'ownerUid': ownerUid,

          // ----------------------------------------------------
          // WALK
          // ----------------------------------------------------

          'walkId': firebaseWalkId,

          // ----------------------------------------------------
          // WALKER
          // ----------------------------------------------------

          'walkerId': walkerId,
          'walkerUid': walkerUid,
          'walkerName': walkerName,

          // ----------------------------------------------------
          // CONNECTION
          // ----------------------------------------------------

          'scanned': true,
          'connected': true,

          // ----------------------------------------------------
          // LIVE SESSION
          // ----------------------------------------------------

          'activeWalkId': sessionId,

          // ----------------------------------------------------
          // TIMESTAMPS
          // ----------------------------------------------------

          'scannedAt':
              FieldValue.serverTimestamp(),

          'connectedAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // ========================================================
      // 19. CREATE LIVE WALK SESSION
      //
      // liveWalkSessions/{sessionId}
      // ========================================================

      batch.set(
        sessionRef,
        {
          // ----------------------------------------------------
          // SESSION
          // ----------------------------------------------------

          'id': sessionId,
          'sessionId': sessionId,

          // IMPORTANT:
          // sessionId is the active live session ID.
          // firebaseWalkId is the original QR walk ID.
          'walkId': sessionId,
          'qrWalkId': firebaseWalkId,

          // ----------------------------------------------------
          // SOURCE
          // ----------------------------------------------------

          'source': 'qr',
          'startedFromQr': true,

          // ----------------------------------------------------
          // OWNER
          // ----------------------------------------------------

          'ownerId': ownerId,
          'ownerUid': ownerUid,

          'ownerName': ownerName,
          'ownerPhone': ownerPhone,

          // ----------------------------------------------------
          // WALKER
          // ----------------------------------------------------

          'walkerId': walkerId,
          'walkerUid': walkerUid,
          'walkerName': walkerName,

          // ----------------------------------------------------
          // DOG
          // ----------------------------------------------------

          'dogName': dogName,
          'dogBreed': dogBreed,

          // ----------------------------------------------------
          // LOCATION
          // ----------------------------------------------------

          'currentLocation': {
            'lat': 0.0,
            'lng': 0.0,
          },

          // ----------------------------------------------------
          // WALK STATS
          // ----------------------------------------------------

          'distanceKm': 0.0,
          'elapsedSeconds': 0,

          'peeCount': 0,
          'poopCount': 0,

          // ----------------------------------------------------
          // EVENTS
          // ----------------------------------------------------

          'events':
              <Map<String, dynamic>>[],

          // ----------------------------------------------------
          // ROUTE
          // ----------------------------------------------------

          'routeCoordinates':
              <Map<String, dynamic>>[],

          // ----------------------------------------------------
          // STATUS
          // ----------------------------------------------------

          'status': 'ACTIVE',

          'walkStarted': true,
          'walkEnded': false,

          'trackingStarted': false,
          'trackingEnded': false,

          // ----------------------------------------------------
          // TIMESTAMPS
          // ----------------------------------------------------

          'startedAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      // ========================================================
      // 20. COMMIT
      // ========================================================

      await batch.commit();

      // ========================================================
      // 21. RETURN RESULT
      // ========================================================

      if (!mounted) {
        return;
      }

      final Map<String, dynamic> result = {
        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,

        // ------------------------------------------------------
        // DOG
        // ------------------------------------------------------

        'dogName': dogName,
        'dogBreed': dogBreed,

        // ------------------------------------------------------
        // WALK
        // ------------------------------------------------------

        'walkId': sessionId,
        'qrWalkId': firebaseWalkId,
        'sessionId': sessionId,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status': 'ACTIVE',

        // ------------------------------------------------------
        // SOURCE
        // ------------------------------------------------------

        'source': 'qr',
        'startedFromQr': true,

        // ------------------------------------------------------
        // STATS
        // ------------------------------------------------------

        'peeCount': 0,
        'poopCount': 0,
      };

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
      backgroundColor: Colors.black,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF4511E),
        elevation: 0,
        title: const Text(
          'Scan Owner QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Stack(
        fit: StackFit.expand,
        children: [
          // ======================================================
          // CAMERA
          // ======================================================

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

          // ======================================================
          // DARK OVERLAY
          // ======================================================

          IgnorePointer(
            child: Container(
              color:
                  Colors.black.withOpacity(.18),
            ),
          ),

          // ======================================================
          // SCAN FRAME
          // ======================================================

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

          // ======================================================
          // TOP INSTRUCTION
          // ======================================================

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
                    Colors.black.withOpacity(.58),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Scan the Owner QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // PROCESSING
          // ======================================================

          if (isProcessing)
            Center(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 35,
                ),
                padding:
                    const EdgeInsets.all(24),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 20,
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
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Color(0xFFF4511E),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to Owner...',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF263746),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Verifying QR and creating Live Walk.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ======================================================
          // BOTTOM MESSAGE
          // ======================================================

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
                      Colors.black.withOpacity(.68),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        "Point your camera at the Owner's QR Code",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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

    const double length = 42;
    const double thickness = 4;

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
                    BorderRadius.circular(4),
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
                    BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
