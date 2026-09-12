// File:
// lib/features/insta_walk/services/insta_walk_request_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../services/walker_availability_service.dart';
import '../models/insta_walk_request.dart';

/// ============================================================
/// INSTA WALK REQUEST SERVICE
///
/// RESPONSIBILITIES:
///
/// - Find searching Insta Walk requests
/// - Hide requests rejected by current Walker
/// - Claim one incoming request for one Walker at a time
/// - Return available requests
/// - Get a single walk request
///
/// AVAILABILITY:
///
/// - ONLY ONLINE walkers can discover/claim requests
/// - OFFLINE walkers receive an empty request stream
/// - Going ONLINE restarts request discovery
/// - Going OFFLINE immediately clears request discovery
///
/// NOT RESPONSIBLE FOR:
///
/// - Sound
/// - Accept
/// - Reject
/// - Cancel
/// - Reach
/// - Start
/// - Complete
/// - Accepted walk watching
/// - Active walk document watching
/// - GPS tracking
///
/// GPS / ONLINE STATE:
///
///     WalkerAvailabilityService
///
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
  //
  // Walker ID is read from walkers/{uid}.
  //
  // Firebase Auth UID remains the canonical UID used for claims.
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final String? uid = currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>? snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot != null) {
      final Map<String, dynamic>? data = snapshot.data();

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
  // CLAIM ONE INCOMING REQUEST
  //
  // IMPORTANT:
  //
  // A searching request can be offered to ONLY ONE Walker.
  //
  // The claim is stored on:
  //
  // walk_request/{walkId}
  //
  //     incomingWalkerUid
  //     incomingClaimedAt
  //
  // Rejection is checked INSIDE the same transaction.
  //
  // This prevents:
  //
  // reject -> claim race
  //
  // and keeps rejected requests hidden from that Walker.
  //
  // Returns:
  //
  // true  = this Walker owns the incoming offer
  // false = unavailable / rejected / another Walker owns it
  // ============================================================

  Future<bool> _claimIncomingRequest({
    required String walkId,
    required String walkerUid,
    required String walkerId,
  }) async {
    // ------------------------------------------------------------
    // GLOBAL ONLINE GUARD
    // ------------------------------------------------------------

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
        // --------------------------------------------------------
        // ONLINE CHECK
        // --------------------------------------------------------

        if (!_availabilityService.isOnline) {
          return false;
        }

        // --------------------------------------------------------
        // READ MAIN REQUEST
        // --------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>> walkSnapshot =
            await transaction.get(
          walkRef,
        );

        if (!walkSnapshot.exists) {
          return false;
        }

        final Map<String, dynamic>? data =
            walkSnapshot.data();

        if (data == null) {
          return false;
        }

        // --------------------------------------------------------
        // ONLY SEARCHING REQUESTS CAN BE CLAIMED
        // --------------------------------------------------------

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        if (status != 'searching') {
          return false;
        }

        // --------------------------------------------------------
        // READ REJECTION INSIDE SAME TRANSACTION
        //
        // This is important.
        //
        // IncomingWalkRejectService writes:
        //
        // rejections/{walkerId}
        //
        // A rejected Walker must never claim this request again.
        // --------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>>
            rejectionSnapshot =
            await transaction.get(
          rejectionRef,
        );

        if (rejectionSnapshot.exists) {
          return false;
        }

        // --------------------------------------------------------
        // CURRENT CLAIM
        // --------------------------------------------------------

        final String incomingWalkerUid =
            data['incomingWalkerUid']?.toString().trim() ?? '';

        // --------------------------------------------------------
        // ALREADY CLAIMED BY THIS WALKER
        //
        // Keep existing claim.
        // Do not write again.
        // --------------------------------------------------------

        if (incomingWalkerUid == uid) {
          return true;
        }

        // --------------------------------------------------------
        // CLAIMED BY ANOTHER WALKER
        // --------------------------------------------------------

        if (incomingWalkerUid.isNotEmpty &&
            incomingWalkerUid != uid) {
          return false;
        }

        // --------------------------------------------------------
        // FINAL ONLINE CHECK
        // --------------------------------------------------------

        if (!_availabilityService.isOnline) {
          return false;
        }

        // --------------------------------------------------------
        // CLAIM REQUEST
        // --------------------------------------------------------

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
  // PENDING / SEARCHING REQUESTS
  //
  // GLOBAL AVAILABILITY AWARE
  //
  // ONLINE:
  //     Listen for searching requests.
  //
  // OFFLINE:
  //     Request discovery stops immediately.
  //
  // ONLINE AGAIN:
  //     Discovery starts again.
  //
  // Rejected requests are hidden.
  //
  // Only ONE request is returned to a Walker at a time.
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
        int generation = 0;

        // --------------------------------------------------------
        // STOP REQUEST LISTENER
        // --------------------------------------------------------

        Future<void> stopRequestListener() async {
          final StreamSubscription<
                  QuerySnapshot<Map<String, dynamic>>>?
              subscription = requestSubscription;

          requestSubscription = null;

          if (subscription != null) {
            await subscription.cancel();
          }
        }

        // --------------------------------------------------------
        // EMIT EMPTY
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
        // START REQUEST LISTENER
        // --------------------------------------------------------

        Future<void> startRequestListener(
          User user,
        ) async {
          final int currentGeneration = ++generation;

          await stopRequestListener();

          if (disposed ||
              currentGeneration != generation) {
            return;
          }

          // ------------------------------------------------------
          // GLOBAL ONLINE GUARD
          // ------------------------------------------------------

          if (!_availabilityService.isOnline) {
            emitEmpty();
            return;
          }

          final String walkerUid = user.uid.trim();

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

          // ------------------------------------------------------
          // FIRESTORE SEARCHING LISTENER
          // ------------------------------------------------------

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

              // ------------------------------------------------
              // OFFLINE = NO REQUESTS
              // ------------------------------------------------

              if (!_availabilityService.isOnline) {
                emitEmpty();
                return;
              }

              final List<InstaWalkRequest> availableRequests =
                  <InstaWalkRequest>[];

              for (final QueryDocumentSnapshot<
                  Map<String, dynamic>> doc in snapshot.docs) {
                if (disposed ||
                    currentGeneration != generation) {
                  return;
                }

                if (!_availabilityService.isOnline) {
                  emitEmpty();
                  return;
                }

                // ------------------------------------------------
                // CLAIM
                //
                // Rejection is checked atomically inside this
                // transaction.
                // ------------------------------------------------

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

                // ------------------------------------------------
                // BUILD REQUEST
                // ------------------------------------------------

                final InstaWalkRequest request =
                    InstaWalkRequest.fromFirestore(
                  doc,
                );

                availableRequests.add(
                  request,
                );

                // ------------------------------------------------
                // ONLY ONE REQUEST PER WALKER
                // ------------------------------------------------

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
            onError: (Object error) {
              if (disposed ||
                  currentGeneration != generation) {
                return;
              }

              debugPrint(
                'Insta Walk request stream error: $error',
              );
            },
          );
        }

        // --------------------------------------------------------
        // AVAILABILITY CHANGE
        //
        // Online  -> start discovery
        // Offline -> stop discovery immediately
        // --------------------------------------------------------

        void onAvailabilityChanged() {
          if (disposed) {
            return;
          }

          if (!_availabilityService.isOnline) {
            generation++;

            unawaited(
              stopRequestListener(),
            );

            emitEmpty();
            return;
          }

          final User? user =
              _auth.currentUser;

          if (user == null) {
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

            if (user == null) {
              generation++;

              unawaited(
                stopRequestListener(),
              );

              emitEmpty();
              return;
            }

            if (!_availabilityService.isOnline) {
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
          },
        );

        // --------------------------------------------------------
        // GLOBAL AVAILABILITY LISTENER
        // --------------------------------------------------------

        _availabilityService.addListener(
          onAvailabilityChanged,
        );

        // --------------------------------------------------------
        // INITIAL STATE
        // --------------------------------------------------------

        final User? initialUser =
            _auth.currentUser;

        if (initialUser == null) {
          emitEmpty();
        } else if (!_availabilityService.isOnline) {
          emitEmpty();
        } else {
          unawaited(
            startRequestListener(
              initialUser,
            ),
          );
        }

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

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _walkRequests.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    return InstaWalkRequest.fromFirestore(
      snapshot,
    );
  }
}
