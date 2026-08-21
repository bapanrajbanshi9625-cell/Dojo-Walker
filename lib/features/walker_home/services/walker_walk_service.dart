import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../walks/screens/live_walk_screen.dart';
import '../../../screens/qr_scanner_screen.dart';

class WalkerWalkService {
  // ============================================================
  // OPEN QR SCANNER
  // ============================================================

  static Future<WalkerWalkData?> scanOwnerQr(
    BuildContext context,
  ) async {
    final String? scannedData = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (!context.mounted ||
        scannedData == null ||
        scannedData.isEmpty) {
      return null;
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

      if (walkerUser.uid.isEmpty) {
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
      // VALIDATE WALK
      // ========================================================

      if (walkId.isEmpty) {
        throw Exception(
          'Walk ID is missing from QR.',
        );
      }

      return WalkerWalkData(
        ownerName: ownerName,
        ownerUid: ownerUid,
        ownerPhone:
            ownerPhone.isEmpty ? null : ownerPhone,
        walkId: walkId,
      );
    } catch (e) {
      if (!context.mounted) {
        return null;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not read Owner QR: $e',
          ),
        ),
      );

      return null;
    }
  }

  // ============================================================
  // OPEN LIVE WALK
  // ============================================================

  static Future<void> openLiveWalk(
    BuildContext context,
    WalkerWalkData walk,
  ) async {
    final User? walkerUser =
        FirebaseAuth.instance.currentUser;

    if (walkerUser == null) {
      if (!context.mounted) return;

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

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveWalkScreen(
          ownerUid: walk.ownerUid,
          walkId: walk.walkId,
          ownerName: walk.ownerName,
          ownerPhone: walk.ownerPhone,
        ),
      ),
    );
  }
}

// ================================================================
// WALK DATA
// ================================================================

class WalkerWalkData {
  final String ownerName;
  final String ownerUid;
  final String? ownerPhone;
  final String walkId;

  const WalkerWalkData({
    required this.ownerName,
    required this.ownerUid,
    required this.ownerPhone,
    required this.walkId,
  });
}
