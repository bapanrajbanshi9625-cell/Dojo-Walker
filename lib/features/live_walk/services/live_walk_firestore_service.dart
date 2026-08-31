import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveWalkFirestoreService {
  LiveWalkFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>
      get _sessions =>
          _firestore.collection('liveWalkSessions');

  Future<Map<String, dynamic>?> getSession(
    String sessionId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await _sessions.doc(sessionId).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  Future<void> writeLocation({
    required String walkId,
    required String sessionId,
    required Position position,
    required List<Map<String, double>> route,
    required double distanceKm,
    required int steps,
    required int peeCount,
    required int poopCount,
    required DateTime? startedAt,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final Map<String, double> startLocation =
        route.isNotEmpty
            ? route.first
            : <String, double>{
                'lat': position.latitude,
                'lng': position.longitude,
              };

    final Map<String, dynamic> data =
        <String, dynamic>{
      'walkerUid': user.uid,
      'walkId': walkId,
      'sessionId': sessionId,

      'currentLocation': <String, dynamic>{
        'lat': position.latitude,
        'lng': position.longitude,
      },

      'currentLat': position.latitude,
      'currentLng': position.longitude,

      'startLocation': startLocation,
      'routeCoordinates': route,
      'routePointCount': route.length,

      'distanceKm': distanceKm,
      'distanceMeters': distanceKm * 1000.0,

      'steps': steps,
      'peeCount': peeCount,
      'poopCount': poopCount,

      'startedAt': startedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(startedAt),

      'gpsAccuracy': position.accuracy,
      'gpsHeading': position.heading,
      'gpsSpeed': position.speed,

      'gpsUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      'status': 'active',
      'walkStarted': true,
      'walkEnded': false,
      'trackingStarted': true,
      'trackingEnded': false,
    };

    await _sessions
        .doc(sessionId)
        .set(
          data,
          SetOptions(merge: true),
        );
  }
}
