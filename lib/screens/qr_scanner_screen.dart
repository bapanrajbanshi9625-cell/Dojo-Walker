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
  // ==========================================================
  // STATE
  // ==========================================================

  bool isScanCompleted = false;
  bool isProcessing = false;

  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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

      final dynamic decodedData =
          jsonDecode(rawData);

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
          decodedData['ownerUid']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? decodedData['ownerUid']
              .toString()
              .trim()
          : decodedData['uid']
                  ?.toString()
                  .trim() ??
              '';

      final String ownerName =
          decodedData['ownerName']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? decodedData['ownerName']
              .toString()
              .trim()
          : decodedData['name']
                  ?.toString()
                  .trim() ??
              'Owner';

      final String ownerPhone =
          decodedData['ownerPhone']
                  ?.toString()
                  .trim() ??
              decodedData['phoneNumber']
                  ?.toString()
                  .trim() ??
              '';

      final String ownerUserId =
          decodedData['userId']
                  ?.toString()
                  .trim() ??
              ownerUid;

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
      // 5. GET WALKER
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
      // 6. GET OWNER QR FROM FIRESTORE
      // ======================================================
      //
      // Owner app creates:
      //
      // qr_codes/{ownerUid}
      //
      // Therefore Walker reads exactly:
      //
      // qr_codes/{ownerUid}
      // ======================================================

      final DocumentSnapshot<
          Map<String, dynamic>> ownerQR =
          await _firestore
              .collection('qr_codes')
              .doc(ownerUid)
              .get();

      if (!ownerQR.exists) {
        throw Exception(
          'Owner QR not found.\n'
          'Please ask the Owner to generate a new QR code.',
        );
      }

      final Map<String, dynamic> firebaseData =
          ownerQR.data() ??
              <String, dynamic>{};

      // ======================================================
      // 7. VERIFY FIREBASE OWNER UID
      // ======================================================

      final String firebaseOwnerUid =
          firebaseData['ownerUid']
                  ?.toString()
                  .trim() ??
              firebaseData['uid']
                  ?.toString()
                  .trim() ??
              '';

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
      // 8. GET VERIFIED OWNER DATA
      // ======================================================

      final String firebaseOwnerName =
          firebaseData['ownerName']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? firebaseData['ownerName']
              .toString()
              .trim()
          : firebaseData['name']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? firebaseData['name']
              .toString()
              .trim()
          : ownerName;

      final String firebaseOwnerPhone =
          firebaseData['ownerPhone']
                  ?.toString()
                  .trim() ??
              firebaseData['phoneNumber']
                  ?.toString()
                  .trim() ??
              ownerPhone;

      final String firebaseWalkId =
          firebaseData['walkId']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? firebaseData['walkId']
              .toString()
              .trim()
          : qrWalkId;

      // ======================================================
      // 9. READ SAVED OWNER DESTINATION
      // ======================================================
      //
      // Owner QR contains:
      //
      // ownerLocation:
      // {
      //   latitude,
      //   longitude,
      //   accuracy
      // }
      //
      // This is ONLY a location snapshot.
      //
      // It is NOT Owner live location.
      // ======================================================

      Map<String, dynamic>? ownerLocation;

      final dynamic qrOwnerLocation =
          firebaseData['ownerLocation'];

      if (qrOwnerLocation is Map) {
        final dynamic latitude =
            qrOwnerLocation['latitude'];

        final dynamic longitude =
            qrOwnerLocation['longitude'];

        if (latitude != null &&
            longitude != null) {
          ownerLocation =
              <String, dynamic>{
            'latitude':
                _toDouble(latitude),
            'longitude':
                _toDouble(longitude),
          };

          final dynamic accuracy =
              qrOwnerLocation['accuracy'];

          if (accuracy != null) {
            ownerLocation['accuracy'] =
                _toDouble(accuracy);
          }
        }
      }

      // ======================================================
      // 10. VERIFY LOCATION TYPE
      // ======================================================

      final String ownerLocationType =
          firebaseData['ownerLocationType']
                  ?.toString()
                  .trim() ??
              'saved';

      // ======================================================
      // 11. CHECK EXISTING ACTIVE WALK
      // ======================================================
      //
      // Prevent accidental duplicate active walks
      // for the same Walker + Owner.
      // ======================================================

      final QuerySnapshot<
          Map<String, dynamic>> existingWalks =
          await _firestore
              .collection('active_walks')
              .where(
                'walkerUid',
                isEqualTo: walkerUid,
              )
              .where(
                'status',
                isEqualTo: 'active',
              )
              .limit(10)
              .get();

      for (final QueryDocumentSnapshot<
          Map<String, dynamic>> doc
          in existingWalks.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final String existingOwnerUid =
            data['ownerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (existingOwnerUid ==
            ownerUid) {
          throw Exception(
            'You already have an active walk with this Owner.',
          );
        }
      }

      // ======================================================
      // 12. MARK QR AS SCANNED
      // ======================================================

      await _firestore
          .collection('qr_codes')
          .doc(ownerUid)
          .update({
        'scanned': true,
        'scannedBy': walkerUid,
        'scannedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      // ======================================================
      // 13. CREATE ACTIVE WALK
      // ======================================================

      final DocumentReference<
          Map<String, dynamic>> walkRef =
          _firestore
              .collection('active_walks')
              .doc();

      final Map<String, dynamic>
          activeWalkData =
          <String, dynamic>{
        // ----------------------------------------------------
        // WALK
        // ----------------------------------------------------

        'walkId':
            walkRef.id,

        'qrWalkId':
            firebaseWalkId,

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
        // LOCATION TYPE
        // ----------------------------------------------------
        //
        // saved = destination snapshot
        //
        // Never live owner tracking.
        // ----------------------------------------------------

        'ownerLocationType':
            ownerLocationType,

        // ----------------------------------------------------
        // OWNER DESTINATION
        // ----------------------------------------------------

        if (ownerLocation != null)
          'ownerLocation':
              ownerLocation,

        // ----------------------------------------------------
        // TRACKING FLAGS
        // ----------------------------------------------------

        'walkerTracking':
            false,

        'trackingStarted':
            false,

        'trackingEnded':
            false,

        'walkStarted':
            false,

        'walkEnded':
            false,

        // ----------------------------------------------------
        // TIMESTAMPS
        // ----------------------------------------------------

        'startedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      await walkRef.set(
        activeWalkData,
      );

      // ======================================================
      // 14. SUCCESS
      // ======================================================

      debugPrint(
        'Owner QR scanned successfully.',
      );

      debugPrint(
        'Owner UID: $ownerUid',
      );

      debugPrint(
        'Walker UID: $walkerUid',
      );

      debugPrint(
        'Active Walk ID: ${walkRef.id}',
      );

      if (ownerLocation != null) {
        debugPrint(
          'Saved Owner destination: '
          '${ownerLocation['latitude']}, '
          '${ownerLocation['longitude']}',
        );
      } else {
        debugPrint(
          'Owner destination was not available.',
        );
      }

      // ======================================================
      // 15. RETURN TO LIVE WALK
      // ======================================================

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        jsonEncode({
          'ownerUid':
              ownerUid,

          'ownerUserId':
              ownerUserId,

          'ownerName':
              firebaseOwnerName,

          'ownerPhone':
              firebaseOwnerPhone,

          'walkerUid':
              walkerUid,

          'walkId':
              walkRef.id,

          'qrWalkId':
              firebaseWalkId,

          'status':
              'active',

          'ownerLocationType':
              ownerLocationType,

          if (ownerLocation != null)
            'ownerLocation':
                ownerLocation,
        }),
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
            ? 'You do not have permission to connect with this Owner.'
            : e.message ??
                'Unable to connect with Owner.',
      );
    } catch (e) {
      debugPrint(
        'QR scan error: $e',
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
  // DOUBLE / INT / STRING SAFE DOUBLE
  // ==========================================================

  double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0.0;
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
          ),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          backgroundColor:
              const Color(0xFF263746),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
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
            const Color(0xFFE45D32),

        elevation: 0,

        title: const Text(
          'Scan Owner QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.white,
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
                (
              BarcodeCapture capture,
            ) {
              if (isScanCompleted ||
                  isProcessing) {
                return;
              }

              for (final Barcode barcode
                  in capture.barcodes) {
                final String? rawData =
                    barcode.rawValue;

                if (rawData != null &&
                    rawData.trim().isNotEmpty) {
                  _processOwnerQR(
                    rawData.trim(),
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
              decoration:
                  BoxDecoration(
                color: Colors.black
                    .withValues(
                  alpha: .18,
                ),
              ),
            ),
          ),

          // ==================================================
          // SCAN FRAME
          // ==================================================

          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFFF6B35,
                  ),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(
                      0xFFFF6B35,
                    ).withValues(
                      alpha: .35,
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // SCAN CORNERS
          // ==================================================

          Center(
            child: SizedBox(
              width: 270,
              height: 270,
              child: CustomPaint(
                painter:
                    _ScannerCornersPainter(),
              ),
            ),
          ),

          // ==================================================
          // TOP INSTRUCTION
          // ==================================================

          Positioned(
            top: 28,
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
                color: Colors.black
                    .withValues(
                  alpha: .58,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons
                        .qr_code_scanner_rounded,
                    color:
                        Colors.white,
                    size: 22,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'Scan the Owner QR code to start the walk.',
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

          // ==================================================
          // CENTER LABEL
          // ==================================================

          Positioned(
            top:
                MediaQuery.of(context)
                        .size
                        .height /
                    2 +
                145,
            left: 30,
            right: 30,
            child: const Text(
              'Place the Owner QR code inside the frame',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    14,
                fontWeight:
                    FontWeight.w700,
                shadows: [
                  Shadow(
                    color:
                        Colors.black87,
                    blurRadius:
                        6,
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // PROCESSING
          // ==================================================

          if (isProcessing)
            Container(
              color: Colors.black
                  .withValues(
                alpha: .48,
              ),
              child: Center(
                child: Card(
                  elevation: 12,
                  margin:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 35,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 42,
                          height: 42,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                3,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              Color(
                                0xFFE45D32,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        const Text(
                          'Connecting to Owner...',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(
                              0xFF263746,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          'Verifying QR and creating Live Walk',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            fontSize:
                                12,
                            color:
                                Colors.grey
                                    .shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ==================================================
          // BOTTOM MESSAGE
          // ==================================================

          if (!isProcessing)
            Positioned(
              bottom: 38,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 16,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.black
                      .withValues(
                    alpha: .62,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .camera_alt_rounded,
                      color:
                          Colors.white,
                      size: 18,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Flexible(
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
}

// ================================================================
// SCANNER CORNERS PAINTER
// ================================================================

class _ScannerCornersPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const Color color =
        Color(0xFFFF6B35);

    const double length = 28;
    const double strokeWidth = 5;
    const double radius = 5;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // ==========================================================
    // TOP LEFT
    // ==========================================================

    final Path topLeft =
        Path()
          ..moveTo(
            0,
            length,
          )
          ..lineTo(
            0,
            radius,
          )
          ..quadraticBezierTo(
            0,
            0,
            radius,
            0,
          )
          ..lineTo(
            length,
            0,
          );

    canvas.drawPath(
      topLeft,
      paint,
    );

    // ==========================================================
    // TOP RIGHT
    // ==========================================================

    final Path topRight =
        Path()
          ..moveTo(
            size.width - length,
            0,
          )
          ..lineTo(
            size.width - radius,
            0,
          )
          ..quadraticBezierTo(
            size.width,
            0,
            size.width,
            radius,
          )
          ..lineTo(
            size.width,
            length,
          );

    canvas.drawPath(
      topRight,
      paint,
    );

    // ==========================================================
    // BOTTOM LEFT
    // ==========================================================

    final Path bottomLeft =
        Path()
          ..moveTo(
            0,
            size.height - length,
          )
          ..lineTo(
            0,
            size.height - radius,
          )
          ..quadraticBezierTo(
            0,
            size.height,
            radius,
            size.height,
          )
          ..lineTo(
            length,
            size.height,
          );

    canvas.drawPath(
      bottomLeft,
      paint,
    );

    // ==========================================================
    // BOTTOM RIGHT
    // ==========================================================

    final Path bottomRight =
        Path()
          ..moveTo(
            size.width - length,
            size.height,
          )
          ..lineTo(
            size.width - radius,
            size.height,
          )
          ..quadraticBezierTo(
            size.width,
            size.height,
            size.width,
            size.height - radius,
          )
          ..lineTo(
            size.width,
            size.height - length,
          );

    canvas.drawPath(
      bottomRight,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
