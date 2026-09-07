// File:
// lib/features/insta_walk/services/insta_walk_reach_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class InstaWalkReachService {
  InstaWalkReachService._();

  static final InstaWalkReachService instance =
      InstaWalkReachService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// ============================================================
  /// CREATE LIVE WALK SESSION
  ///
  /// Flow:
  ///
  /// walk_request
  ///     accepted
  ///        ↓
  /// Walker reaches owner
  ///        ↓
  /// walk_request.reached = true
  ///        ↓
  /// liveWalkSessions/{walkId}
  ///        ↓
  /// LiveWalkScreen
  ///
  /// FINAL WALK ID FORMAT:
  ///
  ///   DW-000001
  ///   DW-000002
  ///   DW-000003
  ///
  /// One Walk = One Walk ID = One Live Session ID
  ///
  /// Walker details shared:
  ///
  ///   walkerId
  ///   walkerUid
  ///   walkerName
  ///   walkerPhone
  ///   walkerProfileImage
  ///
  /// Owner data comes from walk_request.
  /// ============================================================

  Future<String> createLiveWalkSession({
    required String walkRequestId,
    required String walkerUid,
    required String walkerId,
    String? walkerName,
    String? walkerPhone,
    String? walkerProfileImage,
  }) async {
    final String requestId =
        walkRequestId.trim();

    final String uid =
        walkerUid.trim();

    final String id =
        walkerId.trim();

    // ==========================================================
    // BASIC VALIDATION
    // ==========================================================

    if (requestId.isEmpty) {
      throw Exception(
        'Walk request ID is missing.',
      );
    }

    if (uid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    if (id.isEmpty) {
      throw Exception(
        'Walker ID is missing.',
      );
    }

    // ==========================================================
    // WALK REQUEST
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        requestRef =
        _firestore
            .collection('walk_request')
            .doc(requestId);

    final DocumentSnapshot<Map<String, dynamic>>
        requestSnapshot =
        await requestRef.get();

    if (!requestSnapshot.exists) {
      throw Exception(
        'Walk request not found.',
      );
    }

    final Map<String, dynamic>? requestData =
        requestSnapshot.data();

    if (requestData == null) {
      throw Exception(
        'Walk request data is unavailable.',
      );
    }

    // ==========================================================
    // STATUS
    // ==========================================================

    final String status =
        requestData['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status != 'accepted') {
      throw Exception(
        'This walk is not in accepted status.',
      );
    }

    // ==========================================================
    // VERIFY WALKER
    // ==========================================================

    final String existingWalkerUid =
        requestData['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid != uid) {
      throw Exception(
        'This walk is assigned to another Walker.',
      );
    }

    // ==========================================================
    // VERIFY ACCEPTED BY
    // ==========================================================

    final String acceptedBy =
        requestData['acceptedBy']
                ?.toString()
                .trim() ??
            '';

    if (acceptedBy.isNotEmpty &&
        acceptedBy != id &&
        existingWalkerUid != uid) {
      throw Exception(
        'This walk was accepted by another Walker.',
      );
    }

    // ==========================================================
    // FINAL WALK ID
    //
    // FORMAT:
    //
    // DW-000001
    // DW-000002
    // DW-000003
    //
    // IMPORTANT:
    // Firebase walk_request document ID is NOT the Walk ID.
    // ==========================================================

    final String walkId =
        requestData['walkId']
                ?.toString()
                .trim() ??
            '';

    if (walkId.isEmpty) {
      throw Exception(
        'Walk ID is missing from this walk request.',
      );
    }

    // ==========================================================
    // VALIDATE WALK ID
    // ==========================================================

    final bool isValidWalkId =
        RegExp(r'^DW-\d{6}$')
            .hasMatch(walkId);

    if (!isValidWalkId) {
      throw Exception(
        'Invalid Walk ID. Expected format: DW-000001.',
      );
    }

    // ==========================================================
    // OWNER DATA
    // ==========================================================

    final String ownerId =
        requestData['ownerId']
                ?.toString()
                .trim() ??
            '';

    final String ownerName =
        requestData['ownerName']
                ?.toString()
                .trim() ??
            '';

    final String ownerPhone =
        requestData['ownerPhone']
                ?.toString()
                .trim() ??
            '';

    final String ownerAuthUid =
        requestData['ownerAuthUid']
                ?.toString()
                .trim() ??
            '';

    final String ownerUid =
        ownerAuthUid.isNotEmpty
            ? ownerAuthUid
            : requestData['ownerUid']
                    ?.toString()
                    .trim() ??
                '';

    // ==========================================================
    // WALKER NAME
    // ==========================================================

    final String requestWalkerName =
        requestData['walkerName']
                ?.toString()
                .trim() ??
            '';

    final String finalWalkerName =
        walkerName?.trim().isNotEmpty == true
            ? walkerName!.trim()
            : requestWalkerName;

    // ==========================================================
    // WALKER PHONE
    // ==========================================================

    final String requestWalkerPhone =
        requestData['walkerPhone']
                ?.toString()
                .trim() ??
            '';

    final String finalWalkerPhone =
        walkerPhone?.trim().isNotEmpty == true
            ? walkerPhone!.trim()
            : requestWalkerPhone;

    // ==========================================================
    // WALKER PROFILE IMAGE
    // ==========================================================

    final String requestWalkerProfileImage =
        requestData['walkerProfileImage']
                ?.toString()
                .trim() ??
            '';

    final String finalWalkerProfileImage =
        walkerProfileImage?.trim().isNotEmpty == true
            ? walkerProfileImage!.trim()
            : requestWalkerProfileImage;

    // ==========================================================
    // DOG
    // ==========================================================

    final String dogName =
        requestData['dogName']
                ?.toString()
                .trim() ??
            '';

    final String dogBreed =
        requestData['dogBreed']
                ?.toString()
                .trim() ??
            '';

    final String dogPhoto =
        requestData['dogPhoto']
                ?.toString()
                .trim() ??
            '';

    // ==========================================================
    // ADDRESS
    // ==========================================================

    final String address =
        requestData['address']
                ?.toString()
                .trim() ??
            '';

    final dynamic ownerLocation =
        requestData['ownerLocation'];

    final String ownerLocationType =
        requestData['ownerLocationType']
                ?.toString()
                .trim() ??
            'search_snapshot';

    // ==========================================================
    // TIMESTAMP
    // ==========================================================

    final Timestamp now =
        Timestamp.now();

    // ==========================================================
    // LIVE WALK SESSION
    //
    // IMPORTANT:
    //
    // Document ID = WALK ID
    //
    // liveWalkSessions/DW-000001
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        sessionRef =
        _firestore
            .collection('liveWalkSessions')
            .doc(walkId);

    final Map<String, dynamic> sessionData =
        <String, dynamic>{
      // ========================================================
      // SESSION
      // ========================================================

      'sessionId': walkId,

      'walkId': walkId,

      'walkRequestId': requestId,

      // ========================================================
      // OWNER
      // ========================================================

      'ownerId': ownerId,

      'ownerName': ownerName,

      'ownerPhone': ownerPhone,

      'ownerUid': ownerUid,

      'ownerAuthUid': ownerAuthUid,

      // ========================================================
      // WALKER
      // ========================================================

      'walkerId': id,

      'walkerUid': uid,

      'walkerName': finalWalkerName,

      'walkerPhone': finalWalkerPhone,

      'walkerProfileImage':
          finalWalkerProfileImage,

      // ========================================================
      // DOG
      // ========================================================

      'dogName': dogName,

      'dogBreed': dogBreed,

      'dogPhoto': dogPhoto,

      // ========================================================
      // ADDRESS / OWNER LOCATION
      // ========================================================

      'address': address,

      'ownerLocation': ownerLocation,

      'ownerLocationType':
          ownerLocationType,

      // ========================================================
      // ACCEPTANCE
      // ========================================================

      'acceptedAt':
          requestData['acceptedAt'] ?? now,

      'acceptedBy':
          requestData['acceptedBy'] ?? id,

      // ========================================================
      // ARRIVAL
      // ========================================================

      'reachedAt': now,

      'arrivalDistanceKm':
          _toDouble(
        requestData['arrivalDistanceKm'],
      ),

      'arrivalDistanceMeters':
          _toInt(
        requestData['arrivalDistanceMeters'],
      ),

      'arrivalDurationMinutes':
          _toInt(
        requestData['arrivalDurationMinutes'],
      ),

      // ========================================================
      // LIVE WALK STATE
      // ========================================================

      'status': 'ready',

      'reached': true,

      'walkStarted': false,

      'walkEnded': false,

      'trackingStarted': false,

      'trackingEnded': false,

      'startedAt': null,

      'endedAt': null,

      'completedAt': null,

      // ========================================================
      // LIVE LOCATION
      // ========================================================

      'currentLocation':
          <String, dynamic>{
        'lat': 0.0,
        'lng': 0.0,
      },

      // ========================================================
      // WALK METRICS
      // ========================================================

      'distanceKm': 0.0,

      'elapsedSeconds': 0,

      'steps': 0,

      'peeCount': 0,

      'poopCount': 0,

      // ========================================================
      // ROUTE / EVENTS
      // ========================================================

      'routeCoordinates':
          <dynamic>[],

      'events':
          <dynamic>[],

      // ========================================================
      // SOURCE
      // ========================================================

      'source': 'insta_walk',

      'startedFromQr': false,

      // ========================================================
      // TIMESTAMPS
      // ========================================================

      'createdAt': now,

      'updatedAt': now,
    };

    // ==========================================================
    // ATOMIC BATCH
    // ==========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // 1. CREATE LIVE WALK SESSION
    // ----------------------------------------------------------

    batch.set(
      sessionRef,
      sessionData,
    );

    // ----------------------------------------------------------
    // 2. UPDATE WALK REQUEST
    // ----------------------------------------------------------
    //
    // IMPORTANT:
    // Do NOT put live GPS here.
    //
    // Walk ID remains unchanged.
    // ----------------------------------------------------------

    batch.update(
      requestRef,
      <String, dynamic>{
        'reached': true,

        'reachedAt': now,

        'arrivalDistanceKm':
            _toDouble(
          requestData['arrivalDistanceKm'],
        ),

        'arrivalDistanceMeters':
            _toInt(
          requestData['arrivalDistanceMeters'],
        ),

        'arrivalDurationMinutes':
            _toInt(
          requestData['arrivalDurationMinutes'],
        ),

        'updatedAt': now,
      },
    );

    // ==========================================================
    // COMMIT
    // ==========================================================

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      throw Exception(
        'Unable to create Live Walk session: '
        '${error.code} ${error.message ?? ''}'.trim(),
      );
    }

    // ==========================================================
    // RETURN WALK ID / SESSION ID
    //
    // Both are the same:
    //
    // DW-000001
    // ==========================================================

    return walkId;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
            value.trim(),
          ) ??
          0.0;
    }

    return 0.0;
  }

  // ============================================================
  // INT
  // ============================================================

  int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(
            value.trim(),
          ) ??
          0;
    }

    return 0;
  }
}
