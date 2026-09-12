import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/walker_availability_service.dart';
import '../../../services/walker_location_service.dart';

class QrWalkService {
  QrWalkService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    WalkerAvailabilityService? availabilityService,
    WalkerLocationService? locationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _availabilityService =
            availabilityService ?? WalkerAvailabilityService.instance,
        _locationService =
            locationService ?? WalkerLocationService.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final WalkerAvailabilityService _availabilityService;
  final WalkerLocationService _locationService;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  CollectionReference<Map<String, dynamic>> get _qrConnections =>
      _firestore.collection('qr_connections');

  CollectionReference<Map<String, dynamic>> get _liveWalkSessions =>
      _firestore.collection('liveWalkSessions');

  // ==========================================================
  // PROCESS OWNER QR
  // ==========================================================

  Future<Map<String, dynamic>> processOwnerQr({
    required String rawData,
  }) async {
    _log('========== QR WALK START ==========');

    // ========================================================
    // 0. ONLINE CHECK
    //
    // QR WALK IS AVAILABLE ONLY WHILE WALKER IS ONLINE.
    //
    // GPS lifecycle remains owned by
    // WalkerAvailabilityService.
    // ========================================================

    if (!_availabilityService.isOnline) {
      _log('STEP 0 FAILED: Walker is Offline');

      throw Exception(
        'You must be Online to scan and connect an Owner QR.',
      );
    }

    if (!_availabilityService.canPerformWalkAction()) {
      _log('STEP 0 FAILED: Walk action unavailable');

      throw Exception(
        _availabilityService.unavailableMessage,
      );
    }

    _log('STEP 0 OK: Walker is Online');

    // ========================================================
    // 1. VALIDATE RAW QR
    // ========================================================

    final String cleanData = rawData.trim();

    if (cleanData.isEmpty) {
      _log('STEP 1 FAILED: Empty QR');
      throw Exception('Invalid QR code.');
    }

    _log('STEP 1 OK');

    // ========================================================
    // 2. CURRENT WALKER
    // ========================================================

    final User? walker = _auth.currentUser;

    if (walker == null) {
      _log('STEP 2 FAILED: Walker not logged in');
      throw Exception('Walker is not logged in.');
    }

    final String walkerUid = walker.uid.trim();

    if (walkerUid.isEmpty) {
      _log('STEP 2 FAILED: Walker UID missing');
      throw Exception('Walker Firebase UID is missing.');
    }

    _log('STEP 2 OK');

    // ========================================================
    // 3. DECODE QR
    // ========================================================

    final Map<String, dynamic> qrData = _decodeQrPayload(cleanData);

    _log('STEP 3 OK');

    // ========================================================
    // 4. VALIDATE QR TYPE
    // ========================================================

    final String qrType = _readString(
      qrData,
      <String>['type'],
    );

    if (qrType.isNotEmpty && qrType != 'dojo_owner_qr') {
      _log('STEP 4 FAILED: Invalid QR type');

      throw Exception(
        'This QR code is not a valid Dojo Owner QR.',
      );
    }

    _log('STEP 4 OK');

    // ========================================================
    // 5. OWNER ID
    // ========================================================

    final String ownerId = _readString(
      qrData,
      <String>[
        'ownerId',
        'ownerBusinessId',
        'ownerBusinessID',
      ],
    );

    if (ownerId.isEmpty) {
      _log('STEP 5 FAILED: Owner ID missing');

      throw Exception(
        'Owner Business ID is missing from QR code.',
      );
    }

    _log('STEP 5 OK');

    // ========================================================
    // 6. REQUEST / WALK ID
    // ========================================================

    String requestId = _readString(
      qrData,
      <String>[
        'requestId',
        'walkId',
        'qrWalkId',
      ],
    );

    requestId = requestId.trim();

    if (requestId.isEmpty) {
      _log('STEP 6 FAILED: Walk ID missing');

      throw Exception(
        'Walk ID is missing from QR code.',
      );
    }

    _log('STEP 6 OK: $requestId');

    // ========================================================
    // 7. VALIDATE WALK ID
    // ========================================================

    if (!_isValidRequestId(requestId)) {
      _log('STEP 7 FAILED: Invalid Walk ID');

      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    _log('STEP 7 OK');

    // ========================================================
    // 8. READ QR CONNECTION
    // ========================================================

    final DocumentReference<Map<String, dynamic>> connectionRef =
        _qrConnections.doc(ownerId);

    DocumentSnapshot<Map<String, dynamic>> connectionSnapshot;

    try {
      connectionSnapshot = await connectionRef.get();
    } catch (error) {
      _log('STEP 8 FAILED: qr_connections READ');
      _log('ERROR: $error');

      throw Exception(
        'QR STEP 8 - qr_connections READ failed: $error',
      );
    }

    if (!connectionSnapshot.exists) {
      _log('STEP 8 FAILED: QR connection not found');

      throw Exception(
        'Owner QR session was not found or has expired.',
      );
    }

    final Map<String, dynamic> connectionData =
        connectionSnapshot.data() ?? <String, dynamic>{};

    _log('STEP 8 OK');

    // ========================================================
    // 9. VERIFY OWNER ID
    // ========================================================

    final String firebaseOwnerId = _readString(
      connectionData,
      <String>['ownerId'],
    );

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

    _log('STEP 9 OK');

    // ========================================================
    // 10. VERIFY FIRESTORE WALK ID
    // ========================================================

    final String firebaseRequestId = _readString(
      connectionData,
      <String>[
        'requestId',
        'walkId',
        'activeWalkId',
      ],
    );

    if (firebaseRequestId.isEmpty) {
      throw Exception(
        'Owner Walk ID is missing in Firebase.',
      );
    }

    if (!_isValidRequestId(firebaseRequestId)) {
      throw Exception(
        'Invalid Walk ID in Firebase.',
      );
    }

    if (firebaseRequestId != requestId) {
      throw Exception(
        'Walk ID verification failed.',
      );
    }

    _log('STEP 10 OK');

    // ========================================================
    // 11. OWNER FIREBASE UID
    // ========================================================

    final String ownerUid = _readString(
      connectionData,
      <String>[
        'ownerUid',
        'ownerAuthUid',
        'authUid',
        'firebaseUid',
      ],
    );

    if (ownerUid.isEmpty) {
      throw Exception(
        'Owner Firebase UID is missing.',
      );
    }

    if (ownerUid == walkerUid) {
      throw Exception(
        'Owner and Walker cannot be the same account.',
      );
    }

    _log('STEP 11 OK');

    // ========================================================
    // 12. OWNER DATA
    // ========================================================

    String ownerName = _firstNonEmpty(
      <String?>[
        connectionData['ownerName']?.toString(),
        qrData['ownerName']?.toString(),
      ],
    );

    if (ownerName.isEmpty) {
      ownerName = 'Owner';
    }

    final String ownerPhone = _firstNonEmpty(
      <String?>[
        connectionData['ownerPhone']?.toString(),
        qrData['ownerPhone']?.toString(),
      ],
    );

    // ========================================================
    // 13. DOG DATA
    // ========================================================

    String dogName = _firstNonEmpty(
      <String?>[
        connectionData['dogName']?.toString(),
        qrData['dogName']?.toString(),
      ],
    );

    if (dogName.isEmpty) {
      dogName = 'Dog';
    }

    final String dogBreed = _firstNonEmpty(
      <String?>[
        connectionData['dogBreed']?.toString(),
        qrData['dogBreed']?.toString(),
      ],
    );

    _log('STEP 12-13 OK');

    // ========================================================
    // 14. CHECK EXISTING QR CONNECTION
    // ========================================================

    final bool connected = connectionData['connected'] == true;

    final String existingWalkerUid = _readString(
      connectionData,
      <String>['walkerUid'],
    );

    if (connected &&
        existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid) {
      _log('STEP 14 FAILED: Another walker connected');

      throw Exception(
        'This Owner QR is already connected to another walker.',
      );
    }

    _log('STEP 14 OK');

    // ========================================================
    // 15. GET CURRENT WALKER LOCATION
    //
    // IMPORTANT:
    // QR DOES NOT START GPS.
    //
    // GPS is already controlled globally by
    // WalkerAvailabilityService.
    //
    // We first use the canonical current position.
    // If it is temporarily unavailable, ask the canonical
    // location service for a current position.
    // ========================================================

    _log('STEP 15: Reading canonical Walker GPS...');

    Position? pickupPosition = _locationService.currentPosition;

    if (pickupPosition == null) {
      _log(
        'STEP 15: Canonical current position unavailable. '
        'Requesting current position from location service.',
      );

      try {
        pickupPosition = await _locationService.getCurrentLocation();
      } catch (error) {
        _log('STEP 15 FAILED: Current GPS unavailable');
        _log('ERROR: $error');
      }
    }

    if (pickupPosition == null) {
      _log('STEP 15 FAILED: Current GPS unavailable');

      throw Exception(
        'Unable to get your current location. '
        'Please make sure GPS is available and try again.',
      );
    }

    // Online must still be true after the asynchronous GPS read.
    if (!_availabilityService.isOnline) {
      _log('STEP 15 FAILED: Walker became Offline');

      throw Exception(
        'Walker went Offline. Please stay Online to continue.',
      );
    }

    final double pickupLatitude = pickupPosition.latitude;
    final double pickupLongitude = pickupPosition.longitude;
    final double pickupAccuracy = pickupPosition.accuracy;

    if (!pickupLatitude.isFinite ||
        !pickupLongitude.isFinite ||
        !pickupAccuracy.isFinite ||
        (pickupLatitude == 0.0 && pickupLongitude == 0.0)) {
      _log('STEP 15 FAILED: Invalid GPS coordinates');

      throw Exception(
        'Unable to get a valid current location. '
        'Please try again.',
      );
    }

    final Map<String, double> pickupLocation = <String, double>{
      'lat': pickupLatitude,
      'lng': pickupLongitude,
    };

    _log(
      'STEP 15 OK: Canonical pickup location '
      '$pickupLatitude, $pickupLongitude '
      '(accuracy ${pickupAccuracy.toStringAsFixed(1)}m)',
    );

    // ========================================================
    // 16. WALKER ACCOUNT
    // ========================================================

    DocumentSnapshot<Map<String, dynamic>> walkerAccountSnapshot;

    try {
      walkerAccountSnapshot = await _firestore
          .collection('phoneAccounts')
          .doc(walkerUid)
          .get();
    } catch (error) {
      _log('STEP 16 FAILED: phoneAccounts READ');
      _log('ERROR: $error');

      throw Exception(
        'QR STEP 16 - phoneAccounts READ failed: $error',
      );
    }

    final Map<String, dynamic>? walkerAccountData =
        walkerAccountSnapshot.data();

    _log(
      'STEP 16 OK: exists=${walkerAccountSnapshot.exists}',
    );

    // ========================================================
    // 17. WALKER BUSINESS ID
    // ========================================================

    final String walkerId = _firstNonEmpty(
      <String?>[
        walkerAccountData?['walkerId']?.toString(),
        walkerAccountData?['Walker Id']?.toString(),
        walkerAccountData?['Walker ID']?.toString(),
        walkerAccountData?['walkerBusinessId']?.toString(),
        walkerAccountData?['walkerBusinessID']?.toString(),
        walkerAccountData?['businessId']?.toString(),
        walkerAccountData?['Business ID']?.toString(),
      ],
    );

    if (walkerId.isEmpty) {
      _log('STEP 17 FAILED: Walker Business ID missing');

      throw Exception(
        'Walker Business ID not found.',
      );
    }

    _log('STEP 17 OK');

    // ========================================================
    // 18. WALKER NAME
    // ========================================================

    String walkerName = _firstNonEmpty(
      <String?>[
        walkerAccountData?['walkerName']?.toString(),
        walkerAccountData?['name']?.toString(),
        walkerAccountData?['Full Name']?.toString(),
        walkerAccountData?['Name']?.toString(),
        walker.displayName,
      ],
    );

    if (walkerName.isEmpty) {
      walkerName = 'Walker';
    }

    _log('STEP 18 OK');

    // ========================================================
    // 19. SESSION REFERENCE
    // ========================================================

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _liveWalkSessions.doc(requestId);

    _log(
      'STEP 19 OK: Prepared liveWalkSessions/$requestId',
    );

    // ========================================================
    // IMPORTANT
    //
    // DO NOT READ liveWalkSessions HERE.
    //
    // QR SCAN MUST CREATE THE SESSION DIRECTLY.
    //
    // ========================================================

    // ========================================================
    // 20. PREPARE BATCH
    // ========================================================

    final FieldValue serverTimestamp =
        FieldValue.serverTimestamp();

    final WriteBatch batch = _firestore.batch();

    _log('STEP 20 OK: Batch prepared');

    // ========================================================
    // 21. UPDATE QR CONNECTION
    // ========================================================

    batch.set(
      connectionRef,
      <String, dynamic>{
        'type': 'dojo_owner_qr',
        'version': 2,

        // OWNER
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // WALK
        'requestId': requestId,
        'walkId': requestId,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // WALKER
        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,

        // CONNECTION
        'scanned': true,
        'connected': true,

        // FIXED PICKUP LOCATION
        'pickupLocation': pickupLocation,

        // SESSION
        'liveSessionId': requestId,
        'activeWalkId': requestId,

        // TIMESTAMPS
        'scannedAt': serverTimestamp,
        'connectedAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      },
      SetOptions(merge: true),
    );

    _log(
      'STEP 21 OK: QR connection prepared '
      'with fixed pickup location',
    );

    // ========================================================
    // 22. CREATE LIVE WALK SESSION
    // ========================================================

    batch.set(
      sessionRef,
      <String, dynamic>{
        // IDENTIFIERS
        'sessionId': requestId,
        'requestId': requestId,
        'walkId': requestId,

        // SOURCE
        'source': 'qr',
        'startedFromQr': true,

        // OWNER
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // WALKER
        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // FIXED PICKUP LOCATION
        'pickupLocation': pickupLocation,

        // WALKER LIVE LOCATION
        'currentLocation': <String, double>{
          'lat': 0.0,
          'lng': 0.0,
        },

        // STATS
        'distanceKm': 0.0,
        'elapsedSeconds': 0,
        'peeCount': 0,
        'poopCount': 0,

        // EVENTS / ROUTE
        'events': <Map<String, dynamic>>[],
        'routeCoordinates': <Map<String, dynamic>>[],

        // STATUS
        'status': 'READY',
        'walkStarted': false,
        'walkEnded': false,
        'trackingStarted': false,
        'trackingEnded': false,

        // TIMESTAMPS
        'startedAt': null,
        'endedAt': null,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      },
      SetOptions(merge: true),
    );

    _log(
      'STEP 22 OK: Live session create prepared '
      'with pickup location',
    );

    // ========================================================
    // 23. COMMIT
    // ========================================================

    try {
      // Final Online check immediately before Firestore write.
      if (!_availabilityService.isOnline) {
        throw Exception(
          'Walker went Offline. Please stay Online to continue.',
        );
      }

      await batch.commit();

      _log('STEP 23 OK: Firestore batch committed');
    } catch (error) {
      _log('STEP 23 FAILED: Firestore batch commit');
      _log('ERROR: $error');

      throw Exception(
        'QR STEP 23 - Firestore WRITE failed: $error',
      );
    }

    // ========================================================
    // 24. MARK ACTIVE WALK
    //
    // GPS remains ON because the global availability service
    // owns the lifecycle.
    // ========================================================

    _availabilityService.setActiveWalk(true);

    // ========================================================
    // 25. RETURN LIVE WALK DATA
    // ========================================================

    final Map<String, dynamic> result = <String, dynamic>{
      'ownerId': ownerId,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,

      'walkerId': walkerId,
      'walkerUid': walkerUid,
      'walkerName': walkerName,

      'requestId': requestId,
      'walkId': requestId,
      'liveSessionId': requestId,
      'sessionId': requestId,

      'dogName': dogName,
      'dogBreed': dogBreed,

      // FIXED QR PICKUP LOCATION
      'pickupLocation': pickupLocation,

      'status': 'READY',

      'source': 'qr',
      'startedFromQr': true,
      'existingSession': false,
    };

    _log('STEP 25 OK');
    _log('========== QR WALK SUCCESS ==========');

    return result;
  }

  // ==========================================================
  // DECODE QR PAYLOAD
  // ==========================================================

  Map<String, dynamic> _decodeQrPayload(
    String rawData,
  ) {
    try {
      final dynamic decoded = jsonDecode(rawData);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Try URI format below.
    }

    final Uri? uri = Uri.tryParse(rawData);

    if (uri != null && uri.queryParameters.isNotEmpty) {
      return <String, dynamic>{
        ...uri.queryParameters,
      };
    }

    throw Exception(
      'QR code format is invalid.',
    );
  }

  // ==========================================================
  // READ STRING
  // ==========================================================

  String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ==========================================================
  // FIRST NON EMPTY
  // ==========================================================

  String _firstNonEmpty(
    List<String?> values,
  ) {
    for (final String? value in values) {
      final String text = value?.trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ==========================================================
  // WALK ID VALIDATION
  // ==========================================================

  bool _isValidRequestId(
    String requestId,
  ) {
    return RegExp(
      r'^DW\d{6}$',
    ).hasMatch(
      requestId.trim(),
    );
  }

  // ==========================================================
  // DEBUG LOG
  // ==========================================================

  void _log(String message) {
    debugPrint('[QR WALK] $message');
  }
}
