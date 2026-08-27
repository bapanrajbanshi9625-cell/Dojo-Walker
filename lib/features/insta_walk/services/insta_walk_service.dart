import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// INSTA WALK SERVICE
///
/// RESPONSIBILITIES:
/// - Current Walker information
/// - Watch single walk
/// - Cancel search
/// - Start walk
/// - Complete walk
///
/// REQUEST DISCOVERY:
///     InstaWalkRequestService
///
/// ACCEPT:
///     InstaWalkAcceptService
///
/// REJECT:
///     InstaWalkRejectService
/// ============================================================

class InstaWalkService {
  InstaWalkService._();

  static final InstaWalkService instance =
      InstaWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_request');
  }

  CollectionReference<Map<String, dynamic>>
      get _walkers {
    return _firestore.collection('walkers');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  String? get currentWalkerUid {
    final User? user = _auth.currentUser;

    final String uid =
        user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      return null;
    }

    return uid;
  }

  // ============================================================
  // CURRENT WALKER DOCUMENT
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _getCurrentWalkerDocument() async {
    final String? uid =
        currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _walkers
            .doc(uid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot;
  }

  // ============================================================
  // CURRENT WALKER ID
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final DocumentSnapshot<
            Map<String, dynamic>>?
        snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot == null) {
      return null;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      return null;
    }

    final String walkerId =
        data['walkerId']
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      return null;
    }

    return walkerId;
  }

  // ============================================================
  // CURRENT WALKER NAME
  // ============================================================

  Future<String> getCurrentWalkerName() async {
    final DocumentSnapshot<
            Map<String, dynamic>>?
        snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot == null) {
      return '';
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      return '';
    }

    final String walkerName =
        data['walkerName']
                ?.toString()
                .trim() ??
            '';

    if (walkerName.isNotEmpty) {
      return walkerName;
    }

    return data['name']
                ?.toString()
                .trim() ??
        '';
  }

  // ============================================================
  // WATCH SINGLE WALK
  //
  // Used by ActiveWalkDetailsScreen.
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchWalk(
    String walkId,
  ) {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return const Stream<
          DocumentSnapshot<
              Map<String, dynamic>>>.empty();
    }

    return _walkRequests
        .doc(id)
        .snapshots();
  }

  // ============================================================
  // CANCEL SEARCH
  //
  // searching → cancelled
  // ============================================================

  Future<void> cancelSearch(
    String walkId,
  ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Walk request not found.',
          );
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer searching.',
          );
        }

        final String storedWalkerUid =
            data['walkerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerUid.isNotEmpty &&
            storedWalkerUid != walkerUid) {
          throw Exception(
            'This walk belongs to another walker.',
          );
        }

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'cancelled',
            'cancelledAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // START WALK
  //
  // accepted → active
  // ============================================================

  Future<void> startWalk(
    String walkId, {
    String? liveWalkSessionId,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    final String? walkerId =
        await getCurrentWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Walk request not found.',
          );
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        if (status != 'accepted') {
          throw Exception(
            'This walk is not ready to start.',
          );
        }

        final String storedWalkerId =
            data['walkerId']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerId.isNotEmpty &&
            storedWalkerId != walkerId) {
          throw Exception(
            'This walk belongs to another walker.',
          );
        }

        final String storedWalkerUid =
            data['walkerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerUid.isNotEmpty &&
            storedWalkerUid != walkerUid) {
          throw Exception(
            'This walk belongs to another walker.',
          );
        }

        final String sessionId =
            liveWalkSessionId
                        ?.trim()
                        .isNotEmpty ==
                    true
                ? liveWalkSessionId!.trim()
                : 'session-$id';

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'active',
            'walkerId': walkerId,
            'walkerUid': walkerUid,
            'activeWalkId': id,
            'liveWalkSessionId': sessionId,
            'startedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // COMPLETE WALK
  //
  // active → completed
  // ============================================================

  Future<void> completeWalk(
    String walkId,
  ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    final String? walkerId =
        await getCurrentWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Walk request not found.',
          );
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        if (status != 'active') {
          throw Exception(
            'This walk is not active.',
          );
        }

        final String storedWalkerId =
            data['walkerId']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerId.isNotEmpty &&
            storedWalkerId != walkerId) {
          throw Exception(
            'This walk belongs to another walker.',
          );
        }

        final String storedWalkerUid =
            data['walkerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerUid.isNotEmpty &&
            storedWalkerUid != walkerUid) {
          throw Exception(
            'This walk belongs to another walker.',
          );
        }

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'completed',
            'endedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }
}
