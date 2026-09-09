// File:
// lib/features/qr_walk/services/qr_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class QrWalkService {
  QrWalkService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

    final Map<String, dynamic> qrData =
        _decodeQrPayload(cleanData);

    _log('STEP 3 OK');

    // ========================================================
    // 4. VALIDATE QR TYPE
    // ========================================================

    final String qrType = _readString(
      qrData,
      <String>['type'],
    );

    if (qrType.isNotEmpty &&
        qrType != 'dojo_owner_qr') {
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
        connectionSnapshot.data() ??
            <String, dynamic>{};

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

    final bool connected =
        connectionData['connected'] == true;

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
    // 15. GET FRESH WALKER GPS
    //
    // This location is captured at QR connection time.
    // It becomes the fixed pickup location.
    // ========================================================

    _log('STEP 15: Requesting fresh GPS location...');

    final Position? pickupPosition =
        await _getVerifiedFreshLocation();

    if (pickupPosition == null) {
      _log('STEP 15 FAILED: Verified fresh GPS unavailable');

      throw Exception(
        'Unable to get a verified current location. '
        'Please turn on GPS and try again.',
      );
    }

    final double pickupLatitude =
        pickupPosition.latitude;

    final double pickupLongitude =
        pickupPosition.longitude;

    final double pickupAccuracy =
        pickupPosition.accuracy;

    final Map<String, double> pickupLocation =
        <String, double>{
      'lat': pickupLatitude,
      'lng': pickupLongitude,
    };

    _log(
      'STEP 15 OK: Fresh pickup location '
      '$pickupLatitude, $pickupLongitude '
      '(accuracy ${pickupAccuracy.toStringAsFixed(1)}m)',
    );

    // ========================================================
    // 16. WALKER ACCOUNT
    // ========================================================

    DocumentSnapshot<Map<String, dynamic>>
        walkerAccountSnapshot;

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
        //
        // This is the fresh Walker GPS position captured
        // at QR connection time.
        //
        'pickupLocation': pickupLocation,

        // WALKER LIVE LOCATION
        //
        // This remains separate and will be updated later
        // by the existing Walker GPS / Live Walk system.
        //
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
    // 24. RETURN LIVE WALK DATA
    // ========================================================

    final Map<String, dynamic> result =
        <String, dynamic>{
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

    _log('STEP 24 OK');
    _log('========== QR WALK SUCCESS ==========');

    return result;
  }

  // ==========================================================
  // GET VERIFIED FRESH LOCATION
  // ==========================================================

  Future<Position?> _getVerifiedFreshLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _log('GPS is disabled');
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _log(
          'GPS permission unavailable: $permission',
        );
        return null;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      final double latitude = position.latitude;
      final double longitude = position.longitude;
      final double accuracy = position.accuracy;

      if (latitude == 0.0 && longitude == 0.0) {
        _log('Rejected GPS: 0,0 location');
        return null;
      }

      if (!latitude.isFinite ||
          !longitude.isFinite ||
          !accuracy.isFinite) {
        _log('Rejected GPS: invalid coordinate values');
        return null;
      }

      // Reject an inaccurate GPS fix.
      if (accuracy > 50.0) {
        _log(
          'Rejected GPS: accuracy '
          '${accuracy.toStringAsFixed(1)}m > 50m',
        );
        return null;
      }

      final DateTime now = DateTime.now();
      final Duration age =
          now.difference(position.timestamp);

      if (age.inSeconds.abs() > 30) {
        _log(
          'Rejected GPS: location age '
          '${age.inSeconds.abs()}s > 30s',
        );
        return null;
      }

      _log(
        'Verified fresh GPS: '
        '$latitude, $longitude '
        'accuracy=${accuracy.toStringAsFixed(1)}m '
        'age=${age.inSeconds.abs()}s',
      );

      return position;
    } on TimeoutException {
      _log('Fresh GPS timeout');
      return null;
    } on LocationServiceDisabledException {
      _log('GPS disabled while getting fresh location');
      return null;
    } on PermissionDeniedException {
      _log('GPS permission denied while getting fresh location');
      return null;
    } catch (error, stackTrace) {
      _log('Fresh GPS error: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  // ==========================================================
  // DECODE QR PAYLOAD
  // ==========================================================

  Map<String, dynamic> _decodeQrPayload(
    String rawData,
  ) {
    try {
      final dynamic decoded =
          jsonDecode(rawData);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Try URI format below.
    }

    final Uri? uri =
        Uri.tryParse(rawData);

    if (uri != null &&
        uri.queryParameters.isNotEmpty) {
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

      final String text =
          value.toString().trim();

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
      final String text =
          value?.trim() ?? '';

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
    debugPrint(
      '[QR WALK] $message',
    );
  }
}
