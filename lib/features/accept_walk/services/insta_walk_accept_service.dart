import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/walker_location_service.dart';
import '../../walks/services/walk_request_sound_service.dart';

class InstaWalkAcceptService {
  InstaWalkAcceptService._();

  static final InstaWalkAcceptService instance =
      InstaWalkAcceptService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  StreamSubscription<Position>? _locationSubscription;

  String? _trackingRequestId;

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_request');
  }

  CollectionReference<Map<String, dynamic>>
      get _walkers {
    return _firestore.collection('walkers');
  }

  User? get _currentUser {
    return _auth.currentUser;
  }

  Future<Map<String, String>> _getWalkerProfile() async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception('Walker is not logged in.');
    }

    final String walkerUid = user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception('Walker UID is missing.');
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _walkers.doc(walkerUid).get();

    if (!snapshot.exists) {
      throw Exception('Walker profile not found.');
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      throw Exception('Walker profile data is empty.');
    }

    String walkerId =
        data['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      walkerId =
          data['Walker ID']?.toString().trim() ?? '';
    }

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found in walkers collection.',
      );
    }

    String walkerName =
        data['name']?.toString().trim() ?? '';

    if (walkerName.isEmpty) {
      walkerName =
          data['fullName']?.toString().trim() ?? '';
    }

    if (walkerName.isEmpty) {
      walkerName =
          data['Full Name']?.toString().trim() ?? '';
    }

    String walkerPhone =
        data['phone']?.toString().trim() ?? '';

    if (walkerPhone.isEmpty) {
      walkerPhone =
          data['phoneNumber']?.toString().trim() ?? '';
    }

    if (walkerPhone.isEmpty) {
      walkerPhone =
          data['mobileNumber']?.toString().trim() ?? '';
    }

    if (walkerPhone.isEmpty) {
      walkerPhone =
          data['Mobile number']?.toString().trim() ?? '';
    }

    String walkerProfileImage =
        data['walkerProfileImage']?.toString().trim() ?? '';

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['profileImageUrl']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['profileImage']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['photoUrl']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['photoURL']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['profilePhoto']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['profilePhotoUrl']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['selfie']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['selfieUrl']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['imageUrl']?.toString().trim() ?? '';
    }

    if (walkerProfileImage.isEmpty) {
      walkerProfileImage =
          data['image']?.toString().trim() ?? '';
    }

    // ignore: avoid_print
    print(
      'Walker profile loaded: '
      'walkerId=$walkerId, '
      'name=$walkerName, '
      'phone=$walkerPhone, '
      'profileImage=$walkerProfileImage',
    );

    return <String, String>{
      'walkerId': walkerId,
      'walkerUid': walkerUid,
      'walkerName': walkerName,
      'walkerPhone': walkerPhone,
      'walkerProfileImage': walkerProfileImage,
    };
  }

  Future<String> getCurrentWalkerId() async {
    final Map<String, String> profile =
        await _getWalkerProfile();

    return profile['walkerId'] ?? '';
  }

  Future<void> acceptWalk(
    String requestId,
  ) async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception('Walker is not logged in.');
    }

    final String walkerUid = user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception('Walker UID is missing.');
    }

    final String id = requestId.trim();

    if (id.isEmpty) {
      throw Exception('Request ID is missing.');
    }

    if (!RegExp(r'^DW\d{6}$').hasMatch(id)) {
      throw Exception(
        'Invalid Request ID. Expected format: DW000001.',
      );
    }

    final Map<String, String> walkerProfile =
        await _getWalkerProfile();

    final String walkerId =
        walkerProfile['walkerId'] ?? '';

    final String walkerName =
        walkerProfile['walkerName'] ?? '';

    final String walkerPhone =
        walkerProfile['walkerPhone'] ?? '';

    final String walkerProfileImage =
        walkerProfile['walkerProfileImage'] ?? '';

    if (walkerId.isEmpty) {
      throw Exception('Walker ID is missing.');
    }

    if (walkerName.isEmpty) {
      throw Exception(
        'Walker name is missing from profile.',
      );
    }

    if (walkerPhone.isEmpty) {
      throw Exception(
        'Walker phone number is missing from profile.',
      );
    }

    final DocumentReference<Map<String, dynamic>> walkRef =
        _walkRequests.doc(id);

    final DocumentReference<Map<String, dynamic>> rejectionRef =
        walkRef.collection('rejections').doc(walkerId);

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<Map<String, dynamic>>
            walkSnapshot =
            await transaction.get(walkRef);

        if (!walkSnapshot.exists) {
          throw Exception(
            'Walk request no longer exists.',
          );
        }

        final Map<String, dynamic>? data =
            walkSnapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        final String status =
            data['status']?.toString().trim().toLowerCase() ??
                '';

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer available.',
          );
        }

        final DocumentSnapshot<Map<String, dynamic>>
            rejectionSnapshot =
            await transaction.get(rejectionRef);

        if (rejectionSnapshot.exists) {
          throw Exception(
            'You already rejected this walk.',
          );
        }

        transaction.update(
          walkRef,
          <String, dynamic>{
            'requestId': id,
            'status': 'accepted',
            'walkerId': walkerId,
            'walkerUid': walkerUid,
            'walkerName': walkerName,
            'walkerPhone': walkerPhone,
            'walkerProfileImage': walkerProfileImage,
            'acceptedBy': walkerId,
            'acceptedByUid': walkerUid,
            'acceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      },
    );

    try {
      await _startLocationTracking(
        requestId: id,
      );
    } catch (e) {
      // Accept already succeeded.
      //
      // GPS failure must not undo the accepted walk.

      // ignore: avoid_print
      print(
        'Unable to start walker location tracking: $e',
      );
    }

    try {
      await WalkRequestSoundService
          .instance
          .stopRequest(id);
    } catch (e) {
      // ignore: avoid_print
      print(
        'Unable to stop walk request sound: $e',
      );
    }
  }

  Future<void> _startLocationTracking({
    required String requestId,
  }) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return;
    }

    await _locationSubscription?.cancel();

    _locationSubscription = null;

    _trackingRequestId = id;

    final bool started =
        await _locationService.startTracking();

    if (!started) {
      throw Exception(
        _locationService.lastError ??
            'Unable to start walker GPS tracking.',
      );
    }

    final Position? currentPosition =
        _locationService.currentPosition ??
            await _locationService.getCurrentLocation();

    if (currentPosition != null) {
      await _updateWalkerLocation(
        requestId: id,
        position: currentPosition,
      );
    }

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) {
        unawaited(
          _updateWalkerLocation(
            requestId: id,
            position: position,
          ),
        );
      },
      onError: (Object error) {
        // ignore: avoid_print
        print(
          'Walker GPS stream error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  Future<void> _updateWalkerLocation({
    required String requestId,
    required Position position,
  }) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return;
    }

    if (_trackingRequestId != id) {
      return;
    }

    try {
      await _walkRequests.doc(id).update(
        <String, dynamic>{
          'walkerLocation': GeoPoint(
            position.latitude,
            position.longitude,
          ),
          'walkerHeading': position.heading,
          'walkerSpeed': position.speed,
          'locationUpdatedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      // Firestore failure must NOT stop GPS.

      // ignore: avoid_print
      print(
        'Unable to update walker location: $e',
      );
    }
  }

  bool get isTracking {
    return _trackingRequestId != null;
  }

  String? get trackingRequestId {
    return _trackingRequestId;
  }

  Future<void> _cancelLocationListener() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;
  }

  Future<void> dispose() async {
    await _cancelLocationListener();
  }
}
