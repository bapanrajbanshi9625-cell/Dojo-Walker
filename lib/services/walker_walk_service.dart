// File:
// lib/services/walker_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/live_walk/screens/live_walk_screen.dart';
import '../features/qr_walk/screens/qr_scanner_screen.dart';

/// ============================================================
/// WALKER WALK SERVICE
///
/// FINAL ID ARCHITECTURE
///
/// One single ID is used everywhere:
///
///     DW000001
///
///     walk_request/DW000001
///     liveWalkSessions/DW000001
///     walk_history/DW000001
///
/// No separate walkId.
/// No separate sessionId.
/// No Firebase Auto-ID.
///
/// ============================================================
/// SUPPORTED FLOWS
///
/// 1. QR WALK
///
///    Owner QR
///        ↓
///    requestId = DW######
///        ↓
///    liveWalkSessions/{requestId}
///        ↓
///    Walker connects
///        ↓
///    LiveWalkScreen(requestId: requestId)
///
/// 2. INSTA WALK
///
///    walk_request/{requestId}
///        ↓
///    Walker accepts
///        ↓
///    LiveWalkScreen(requestId: requestId)
///
/// ============================================================

class WalkerWalkService {
  WalkerWalkService._();

  static final WalkerWalkService instance = WalkerWalkService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  static CollectionReference<Map<String, dynamic>>
      get _walkRequests =>
          _firestore.collection('walk_request');

  // ============================================================
  // CURRENT WALKER
  // ============================================================

  static User? get _currentWalker =>
      _auth.currentUser;

  // ============================================================
  // REQUEST ID VALIDATION
  // ============================================================

  static bool _isValidRequestId(
    String value,
  ) {
    return RegExp(r'^DW\d{6}$').hasMatch(
      value.trim(),
    );
  }

  // ============================================================
  // SCAN OWNER QR
  // ============================================================

  static Future<WalkerWalkData?> scanOwnerQr(
    BuildContext context,
  ) async {
    final String? scannedData =
        await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const QrScannerScreen(),
      ),
    );

    if (!context.mounted ||
        scannedData == null ||
        scannedData.trim().isEmpty) {
      return null;
    }

    try {
      final String rawQr =
          scannedData.trim();

      dynamic decoded;

      try {
        decoded = jsonDecode(rawQr);
      } catch (_) {
        throw Exception(
          'Invalid Owner QR Code.',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'Invalid Owner QR Code.',
        );
      }

      final Map<String, dynamic> qr =
          Map<String, dynamic>.from(decoded);

      final User? walker =
          _currentWalker;

      if (walker == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      final String walkerUid =
          walker.uid.trim();

      if (walkerUid.isEmpty) {
        throw Exception(
          'Walker account is invalid.',
        );
      }

      // ========================================================
      // SOURCE
      // ========================================================

      final String source =
          (qr['source'] ?? 'qr')
              .toString()
              .trim()
              .toLowerCase();

      // ========================================================
      // OWNER ID
      // ========================================================

      final String ownerId =
          (
            qr['ownerId'] ??
            qr['ownerUserId'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // OWNER AUTH UID
      // ========================================================

      final String ownerUid =
          (
            qr['ownerUid'] ??
            qr['uid'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // OWNER NAME
      // ========================================================

      final String ownerName =
          (
            qr['ownerName'] ??
            qr['name'] ??
            'Owner'
          )
              .toString()
              .trim();

      // ========================================================
      // OWNER PHONE
      // ========================================================

      final String ownerPhone =
          (
            qr['ownerPhone'] ??
            qr['phoneNumber'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // FINAL REQUEST ID
      //
      // NEW:
      // requestId is the ONLY canonical ID.
      //
      // Legacy walkId is accepted only so an old QR does not
      // immediately crash, but it is converted into requestId.
      // ========================================================

      final String requestId =
          (
            qr['requestId'] ??
            qr['walkId'] ??
            qr['id'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // QR SESSION FLOW
      //
      // The QR payload may contain requestId.
      //
      // We DO NOT use a separate sessionId anymore.
      // ========================================================

      if (source == 'qr' &&
          requestId.isNotEmpty) {
        if (!_isValidRequestId(requestId)) {
          throw Exception(
            'Invalid Walk ID. Expected DW######.',
          );
        }

        return WalkerWalkData(
          ownerId: ownerId,
          ownerUid: ownerUid,
          ownerName:
              ownerName.isEmpty
                  ? 'Owner'
                  : ownerName,
          ownerPhone:
              ownerPhone.isEmpty
                  ? null
                  : ownerPhone,
          requestId: requestId,
          dogName:
              (qr['dogName'] ?? 'Dog')
                  .toString(),
          dogBreed:
              (qr['dogBreed'] ?? '')
                  .toString(),
          source: 'qr',
        );
      }

      // ========================================================
      // OWNER INFORMATION VALIDATION
      // ========================================================

      if (ownerId.isEmpty &&
          ownerUid.isEmpty) {
        throw Exception(
          'Owner information is missing from QR.',
        );
      }

      // ========================================================
      // REQUEST ID VALIDATION
      // ========================================================

      if (requestId.isEmpty) {
        throw Exception(
          'Walk ID is missing from QR.',
        );
      }

      if (!_isValidRequestId(requestId)) {
        throw Exception(
          'Invalid Walk ID. Expected DW######.',
        );
      }

      return WalkerWalkData(
        ownerId:
            ownerId.isNotEmpty
                ? ownerId
                : ownerUid,
        ownerUid: ownerUid,
        ownerName:
            ownerName.isEmpty
                ? 'Owner'
                : ownerName,
        ownerPhone:
            ownerPhone.isEmpty
                ? null
                : ownerPhone,
        requestId: requestId,
        dogName:
            (qr['dogName'] ?? 'Dog')
                .toString(),
        dogBreed:
            (qr['dogBreed'] ?? '')
                .toString(),
        source:
            source.isEmpty
                ? 'qr'
                : source,
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

      _showMessage(
        context,
        'Could not read Owner QR: $message',
      );

      return null;
    }
  }

  // ============================================================
  // CONNECT WITH OWNER
  // ============================================================

  static Future<String> connectWithOwner(
    WalkerWalkData walk,
  ) async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        walker.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker account is invalid.',
      );
    }

    if (!_isValidRequestId(
      walk.requestId,
    )) {
      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    if (walk.isQrFlow) {
      return _connectQrSession(
        walk,
        walkerUid,
      );
    }

    return _connectWalkRequest(
      walk,
      walkerUid,
    );
  }

  // ============================================================
  // CONNECT QR LIVE SESSION
  // ============================================================

  static Future<String> _connectQrSession(
    WalkerWalkData walk,
    String walkerUid,
  ) async {
    final String requestId =
        walk.requestId.trim();

    if (!_isValidRequestId(requestId)) {
      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    // ==========================================================
    // SAME REQUEST ID = SAME SESSION ID
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        sessionRef =
        _liveWalkSessions.doc(requestId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await sessionRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Live Walk session not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // REQUEST ID VERIFICATION
    // ==========================================================

    final String storedRequestId =
        (data['requestId'] ?? '')
            .toString()
            .trim();

    if (storedRequestId.isNotEmpty &&
        storedRequestId != requestId) {
      throw Exception(
        'Walk ID verification failed.',
      );
    }

    // ==========================================================
    // STATUS
    // ==========================================================

    final String status =
        (data['status'] ?? 'ACTIVE')
            .toString()
            .trim()
            .toUpperCase();

    if (status == 'COMPLETED' ||
        status == 'ENDED') {
      throw Exception(
        'This Live Walk has already ended.',
      );
    }

    // ==========================================================
    // OWNER VERIFICATION
    // ==========================================================

    final String sessionOwnerUid =
        (data['ownerUid'] ?? '')
            .toString()
            .trim();

    final String sessionOwnerId =
        (data['ownerId'] ?? '')
            .toString()
            .trim();

    if (walk.ownerUid.isNotEmpty &&
        sessionOwnerUid.isNotEmpty &&
        walk.ownerUid != sessionOwnerUid) {
      throw Exception(
        'Owner verification failed.',
      );
    }

    if (walk.ownerId.isNotEmpty &&
        sessionOwnerId.isNotEmpty &&
        walk.ownerId != sessionOwnerId) {
      throw Exception(
        'Owner ID verification failed.',
      );
    }

    // ==========================================================
    // EXISTING WALKER
    // ==========================================================

    final String existingWalkerUid =
        (data['walkerUid'] ?? '')
            .toString()
            .trim();

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid) {
      throw Exception(
        'This Live Walk is already connected with another walker.',
      );
    }

    // ==========================================================
    // WALKER BUSINESS ID
    // ==========================================================

    final String walkerId =
        await _getWalkerBusinessId(
      walkerUid,
    );

    final String walkerName =
        _walkerName();

    final String walkerPhone =
        _walkerPhone();

    // ==========================================================
    // ATTACH WALKER
    // ==========================================================

    await sessionRef.set(
      <String, dynamic>{
        // FINAL CANONICAL ID
        'requestId': requestId,

        // Compatibility only.
        // Both refer to the same ID.
        'sessionId': requestId,

        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'walkerPhone': walkerPhone,

        'connectionStatus': 'connected',
        'walkerConnected': true,
        'connectedBy': walkerUid,
        'connectedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return requestId;
  }

  // ============================================================
  // GET WALKER BUSINESS ID
  // ============================================================

  static Future<String> _getWalkerBusinessId(
    String walkerUid,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection('phoneAccounts')
            .doc(walkerUid)
            .get();

    final Map<String, dynamic>? data =
        snapshot.data();

    final String walkerId =
        (data?['walkerId'] ?? '')
            .toString()
            .trim();

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    return walkerId;
  }

  // ============================================================
  // WALKER NAME
  // ============================================================

  static String _walkerName() {
    final User? walker =
        _currentWalker;

    final String name =
        walker?.displayName?.trim() ??
            '';

    return name.isEmpty
        ? 'Walker'
        : name;
  }

  // ============================================================
  // WALKER PHONE
  // ============================================================

  static String _walkerPhone() {
    final User? walker =
        _currentWalker;

    return walker?.phoneNumber?.trim() ??
        '';
  }

  // ============================================================
  // CONNECT WALK REQUEST
  // ============================================================

  static Future<String> _connectWalkRequest(
    WalkerWalkData walk,
    String walkerUid,
  ) async {
    final String requestId =
        walk.requestId.trim();

    if (!_isValidRequestId(requestId)) {
      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        requestRef =
        _walkRequests.doc(requestId);

    final DocumentSnapshot<Map<String, dynamic>>
        existing =
        await requestRef.get();

    if (!existing.exists) {
      throw Exception(
        'Walk request not found.',
      );
    }

    final Map<String, dynamic> data =
        existing.data() ??
            <String, dynamic>{};

    // ==========================================================
    // VERIFY DOCUMENT ID
    // ==========================================================

    if (existing.id != requestId) {
      throw Exception(
        'Walk ID verification failed.',
      );
    }

    // ==========================================================
    // STATUS
    // ==========================================================

    final String status =
        (data['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    if (status == 'completed' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'expired' ||
        status == 'rejected') {
      throw Exception(
        'This Walk is no longer available.',
      );
    }

    // ==========================================================
    // OWNER VERIFICATION
    // ==========================================================

    final String storedOwnerUid =
        (data['ownerUid'] ?? '')
            .toString()
            .trim();

    if (walk.ownerUid.isNotEmpty &&
        storedOwnerUid.isNotEmpty &&
        walk.ownerUid != storedOwnerUid) {
      throw Exception(
        'Owner verification failed.',
      );
    }

    // ==========================================================
    // EXISTING WALKER
    // ==========================================================

    final String existingWalkerUid =
        (data['walkerUid'] ?? '')
            .toString()
            .trim();

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid) {
      throw Exception(
        'This Walk is already assigned to another walker.',
      );
    }

    // ==========================================================
    // WALKER BUSINESS ID
    // ==========================================================

    final String walkerId =
        await _getWalkerBusinessId(
      walkerUid,
    );

    final String walkerName =
        _walkerName();

    final String walkerPhone =
        _walkerPhone();

    // ==========================================================
    // UPDATE REQUEST
    // ==========================================================

    await requestRef.set(
      <String, dynamic>{
        'requestId': requestId,

        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'walkerPhone': walkerPhone,

        'status': 'accepted',

        'acceptedBy': walkerUid,
        'acceptedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return requestId;
  }

  // ============================================================
  // SCAN + CONNECT
  // ============================================================

  static Future<String?> scanAndConnect(
    BuildContext context,
  ) async {
    final WalkerWalkData? walk =
        await scanOwnerQr(context);

    if (walk == null) {
      return null;
    }

    try {
      final String requestId =
          await connectWithOwner(walk);

      if (!context.mounted) {
        return requestId;
      }

      _showMessage(
        context,
        'Owner connected successfully.',
      );

      return requestId;
    } catch (e) {
      if (!context.mounted) {
        return null;
      }

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      _showMessage(
        context,
        'Could not connect: $message',
      );

      return null;
    }
  }

  // ============================================================
  // SCAN + CONNECT + OPEN LIVE WALK
  // ============================================================

  static Future<void>
      scanConnectAndOpenLiveWalk(
    BuildContext context,
  ) async {
    final WalkerWalkData? walk =
        await scanOwnerQr(context);

    if (walk == null) {
      return;
    }

    try {
      await connectWithOwner(walk);

      if (!context.mounted) {
        return;
      }

      await openLiveWalk(
        context,
        walk,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      _showMessage(
        context,
        'Could not start Live Walk: $message',
      );
    }
  }

  // ============================================================
  // OPEN LIVE WALK
  // ============================================================

  static Future<void> openLiveWalk(
    BuildContext context,
    WalkerWalkData walk,
  ) async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      _showMessage(
        context,
        'Walker is not logged in.',
      );
      return;
    }

    // ==========================================================
    // OWNER UID
    // ==========================================================

    final String ownerId =
        walk.ownerId.trim();

    final String ownerUid =
        walk.ownerUid.trim();

    final String finalOwnerUid =
        ownerUid.isNotEmpty
            ? ownerUid
            : ownerId;

    if (finalOwnerUid.isEmpty) {
      _showMessage(
        context,
        'Owner ID is missing.',
      );
      return;
    }

    // ==========================================================
    // REQUEST ID
    // ==========================================================

    final String requestId =
        walk.requestId.trim();

    if (!_isValidRequestId(requestId)) {
      _showMessage(
        context,
        'Invalid Walk ID. Expected DW######.',
      );
      return;
    }

    if (!context.mounted) {
      return;
    }

    // ==========================================================
    // OPEN LIVE WALK
    //
    // NO sessionId
    // NO walkId
    //
    // requestId is used everywhere.
    // ==========================================================

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return LiveWalkScreen(
            ownerUid: finalOwnerUid,
            ownerName: walk.ownerName,
            requestId: requestId,
            dogName: walk.dogName,
            dogBreed: walk.dogBreed,
            ownerPhone: walk.ownerPhone,
          );
        },
      ),
    );
  }

  // ============================================================
  // GET MY LIVE WALK SESSION
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>?>
      getMyLiveWalkSession() async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      return null;
    }

    final QuerySnapshot<
        Map<String, dynamic>> result =
        await _liveWalkSessions
            .where(
              'walkerUid',
              isEqualTo: walker.uid,
            )
            .where(
              'status',
              isEqualTo: 'ACTIVE',
            )
            .limit(1)
            .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first;
  }

  // ============================================================
  // WATCH LIVE SESSION
  // ============================================================

  static Stream<
      DocumentSnapshot<Map<String, dynamic>>>
      watchLiveSession(
    String requestId,
  ) {
    final String cleanRequestId =
        requestId.trim();

    return _liveWalkSessions
        .doc(cleanRequestId)
        .snapshots();
  }

  // ============================================================
  // UPDATE WALKER LOCATION
  // ============================================================

  static Future<void> updateWalkerLocation({
    required String requestId,
    required double latitude,
    required double longitude,
  }) async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String cleanRequestId =
        requestId.trim();

    if (!_isValidRequestId(
      cleanRequestId,
    )) {
      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    final Map<String, dynamic>
        locationData =
        <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };

    // ==========================================================
    // LIVE SESSION
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        sessionRef =
        _liveWalkSessions.doc(
      cleanRequestId,
    );

    await sessionRef.set(
      <String, dynamic>{
        'requestId': cleanRequestId,
        'sessionId': cleanRequestId,

        'currentLocation': <
            String, dynamic>{
          'lat': latitude,
          'lng': longitude,
        },

        'walkerLocation':
            locationData,

        'walkerLocationUpdatedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // COMPLETE WALK
  // ============================================================

  static Future<void> completeWalk({
    required String requestId,
  }) async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String cleanRequestId =
        requestId.trim();

    if (!_isValidRequestId(
      cleanRequestId,
    )) {
      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    await _completeLiveSession(
      cleanRequestId,
      walker.uid,
    );
  }

  // ============================================================
  // COMPLETE LIVE SESSION
  // ============================================================

  static Future<void> _completeLiveSession(
    String requestId,
    String walkerUid,
  ) async {
    final String cleanRequestId =
        requestId.trim();

    if (!_isValidRequestId(
      cleanRequestId,
    )) {
      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        sessionRef =
        _liveWalkSessions.doc(
      cleanRequestId,
    );

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await sessionRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Live Walk session not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // REQUEST ID VERIFICATION
    // ==========================================================

    final String storedRequestId =
        (data['requestId'] ?? '')
            .toString()
            .trim();

    if (storedRequestId.isNotEmpty &&
        storedRequestId != cleanRequestId) {
      throw Exception(
        'Walk ID verification failed.',
      );
    }

    // ==========================================================
    // WALKER VERIFICATION
    // ==========================================================

    final String existingWalkerUid =
        (data['walkerUid'] ?? '')
            .toString()
            .trim();

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid) {
      throw Exception(
        'You cannot complete another walker\'s Live Walk.',
      );
    }

    // ==========================================================
    // HISTORY
    //
    // SAME DOCUMENT ID
    //
    // walk_history/DW000001
    // ==========================================================

    await _firestore
        .collection('walk_history')
        .doc(cleanRequestId)
        .set(
      <String, dynamic>{
        ...data,

        'requestId':
            cleanRequestId,

        'sessionId':
            cleanRequestId,

        'status':
            'completed',

        'isLive':
            false,

        'connectionStatus':
            'completed',

        'walkEnded':
            true,

        'trackingEnded':
            true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walkerUid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ==========================================================
    // COMPLETE LIVE SESSION
    // ==========================================================

    await sessionRef.set(
      <String, dynamic>{
        'requestId':
            cleanRequestId,

        'sessionId':
            cleanRequestId,

        'status':
            'COMPLETED',

        'connectionStatus':
            'completed',

        'walkEnded':
            true,

        'trackingEnded':
            true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walkerUid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ==========================================================
    // COMPLETE WALK REQUEST
    //
    // walk_request/DW000001
    // ==========================================================

    await _walkRequests
        .doc(cleanRequestId)
        .set(
      <String, dynamic>{
        'requestId':
            cleanRequestId,

        'status':
            'completed',

        'walkEnded':
            true,

        'trackingEnded':
            true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walkerUid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  static void _showMessage(
    BuildContext context,
    String message,
  ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
}

/// ============================================================
/// WALKER WALK DATA
///
/// FINAL:
///
/// requestId is the only canonical Walk ID.
///
/// Legacy getters are kept ONLY to avoid breaking old callers
/// immediately. They all return the same requestId.
/// ============================================================

class WalkerWalkData {
  final String ownerId;

  /// Firebase Auth UID of owner.
  final String ownerUid;

  final String ownerName;

  final String? ownerPhone;

  /// ==========================================================
  /// CANONICAL WALK / REQUEST ID
  /// ==========================================================

  final String requestId;

  final String dogName;

  final String dogBreed;

  /// qr / insta / etc.
  final String source;

  const WalkerWalkData({
    required this.ownerId,
    this.ownerUid = '',
    required this.ownerName,
    this.ownerPhone,
    required this.requestId,
    required this.dogName,
    required this.dogBreed,
    this.source = 'qr',
  });

  // ============================================================
  // LEGACY COMPATIBILITY
  //
  // DO NOT use these for new code.
  //
  // They all point to requestId.
  // ============================================================

  String get walkId =>
      requestId;

  String get sessionId =>
      requestId;

  String get activeWalkId =>
      requestId;

  String get liveWalkSessionId =>
      requestId;

  // ============================================================
  // VALID REQUEST ID
  // ============================================================

  bool get hasValidRequestId {
    return RegExp(
      r'^DW\d{6}$',
    ).hasMatch(
      requestId.trim(),
    );
  }

  // ============================================================
  // QR FLOW
  // ============================================================

  bool get isQrFlow {
    return source
            .trim()
            .toLowerCase() ==
        'qr';
  }

  // ============================================================
  // INSTA FLOW
  // ============================================================

  bool get isInstaFlow {
    return source
            .trim()
            .toLowerCase() ==
        'insta';
  }
}
