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

      // ==================================================
      // 2. READ OWNER DATA
      //
      // New QR format:
      // ownerUid
      // ownerName
      // ownerPhone
      // walkId
      //
      // Old compatibility:
      // uid
      // name
      // userId
      // ==================================================

      final String type =
          decodedData['type']?.toString() ?? '';

      final String ownerUid =
          decodedData['ownerUid']?.toString() ??
              decodedData['uid']?.toString() ??
              '';

      final String ownerName =
          decodedData['ownerName']?.toString() ??
              decodedData['name']?.toString() ??
              'Owner';

      final String ownerPhone =
          decodedData['ownerPhone']?.toString() ??
              decodedData['phoneNumber']?.toString() ??
              '';

      final String ownerUserId =
          decodedData['userId']?.toString() ??
              ownerUid;

      final String qrWalkId =
          decodedData['walkId']?.toString() ?? '';

      // ==================================================
      // 3. CHECK QR TYPE
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
      // 4. CHECK WALKER LOGIN
      // ==================================================

      final User? walker =
          FirebaseAuth.instance.currentUser;

      if (walker == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      final String walkerUid = walker.uid;

      if (walkerUid.isEmpty) {
        throw Exception(
          'Walker UID is missing.',
        );
      }

      // ==================================================
      // 5. FIND OWNER QR
      //
      // IMPORTANT:
      //
      // Owner app saves:
      //
      // qr_codes/
      //    OWNER_UID/
      //
      // So Walker MUST read:
      //
      // qr_codes/{ownerUid}
      //
      // NOT:
      //
      // qr_codes/owner_qr
      // ==================================================

      final DocumentSnapshot<Map<String, dynamic>>
          ownerQR = await FirebaseFirestore.instance
              .collection('qr_codes')
              .doc(ownerUid)
              .get();

      if (!ownerQR.exists) {
        throw Exception(
          'Owner QR not found.\n'
          'Owner UID: $ownerUid',
        );
      }

      final Map<String, dynamic> firebaseData =
          ownerQR.data() ??
              <String, dynamic>{};

      // ==================================================
      // 6. VERIFY OWNER UID
      // ==================================================

      final String firebaseOwnerUid =
          firebaseData['ownerUid']?.toString() ??
              firebaseData['uid']?.toString() ??
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

      // ==================================================
      // 7. GET FIREBASE OWNER DATA
      // ==================================================

      final String firebaseOwnerName =
          firebaseData['ownerName']?.toString() ??
              firebaseData['name']?.toString() ??
              ownerName;

      final String firebaseOwnerPhone =
          firebaseData['ownerPhone']?.toString() ??
              firebaseData['phoneNumber']?.toString() ??
              ownerPhone;

      final String firebaseWalkId =
          firebaseData['walkId']?.toString() ??
              qrWalkId;

      // ==================================================
      // 8. MARK OWNER QR AS SCANNED
      //
      // Same document:
      //
      // qr_codes/{ownerUid}
      // ==================================================

      await FirebaseFirestore.instance
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

      // ==================================================
      // 9. CREATE ACTIVE WALK
      // ==================================================

      final DocumentReference<
          Map<String, dynamic>> walkRef =
          FirebaseFirestore.instance
              .collection('active_walks')
              .doc();

      await walkRef.set({
        'walkId': walkRef.id,

        // OWNER
        'ownerUid': ownerUid,
        'ownerUserId': ownerUserId,
        'ownerName': firebaseOwnerName,
        'ownerPhone': firebaseOwnerPhone,

        // WALKER
        'walkerUid': walkerUid,

        // QR WALK ID
        'qrWalkId': firebaseWalkId,

        // STATUS
        'status': 'active',

        'startedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      // ==================================================
      // 10. RETURN TO LIVE WALK
      // ==================================================

      if (!mounted) return;

      Navigator.pop(
        context,
        jsonEncode({
          'ownerUid': ownerUid,
          'ownerUserId': ownerUserId,
          'ownerName': firebaseOwnerName,
          'ownerPhone': firebaseOwnerPhone,
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

  // ======================================================
  // BUILD
  // ======================================================

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

          // ==================================================
          // SCAN BOX
          // ==================================================

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

          // ==================================================
          // PROCESSING
          // ==================================================

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

                      SizedBox(
                        height: 15,
                      ),

                      Text(
                        'Connecting to Owner...',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ==================================================
          // BOTTOM MESSAGE
          // ==================================================

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
                  color:
                      Colors.black54,

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
