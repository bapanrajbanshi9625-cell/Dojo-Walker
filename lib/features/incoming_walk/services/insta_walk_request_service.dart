// File:
// lib/features/incoming_walk/services/insta_walk_request_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../services/walker_availability_service.dart';
import '../../insta_walk/models/insta_walk_request.dart';

/// ============================================================
/// INCOMING WALK REQUEST SERVICE
///
/// Responsibilities:
///
/// - Discover searching walk requests
/// - Hide requests rejected by current Walker
/// - Claim one request for one Walker
/// - Restart discovery when Walker becomes Online
/// - Stop discovery immediately when Walker becomes Offline
///
/// GPS lifecycle remains owned by:
///
/// WalkerAvailabilityService
///
/// This service NEVER starts or stops GPS.
/// ============================================================

class InstaWalkRequestService {
  InstaWalkRequestService._();

  static final InstaWalkRequestService instance =
      InstaWalkRequestService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final WalkerAvailabilityService _availabilityService =
      WalkerAvailabilityService.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _walkRequests {
    return _firestore.collection('walk_request');
  }

  CollectionReference<Map<String, dynamic>> get _walkers {
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

    final String uid = user?.uid.trim() ?? '';

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
    final String? uid = currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _walkers.doc(uid).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot;
  }

  // ============================================================
  // CURRENT WALKER ID
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final String? uid = currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>? snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot != null) {
      final Map<String, dynamic>? data =
          snapshot.data();

      if (data != null) {
        String walkerId =
            data['walkerId']?.toString().trim() ?? '';

        if (walkerId.isEmpty) {
          walkerId =
              data['Walker ID']?.toString().trim() ?? '';
        }

        if (walkerId.isNotEmpty) {
          return walkerId;
        }
      }
    }

    return uid;
  }

  // ============================================================
  // CLAIM INCOMING REQUEST
  // ============================================================

  Future<bool> _claimIncomingRequest({
    required String walkId,
    required String walkerUid,
    required String walkerId,
  }) async {
    if (!_availabilityService.isOnline) {
      return false;
    }

    final String id = walkId.trim();
    final String uid = walkerUid.trim();
    final String wid = walkerId.trim();

    if (id.isEmpty ||
        uid.isEmpty ||
        wid.isEmpty) {
      return false;
    }

    final DocumentReference<Map<String, dynamic>> walkRef =
        _walkRequests.doc(id);

    final DocumentReference<Map<String, dynamic>> rejectionRef =
        walkRef
            .collection('rejections')
            .doc(wid);

    return _firestore.runTransaction<bool>(
      (
        Transaction transaction,
      ) async {
        if (!_availabilityService.isOnline) {
          return false;
        }

        final DocumentSnapshot<Map<String, dynamic>>
            walkSnapshot =
            await transaction.get(walkRef);

        if (!walkSnapshot.exists) {
          return false;
        }

        final Map<String, dynamic>? data =
            walkSnapshot.data();

        if (data == null) {
          return false;
        }

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        if (status != 'searching') {
          return false;
        }

        // --------------------------------------------------------
        // Rejected by this Walker?
        // --------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>>
            rejectionSnapshot =
            await transaction.get(rejectionRef);

        if (rejectionSnapshot.exists) {
          return false;
        }

        // --------------------------------------------------------
        // Existing incoming claim
        // --------------------------------------------------------

        final String incomingWalkerUid =
            data['incomingWalkerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (incomingWalkerUid == uid) {
          return true;
        }

        if (incomingWalkerUid.isNotEmpty &&
            incomingWalkerUid != uid) {
          return false;
        }

        if (!_availabilityService.isOnline) {
          return false;
        }

        transaction.update(
          walkRef,
          <String, dynamic>{
            'incomingWalkerUid': uid,
            'incomingClaimedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        return true;
      },
    );
  }

  // ============================================================
  // PENDING REQUEST STREAM
  // ============================================================

  Stream<List<InstaWalkRequest>> pendingRequestsStream() {
    return Stream.multi(
      (
        MultiStreamController<List<InstaWalkRequest>> controller,
      ) {
        StreamSubscription<User?>? authSubscription;

        StreamSubscription<
                QuerySnapshot<Map<String, dynamic>>>?
            requestSubscription;

        bool disposed = false;
        bool startingListener = false;
        int generation = 0;

        // --------------------------------------------------------
        // STOP FIRESTORE LISTENER
        // --------------------------------------------------------

        Future<void> stopRequestListener() async {
          final StreamSubscription<
                  QuerySnapshot<Map<String, dynamic>>>?
              subscription =
              requestSubscription;

          requestSubscription = null;

          if (subscription != null) {
            await subscription.cancel();
          }
        }

        // --------------------------------------------------------
        // EMPTY
        // --------------------------------------------------------

        void emitEmpty() {
          if (disposed) {
            return;
          }

          controller.add(
            <InstaWalkRequest>[],
          );
        }

        // --------------------------------------------------------
        // START FIRESTORE LISTENER
        // --------------------------------------------------------

        Future<void> startRequestListener(
          User user,
        ) async {
          if (disposed || startingListener) {
            return;
          }

          startingListener = true;

          final int currentGeneration =
              ++generation;

          try {
            await stopRequestListener();

            if (disposed ||
                currentGeneration != generation) {
              return;
            }

            // ----------------------------------------------------
            // Wait until availability startup restoration has
            // completed.
            // ----------------------------------------------------

            await _availabilityService.ready;

            if (disposed ||
                currentGeneration != generation) {
              return;
            }

            if (!_availabilityService.isOnline) {
              emitEmpty();
              return;
            }

            final String walkerUid =
                user.uid.trim();

            if (walkerUid.isEmpty) {
              emitEmpty();
              return;
            }

            final String? walkerId =
                await getCurrentWalkerId();

            if (disposed ||
                currentGeneration != generation) {
              return;
            }

            if (!_availabilityService.isOnline) {
              emitEmpty();
              return;
            }

            if (walkerId == null ||
                walkerId.trim().isEmpty) {
              emitEmpty();
              return;
            }

            final String cleanWalkerId =
                walkerId.trim();

            // ----------------------------------------------------
            // FIRESTORE SEARCHING LISTENER
            // ----------------------------------------------------

            requestSubscription = _walkRequests
                .where(
                  'status',
                  isEqualTo: 'searching',
                )
                .snapshots()
                .listen(
              (
                QuerySnapshot<Map<String, dynamic>> snapshot,
              ) async {
                if (disposed ||
                    currentGeneration != generation) {
                  return;
                }

                if (!_availabilityService.isOnline) {
                  emitEmpty();
                  return;
                }

                final List<InstaWalkRequest>
                    availableRequests =
                    <InstaWalkRequest>[];

                for (final QueryDocumentSnapshot<
                    Map<String, dynamic>> doc
                    in snapshot.docs) {
                  if (disposed ||
                      currentGeneration != generation) {
                    return;
                  }

                  if (!_availabilityService.isOnline) {
                    emitEmpty();
                    return;
                  }

                  final bool claimed =
                      await _claimIncomingRequest(
                    walkId: doc.id,
                    walkerUid: walkerUid,
                    walkerId: cleanWalkerId,
                  );

                  if (disposed ||
                      currentGeneration != generation) {
                    return;
                  }

                  if (!_availabilityService.isOnline) {
                    emitEmpty();
                    return;
                  }

                  if (!claimed) {
                    continue;
                  }

                  final InstaWalkRequest request =
                      InstaWalkRequest.fromFirestore(
                    doc,
                  );

                  availableRequests.add(
                    request,
                  );

                  // One request at a time.
                  break;
                }

                if (disposed ||
                    currentGeneration != generation) {
                  return;
                }

                if (!_availabilityService.isOnline) {
                  emitEmpty();
                  return;
                }

                if (availableRequests.isEmpty) {
                  emitEmpty();
                  return;
                }

                controller.add(
                  <InstaWalkRequest>[
                    availableRequests.first,
                  ],
                );
              },
              onError: (
                Object error,
                StackTrace stackTrace,
              ) {
                if (disposed ||
                    currentGeneration != generation) {
                  return;
                }

                debugPrint(
                  'Incoming Walk Firestore stream error: '
                  '$error',
                );

                debugPrintStack(
                  stackTrace: stackTrace,
                );
              },
            );
          } finally {
            startingListener = false;
          }
        }

        // --------------------------------------------------------
        // AVAILABILITY CHANGE
        // --------------------------------------------------------

        void onAvailabilityChanged() {
          if (disposed) {
            return;
          }

          final User? user =
              _auth.currentUser;

          if (!_availabilityService.isOnline) {
            generation++;

            unawaited(
              stopRequestListener(),
            );

            emitEmpty();
            return;
          }

          if (user == null) {
            generation++;

            unawaited(
              stopRequestListener(),
            );

            emitEmpty();
            return;
          }

          unawaited(
            startRequestListener(user),
          );
        }

        // --------------------------------------------------------
        // AUTH CHANGE
        // --------------------------------------------------------

        authSubscription =
            _auth.authStateChanges().listen(
          (User? user) {
            if (disposed) {
              return;
            }

            generation++;

            unawaited(
              stopRequestListener(),
            );

            if (user == null) {
              emitEmpty();
              return;
            }

            unawaited(
              startRequestListener(user),
            );
          },
        );

        // --------------------------------------------------------
        // AVAILABILITY LISTENER
        // --------------------------------------------------------

        _availabilityService.addListener(
          onAvailabilityChanged,
        );

        // --------------------------------------------------------
        // INITIAL START
        //
        // IMPORTANT:
        // Wait for availability restore first.
        // --------------------------------------------------------

        unawaited(
          () async {
            await _availabilityService.ready;

            if (disposed) {
              return;
            }

            final User? user =
                _auth.currentUser;

            if (user == null) {
              emitEmpty();
              return;
            }

            if (!_availabilityService.isOnline) {
              emitEmpty();
              return;
            }

            await startRequestListener(user);
          }(),
        );

        // --------------------------------------------------------
        // CLEANUP
        // --------------------------------------------------------

        controller.onCancel = () async {
          if (disposed) {
            return;
          }

          disposed = true;
          generation++;

          _availabilityService.removeListener(
            onAvailabilityChanged,
          );

          await authSubscription?.cancel();
          await stopRequestListener();
        };
      },
      isBroadcast: true,
    );
  }

  // ============================================================
  // GET SINGLE WALK REQUEST
  // ============================================================

  Future<InstaWalkRequest?> getWalkRequest(
    String walkId,
  ) async {
    final String id = walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await _walkRequests.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    return InstaWalkRequest.fromFirestore(
      snapshot,
    );
  }
}
