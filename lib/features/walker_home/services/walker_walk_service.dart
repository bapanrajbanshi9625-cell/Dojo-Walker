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
    final String? scannedData =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const QrScannerScreen(),
      ),
    );

    if (!context.mounted ||
        scannedData == null ||
        scannedData.trim().isEmpty) {
      return null;
    }

    try {
      // ========================================================
      // DECODE QR
      // ========================================================

      final dynamic decoded =
          jsonDecode(scannedData);

      if (decoded is! Map) {
        throw Exception(
          'Invalid QR data.',
        );
      }

      // ========================================================
      // QR TYPE
      // ========================================================

      final String type =
          decoded['type']?.toString() ?? '';

      if (type.isNotEmpty &&
          type.toLowerCase() != 'owner') {
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
          decoded['phone']?.toString() ??
          '';

      // ========================================================
      // WALK DATA
      // ========================================================

      final String walkId =
          decoded['walkId']?.toString() ??
          decoded['walkID']?.toString() ??
          decoded['id']?.toString() ??
          '';

      final String dogName =
          decoded['dogName']?.toString() ??
          decoded['petName']?.toString() ??
          decoded['dog']?.toString() ??
          'Dog';

      final String dogBreed =
          decoded['dogBreed']?.toString() ??
          decoded['breed']?.toString() ??
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

      if (ownerUid.trim().isEmpty) {
        throw Exception(
          'Owner UID is missing from QR.',
        );
      }

      // ========================================================
      // VALIDATE WALK
      // ========================================================

      if (walkId.trim().isEmpty) {
        throw Exception(
          'Walk ID is missing from QR.',
        );
      }

      // ========================================================
      // RETURN WALK DATA
      // ========================================================

      return WalkerWalkData(
        ownerName: ownerName.trim().isEmpty
            ? 'Owner'
            : ownerName.trim(),
        ownerUid: ownerUid.trim(),
        ownerPhone: ownerPhone.trim().isEmpty
            ? null
            : ownerPhone.trim(),
        walkId: walkId.trim(),
        dogName: dogName.trim().isEmpty
            ? 'Dog'
            : dogName.trim(),
        dogBreed: dogBreed.trim(),
      );
    } catch (e) {
      if (!context.mounted) {
        return null;
      }

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not read Owner QR: $message',
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
    // ==========================================================
    // WALKER AUTH
    // ==========================================================

    final User? walkerUser =
        FirebaseAuth.instance.currentUser;

    if (walkerUser == null) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Walker is not logged in.',
            ),
          ),
        );

      return;
    }

    if (walkerUser.uid.isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Walker UID is missing.',
            ),
          ),
        );

      return;
    }

    // ==========================================================
    // VALIDATE WALK DATA
    // ==========================================================

    if (walk.ownerUid.trim().isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Owner UID is missing.',
            ),
          ),
        );

      return;
    }

    if (walk.walkId.trim().isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Walk ID is missing.',
            ),
          ),
        );

      return;
    }

    if (!context.mounted) {
      return;
    }

    // ==========================================================
    // OPEN LIVE WALK
    // ==========================================================

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LiveWalkScreen(
          ownerUid: walk.ownerUid,
          ownerName: walk.ownerName,
          walkId: walk.walkId,
          dogName: walk.dogName,
          dogBreed: walk.dogBreed,
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
  final String dogName;
  final String dogBreed;

  const WalkerWalkData({
    required this.ownerName,
    required this.ownerUid,
    required this.ownerPhone,
    required this.walkId,
    required this.dogName,
    required this.dogBreed,
  });
}
