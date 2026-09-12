// File:
// lib/features/insta_walk/services/insta_walk_request_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final WalkerAvailabilityService
      _availabilityService =
      WalkerAvailabilityService.instance;

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
    final User? user =
        _auth.currentUser;

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
  //
  // Firebase Auth UID is the canonical fallback.
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final String? uid =
        currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>?
        snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot != null) {
      final Map<String, dynamic>? data =
          snapshot.data();

      if (data != null) {
        final String walkerId =
            data['walkerId']
                    ?.toString()
                    .trim() ??
                '';

        if (walkerId.isNotEmpty) {
          return walkerId;
        }
      }
    }

    return uid;
  }

  // ============================================================
  // CHECK REJECTION
  //
  // walk_request/{walkId}/rejections/{walkerId}
  // ============================================================

  Future<bool> _hasRejected(
    String walkId,
    String walkerId,
  ) async {
    final String id =
        walkId.trim();

    final String wid =
        walkerId.trim();

    if (id.isEmpty ||
        wid.isEmpty) {
      return false;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _walkRequests
            .doc(id)
            .collection('rejections')
            .doc(wid)
            .get();

    return snapshot.exists;
  }

  // ============================================================
  // CLAIM ONE INCOMING REQUEST
  //
  // IMPORTANT:
  //
  // A searching request can be offered to ONLY ONE Walker.
  //
  // The claim is stored on the request as:
  //
  // incomingWalkerUid
  // incomingClaimedAt
  //
  // This transaction makes the claim race-safe between
  // multiple Walker devices.
  //
  // Returns:
  //
  // true  = this Walker owns the incoming offer
  // false = another Walker owns it / request unavailable
  // ============================================================

  Future<bool> _claimIncomingRequest({
    required String walkId,
    required String walkerUid,
  }) async {
    // ------------------------------------------------------------
    // GLOBAL ONLINE GUARD
    //
    // Never claim a request while Offline.
    // ------------------------------------------------------------

    if (!_availabilityService.isOnline) {
      return false;
    }

    final String id =
        walkId.trim();

    final String uid =
        walkerUid.trim();

    if (id.isEmpty ||
        uid.isEmpty) {
      return false;
    }

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    return _firestore.runTransaction<bool>(
      (
        Transaction transaction,
      ) async {
        // --------------------------------------------------------
        // CHECK AGAIN INSIDE THE OPERATION
        //
        // Availability may change while this transaction is
        // being prepared.
        // --------------------------------------------------------

        if (!_availabilityService.isOnline) {
          return false;
        }

        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          return false;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return false;
        }

        // --------------------------------------------------------
        // ONLY SEARCHING REQUESTS CAN BE CLAIMED
        // --------------------------------------------------------

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (status != 'searching') {
          return false;
        }

        // --------------------------------------------------------
        // CURRENT CLAIM
        // --------------------------------------------------------

        final String incomingWalkerUid =
            data['incomingWalkerUid']
                    ?.toString()
                    .trim() ??
                '';

        // --------------------------------------------------------
        // ALREADY CLAIMED BY THIS WALKER
        //
        // Keep the existing claim.
        // Do NOT write again.
        // This prevents unnecessary snapshot loops.
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
        // FINAL ONLINE CHECK BEFORE CLAIM
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
          },
        );

        return true;
      },
    );
  }

  // ============================================================
  // LOAD AVAILABLE REQUESTS
  //
  // This method is called only while Online.
  // ============================================================

  Future<List<InstaWalkRequest>>
      _loadAvailableRequests({
    required String walkerUid,
    required String walkerId,
  }) async {
    // ------------------------------------------------------------
    // ONLINE GUARD
    // ------------------------------------------------------------

    if (!_availabilityService.isOnline) {
      return <InstaWalkRequest>[];
    }

    if (walkerUid.trim().isEmpty ||
        walkerId.trim().isEmpty) {
      return <InstaWalkRequest>[];
    }

    final QuerySnapshot<
            Map<String, dynamic>>
        snapshot =
        await _walkRequests
            .where(
              'status',
              isEqualTo: 'searching',
            )
            .get();

    // ------------------------------------------------------------
    // CHECK AVAILABILITY AGAIN AFTER FIRESTORE READ
    //
    // Walker could have gone Offline while the query was running.
    // ------------------------------------------------------------

    if (!_availabilityService.isOnline) {
      return <InstaWalkRequest>[];
    }

    final List<InstaWalkRequest>
        availableRequests =
        <InstaWalkRequest>[];

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc in snapshot.docs) {
      // ----------------------------------------------------------
      // STOP IMMEDIATELY IF WALKER GOES OFFLINE
      // ----------------------------------------------------------

      if (!_availabilityService.isOnline) {
        break;
      }

      // ----------------------------------------------------------
      // PRIVATE REJECTION CHECK
      // ----------------------------------------------------------

      final bool alreadyRejected =
          await _hasRejected(
        doc.id,
        walkerId,
      );

      if (alreadyRejected) {
        continue;
      }

      // ----------------------------------------------------------
      // CLAIM CHECK
      //
      // Only one Walker can successfully claim.
      // ----------------------------------------------------------

      final bool claimed =
          await _claimIncomingRequest(
        walkId: doc.id,
        walkerUid: walkerUid,
      );

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

      // ----------------------------------------------------------
      // ONLY ONE REQUEST PER WALKER
      // ----------------------------------------------------------

      break;
    }

    if (availableRequests.isEmpty) {
      return <InstaWalkRequest>[];
    }

    return <InstaWalkRequest>[
      availableRequests.first,
    ];
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
  //     No request discovery.
  //     Existing request stream is cancelled.
  //
  // ONLINE AGAIN:
  //     Request discovery starts again.
  //
  // Auth-state aware:
  //
  // If Firebase Auth becomes available after app startup,
  // the listener starts automatically.
  //
  // Only one Walker can claim a request at a time.
  //
  // Rejected requests are hidden for that Walker.
  // ============================================================

  Stream<List<InstaWalkRequest>>
      pendingRequestsStream() {
    return Stream.multi(
      (
        MultiStreamController<
                List<InstaWalkRequest>>
            controller,
      ) {
        StreamSubscription<User?>?
            authSubscription;

        StreamSubscription<
                QuerySnapshot<
                    Map<String, dynamic>>>?
            requestSubscription;

        bool disposed = false;
        int generation = 0;

        // --------------------------------------------------------
        // STOP REQUEST LISTENER
        // --------------------------------------------------------

        Future<void> stopRequestListener() async {
          final StreamSubscription<
                  QuerySnapshot<
                      Map<String, dynamic>>>?
              subscription =
              requestSubscription;

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
          final int currentGeneration =
              ++generation;

          await stopRequestListener();

          if (disposed) {
            return;
          }

          // ------------------------------------------------------
          // GLOBAL ONLINE GUARD
          // ------------------------------------------------------

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
              currentGeneration !=
                  generation) {
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

          // ------------------------------------------------------
          // FIRESTORE SEARCHING LISTENER
          // ------------------------------------------------------

          requestSubscription =
              _walkRequests
                  .where(
                    'status',
                    isEqualTo: 'searching',
                  )
                  .snapshots()
                  .listen(
            (
              QuerySnapshot<
                      Map<String, dynamic>>
                  snapshot,
            ) async {
              if (disposed ||
                  currentGeneration !=
                      generation) {
                return;
              }

              // ------------------------------------------------
              // OFFLINE = NO REQUESTS
              // ------------------------------------------------

              if (!_availabilityService.isOnline) {
                emitEmpty();
                return;
              }

              final List<
                      InstaWalkRequest>
                  availableRequests =
                  <InstaWalkRequest>[];

              for (final QueryDocumentSnapshot<
                      Map<String, dynamic>>
                  doc in snapshot.docs) {
                if (disposed ||
                    currentGeneration !=
                        generation) {
                  return;
                }

                // ----------------------------------------------
                // GLOBAL ONLINE CHECK
                // ----------------------------------------------

                if (!_availabilityService
                    .isOnline) {
                  emitEmpty();
                  return;
                }

                // ----------------------------------------------
                // PRIVATE REJECTION CHECK
                // ----------------------------------------------

                final bool alreadyRejected =
                    await _hasRejected(
                  doc.id,
                  walkerId,
                );

                if (disposed ||
                    currentGeneration !=
                        generation) {
                  return;
                }

                if (!_availabilityService
                    .isOnline) {
                  emitEmpty();
                  return;
                }

                if (alreadyRejected) {
                  continue;
                }

                // ----------------------------------------------
                // CLAIM CHECK
                // ----------------------------------------------

                final bool claimed =
                    await _claimIncomingRequest(
                  walkId: doc.id,
                  walkerUid: walkerUid,
                );

                if (disposed ||
                    currentGeneration !=
                        generation) {
                  return;
                }

                if (!_availabilityService
                    .isOnline) {
                  emitEmpty();
                  return;
                }

                if (!claimed) {
                  continue;
                }

                final InstaWalkRequest
                    request =
                    InstaWalkRequest
                        .fromFirestore(
                  doc,
                );

                availableRequests.add(
                  request,
                );

                // ----------------------------------------------
                // ONLY ONE REQUEST PER WALKER
                // ----------------------------------------------

                break;
              }

              if (disposed ||
                  currentGeneration !=
                      generation) {
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
                  currentGeneration !=
                      generation) {
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
        // Offline -> immediately stop discovery
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

          _availabilityService
              .removeListener(
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

  Future<InstaWalkRequest?>
      getWalkRequest(
    String walkId,
  ) async {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _walkRequests
            .doc(id)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return InstaWalkRequest.fromFirestore(
      snapshot,
    );
  }
}
