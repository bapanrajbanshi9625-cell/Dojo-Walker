import 'package:cloud_firestore/cloud_firestore.dart';

class LiveWalkSessionService {
  LiveWalkSessionService._();

  static final LiveWalkSessionService instance =
      LiveWalkSessionService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // SESSION REFERENCE
  // ============================================================

  DocumentReference<Map<String, dynamic>> sessionRef(
    String sessionId,
  ) {
    return _firestore
        .collection('liveWalkSessions')
        .doc(sessionId.trim());
  }

  // ============================================================
  // START WALK
  //
  // GPS इस method से START नहीं होगा.
  // GPS पहले से central service से चल रहा होगा.
  // यह केवल WALK को officially start करता है.
  // ============================================================

  Future<void> startWalk({
    required String sessionId,
    required String walkId,
    required String ownerUid,
    required String ownerName,
    required String dogName,
    String dogBreed = '',
  }) async {
    final String cleanSessionId =
        sessionId.trim();

    final String cleanWalkId =
        walkId.trim();

    if (cleanSessionId.isEmpty) {
      throw Exception(
        'Live walk session ID is missing.',
      );
    }

    if (cleanWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<Map<String, dynamic>> ref =
        sessionRef(cleanSessionId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await ref.get();

    final Map<String, dynamic> existing =
        snapshot.data() ??
            <String, dynamic>{};

    final String currentStatus =
        existing['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    // ----------------------------------------------------------
    // ALREADY STARTED
    // ----------------------------------------------------------

    if (currentStatus == 'active' ||
        currentStatus == 'started') {
      return;
    }

    // ----------------------------------------------------------
    // START WALK
    // ----------------------------------------------------------

    await ref.set(
      <String, dynamic>{
        'walkId': cleanWalkId,
        'ownerUid': ownerUid.trim(),
        'ownerName': ownerName.trim(),
        'dogName': dogName.trim(),
        'dogBreed': dogBreed.trim(),

        'status': 'active',

        // IMPORTANT:
        // यह WALK START का time है,
        // GPS START का time नहीं।
        'startedAt': FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),

        // Existing tracking data preserve
        'distanceKm':
            existing['distanceKm'] ?? 0.0,

        'steps':
            existing['steps'] ?? 0,

        'peeCount':
            existing['peeCount'] ?? 0,

        'poopCount':
            existing['poopCount'] ?? 0,

        'routeCoordinates':
            existing['routeCoordinates'] ?? <dynamic>[],

        if (existing['currentLocation'] != null)
          'currentLocation':
              existing['currentLocation'],
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // COMPLETE WALK
  // ============================================================

  Future<void> completeWalk({
    required String sessionId,
  }) async {
    final String cleanSessionId =
        sessionId.trim();

    if (cleanSessionId.isEmpty) {
      throw Exception(
        'Live walk session ID is missing.',
      );
    }

    await sessionRef(cleanSessionId).set(
      <String, dynamic>{
        'status': 'completed',
        'completedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}
