import 'package:cloud_firestore/cloud_firestore.dart';

class AcceptWalkReachService {
  AcceptWalkReachService._();

  static final AcceptWalkReachService instance =
      AcceptWalkReachService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // CREATE / RESTORE LIVE WALK SESSION
  //
  // Canonical Walk ID:
  //
  // walk_request/{DW######}
  // liveWalkSessions/{DW######}
  //
  // Reach is idempotent:
  // if the Live Walk session already exists, it is NOT overwritten.
  // ============================================================

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

    if (!RegExp(r'^DW\d{6}$').hasMatch(requestId)) {
      throw Exception(
        'Invalid Walk Request ID. '
        'Expected format: DW000001.',
      );
    }

    final DocumentReference<Map<String, dynamic>> requestRef =
        _firestore
            .collection('walk_request')
            .doc(requestId);

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _firestore
            .collection('liveWalkSessions')
            .doc(requestId);

    try {
      await _firestore.runTransaction(
        (
          Transaction transaction,
        ) async {
          // ------------------------------------------------------
          // READ REQUEST
          // ------------------------------------------------------

          final DocumentSnapshot<Map<String, dynamic>>
              requestSnapshot =
              await transaction.get(
            requestRef,
          );

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

          // ------------------------------------------------------
          // READ EXISTING LIVE SESSION
          // ------------------------------------------------------

          final DocumentSnapshot<Map<String, dynamic>>
              sessionSnapshot =
              await transaction.get(
            sessionRef,
          );

          // ------------------------------------------------------
          // EXISTING SESSION
          //
          // Do NOT overwrite it.
          // Reach can safely be called again.
          // ------------------------------------------------------

          if (sessionSnapshot.exists) {
            final Map<String, dynamic>? existingData =
                sessionSnapshot.data();

            final String existingWalkerUid =
                existingData?['walkerUid']
                        ?.toString()
                        .trim() ??
                    '';

            final String existingWalkerId =
                existingData?['walkerId']
                        ?.toString()
                        .trim() ??
                    '';

            if (existingWalkerUid.isNotEmpty &&
                existingWalkerUid != uid) {
              throw Exception(
                'This Live Walk belongs to another Walker.',
              );
            }

            if (existingWalkerId.isNotEmpty &&
                existingWalkerId != id &&
                existingWalkerUid != uid) {
              throw Exception(
                'This Live Walk belongs to another Walker.',
              );
            }

            // Make sure the request is marked reached,
            // but never recreate/reset the live session.
            final String requestStatus =
                requestData['status']
                        ?.toString()
                        .trim()
                        .toLowerCase() ??
                    '';

            if (requestStatus != 'reached') {
              transaction.update(
                requestRef,
                <String, dynamic>{
                  'status': 'reached',
                  'reached': true,
                  'reachedAt':
                      requestData['reachedAt'] ??
                          FieldValue.serverTimestamp(),
                  'updatedAt':
                      FieldValue.serverTimestamp(),
                },
              );
            }

            return;
          }

          // ------------------------------------------------------
          // REQUEST STATUS
          // ------------------------------------------------------

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

          // ------------------------------------------------------
          // VERIFY ACCEPTED WALKER
          // ------------------------------------------------------

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

          // ------------------------------------------------------
          // OWNER
          // ------------------------------------------------------

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

          // ------------------------------------------------------
          // WALKER
          // ------------------------------------------------------

          final String requestWalkerName =
              requestData['walkerName']
                      ?.toString()
                      .trim() ??
                  '';

          final String finalWalkerName =
              walkerName?.trim().isNotEmpty == true
                  ? walkerName!.trim()
                  : requestWalkerName;

          final String requestWalkerPhone =
              requestData['walkerPhone']
                      ?.toString()
                      .trim() ??
                  '';

          final String finalWalkerPhone =
              walkerPhone?.trim().isNotEmpty == true
                  ? walkerPhone!.trim()
                  : requestWalkerPhone;

          final String requestWalkerProfileImage =
              requestData['walkerProfileImage']
                      ?.toString()
                      .trim() ??
                  '';

          final String finalWalkerProfileImage =
              walkerProfileImage?.trim().isNotEmpty == true
                  ? walkerProfileImage!.trim()
                  : requestWalkerProfileImage;

          // ------------------------------------------------------
          // DOG
          // ------------------------------------------------------

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

          // ------------------------------------------------------
          // ADDRESS / LOCATION
          // ------------------------------------------------------

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

          final Timestamp now =
              Timestamp.now();

          // ------------------------------------------------------
          // LIVE SESSION
          // ------------------------------------------------------

          final Map<String, dynamic> sessionData =
              <String, dynamic>{
            'sessionId': requestId,
            'walkRequestId': requestId,
            'requestId': requestId,
            'walkId': requestId,

            'ownerId': ownerId,
            'ownerName': ownerName,
            'ownerPhone': ownerPhone,
            'ownerUid': ownerUid,
            'ownerAuthUid': ownerAuthUid,

            'walkerId': id,
            'walkerUid': uid,
            'walkerName': finalWalkerName,
            'walkerPhone': finalWalkerPhone,
            'walkerProfileImage':
                finalWalkerProfileImage,

            'dogName': dogName,
            'dogBreed': dogBreed,
            'dogPhoto': dogPhoto,

            'address': address,
            'ownerLocation': ownerLocation,
            'ownerLocationType':
                ownerLocationType,

            'acceptedAt':
                requestData['acceptedAt'] ?? now,

            'acceptedBy':
                requestData['acceptedBy'] ?? id,

            'reachedAt': now,

            'arrivalDistanceKm':
                _toDouble(
              requestData[
                  'arrivalDistanceKm'],
            ),

            'arrivalDistanceMeters':
                _toInt(
              requestData[
                  'arrivalDistanceMeters'],
            ),

            'arrivalDurationMinutes':
                _toInt(
              requestData[
                  'arrivalDurationMinutes'],
            ),

            // ----------------------------------------------------
            // READY = reached, waiting for Start
            // ----------------------------------------------------

            'status': 'ready',
            'reached': true,

            'walkStarted': false,
            'walkEnded': false,
            'trackingStarted': false,
            'trackingEnded': false,

            'startedAt': null,
            'endedAt': null,
            'completedAt': null,

            // ----------------------------------------------------
            // GPS
            //
            // Actual GPS updates will come from
            // WalkerLocationService.
            // ----------------------------------------------------

            'currentLocation':
                <String, dynamic>{
              'lat': 0.0,
              'lng': 0.0,
            },

            'distanceKm': 0.0,
            'elapsedSeconds': 0,
            'steps': 0,

            'peeCount': 0,
            'poopCount': 0,

            'routeCoordinates':
                <dynamic>[],

            'events':
                <dynamic>[],

            // ----------------------------------------------------
            // SOURCE
            // ----------------------------------------------------

            'source': 'insta_walk',
            'startedFromQr': false,

            'createdAt': now,
            'updatedAt': now,
          };

          // ------------------------------------------------------
          // CREATE LIVE SESSION
          // ------------------------------------------------------

          transaction.set(
            sessionRef,
            sessionData,
          );

          // ------------------------------------------------------
          // UPDATE REQUEST
          //
          // Same DW######.
          // Search/offer lifecycle is finished.
          // ------------------------------------------------------

          transaction.update(
            requestRef,
            <String, dynamic>{
              'status': 'reached',
              'reached': true,
              'reachedAt': now,

              'arrivalDistanceKm':
                  _toDouble(
                requestData[
                    'arrivalDistanceKm'],
              ),

              'arrivalDistanceMeters':
                  _toInt(
                requestData[
                    'arrivalDistanceMeters'],
              ),

              'arrivalDurationMinutes':
                  _toInt(
                requestData[
                    'arrivalDurationMinutes'],
              ),

              // Incoming offer fields are no longer needed.
              'incomingWalkerUid':
                  FieldValue.delete(),

              'incomingWalkerId':
                  FieldValue.delete(),

              'incomingClaimedAt':
                  FieldValue.delete(),

              'updatedAt': now,
            },
          );
        },
      );
    } on FirebaseException catch (error) {
      throw Exception(
        'Unable to create Live Walk session: '
        '${error.code} '
        '${error.message ?? ''}'.trim(),
      );
    }

    return requestId;
  }

  // ============================================================
  // NUMBER HELPERS
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
