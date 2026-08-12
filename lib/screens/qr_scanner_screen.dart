// File location: lib/screens/qr_scanner_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool isScanCompleted = false;
  bool isProcessing = false;

  Future<void> _processOwnerQR(String rawData) async {
    if (isScanCompleted || isProcessing) return;

    setState(() {
      isScanCompleted = true;
      isProcessing = true;
    });

    try {
      // ==================================================
      // 1. READ QR JSON
      // ==================================================

      final dynamic decodedData = jsonDecode(rawData);

      if (decodedData is! Map) {
        throw Exception('Invalid Owner QR Code');
      }

      final String type =
          decodedData['type']?.toString() ?? '';

      final String ownerUid =
          decodedData['uid']?.toString() ?? '';

      final String ownerName =
          decodedData['name']?.toString() ??
              'Owner';

      final String ownerUserId =
          decodedData['userId']?.toString() ?? '';

      // ==================================================
      // 2. CHECK OWNER QR TYPE
      // ==================================================

      if (type != 'owner') {
        throw Exception(
          'This is not a valid Owner QR Code.',
        );
      }

      if (ownerUid.isEmpty) {
        throw Exception(
          'Owner UID is missing from QR Code.',
        );
      }

      // ==================================================
      // 3. CHECK WALKER LOGIN
      // ==================================================

      final User? walker =
          FirebaseAuth.instance.currentUser;

      if (walker == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      final String walkerUid = walker.uid;

      // ==================================================
      // 4. VERIFY OWNER QR IN FIREBASE
      // ==================================================

      final DocumentSnapshot<Map<String, dynamic>>
          ownerQR = await FirebaseFirestore
              .instance
              .collection('qr_codes')
              .doc('owner_qr')
              .get();

      if (!ownerQR.exists) {
        throw Exception(
          'Owner QR was not found in Firebase.',
        );
      }

      final Map<String, dynamic> firebaseData =
          ownerQR.data() ??
              <String, dynamic>{};

      final String firebaseOwnerUid =
          firebaseData['uid']?.toString() ?? '';

      if (firebaseOwnerUid != ownerUid) {
        throw Exception(
          'Owner QR verification failed.',
        );
      }

      // ==================================================
      // 5. SAVE SCAN RESULT TO FIREBASE
      // ==================================================

      await FirebaseFirestore.instance
          .collection('qr_codes')
          .doc('owner_qr')
          .update({
        'scanned': true,
        'scannedBy': walkerUid,
        'scannedAt':
            FieldValue.serverTimestamp(),
      });

      // ==================================================
      // 6. CREATE ACTIVE WALK CONNECTION
      // ==================================================

      final DocumentReference walkRef =
          FirebaseFirestore.instance
              .collection('active_walks')
              .doc();

      await walkRef.set({
        'walkId': walkRef.id,
        'ownerUid': ownerUid,
        'ownerUserId': ownerUserId,
        'ownerName': ownerName,
        'walkerUid': walkerUid,
        'status': 'active',
        'startedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      // ==================================================
      // 7. RETURN DIRECTLY TO LIVE WALK
      // ==================================================

      if (!mounted) return;

      Navigator.pop(
        context,
        jsonEncode({
          'ownerUid': ownerUid,
          'ownerUserId': ownerUserId,
          'ownerName': ownerName,
          'walkerUid': walkerUid,
          'walkId': walkRef.id,
          'status': 'active',
        }),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isScanCompleted = false;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text(
          'Scan Owner QR Code',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: Stack(
        children: [

          // ==============================================
          // CAMERA
          // ==============================================

          MobileScanner(
            onDetect:
                (BarcodeCapture capture) {
              if (isScanCompleted ||
                  isProcessing) {
                return;
              }

              for (final Barcode barcode
                  in capture.barcodes) {
                final String? rawData =
                    barcode.rawValue;

                if (rawData != null &&
                    rawData.isNotEmpty) {
                  _processOwnerQR(
                    rawData,
                  );
                  break;
                }
              }
            },
          ),

          // ==============================================
          // SCAN BOX
          // ==============================================

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration:
                  BoxDecoration(
                border: Border.all(
                  color:
                      Colors.deepOrange,
                  width: 3,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
            ),
          ),

          // ==============================================
          // PROCESSING
          // ==============================================

          if (isProcessing)
            const Center(
              child: Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 15),
                      Text(
                        'Connecting to Owner...',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ==============================================
          // BOTTOM MESSAGE
          // ==============================================

          if (!isProcessing)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Text(
                  "Point your camera at the Owner's QR Code",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
