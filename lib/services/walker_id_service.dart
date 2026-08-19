// File location: lib/services/walker_id_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class WalkerIdService {
  WalkerIdService._();

  static final WalkerIdService instance =
      WalkerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String _phoneAccounts =
      'phoneAccounts';

  static const String _walkers =
      'walkers';

  static const String _counters =
      'counters';

  static const String _walkerCounter =
      'walker';

  // ============================================================
  // GET OR CREATE WALKER ID
  //
  // Flow:
  //
  // Firebase UID
  //      ↓
  // phoneAccounts/{UID}
  //      ↓
  // Walker ID
  //      ↓
  // walkers/{UID}
  //
  // Existing Walker ID will NEVER be replaced.
  // ============================================================

  Future<String> getOrCreateWalkerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid =
        uid.trim();

    final String cleanPhone =
        phoneNumber.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (cleanUid.isEmpty) {
      throw Exception(
        'Firebase UID is empty.',
      );
    }

    if (cleanPhone.isEmpty) {
      throw Exception(
        'Phone number is empty.',
      );
    }

    // ==========================================================
    // REFERENCES
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        accountRef = _firestore
            .collection(_phoneAccounts)
            .doc(cleanUid);

    final DocumentReference<Map<String, dynamic>>
        walkerRef = _firestore
            .collection(_walkers)
            .doc(cleanUid);

    final DocumentReference<Map<String, dynamic>>
        counterRef = _firestore
            .collection(_counters)
            .doc(_walkerCounter);

    try {
      // ========================================================
      // TRANSACTION
      // ========================================================

      final String walkerId =
          await _firestore.runTransaction<String>(
        (transaction) async {
          // ====================================================
          // READ ACCOUNT
          // ====================================================

          final DocumentSnapshot<Map<String, dynamic>>
              accountSnapshot =
              await transaction.get(accountRef);

          final Map<String, dynamic>
              accountData =
              accountSnapshot.data() ?? {};

          // ====================================================
          // CHECK EXISTING ROLE
          // ====================================================

          final String? existingRole =
              accountData['role']
                  ?.toString()
                  .trim();

          if (existingRole != null &&
              existingRole.isNotEmpty &&
              existingRole != 'walker') {
            throw Exception(
              'This Firebase account is already registered '
              'as $existingRole.',
            );
          }

          // ====================================================
          // EXISTING WALKER ID
          //
          // First check phoneAccounts/{UID}.
          // ====================================================

          String? existingWalkerId;

          final dynamic accountWalkerId =
              accountData['walkerId'];

          if (accountWalkerId is String &&
              accountWalkerId.trim().isNotEmpty) {
            existingWalkerId =
                accountWalkerId.trim();
          }

          // ====================================================
          // IF ACCOUNT DOES NOT HAVE ID,
          // CHECK walkers/{UID}
          // ====================================================

          if (existingWalkerId == null) {
            final DocumentSnapshot<Map<String, dynamic>>
                walkerSnapshot =
                await transaction.get(walkerRef);

            if (walkerSnapshot.exists) {
              final Map<String, dynamic>
                  walkerData =
                  walkerSnapshot.data() ?? {};

              final dynamic walkerIdValue =
                  walkerData['walkerId'];

              if (walkerIdValue is String &&
                  walkerIdValue.trim().isNotEmpty) {
                existingWalkerId =
                    walkerIdValue.trim();
              }
            }
          }

          // ====================================================
          // EXISTING ACCOUNT FOUND
          //
          // Do NOT create another Walker ID.
          // ====================================================

          if (existingWalkerId != null) {
            final String savedWalkerId =
                existingWalkerId;

            // --------------------------------------------------
            // Keep phoneAccounts/{UID} synchronized.
            // --------------------------------------------------

            transaction.set(
              accountRef,
              {
                'authUid': cleanUid,
                'phone': cleanPhone,
                'phoneNumber': cleanPhone,
                'role': 'walker',
                'walkerId': savedWalkerId,
                'active': true,
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );

            // --------------------------------------------------
            // Keep walkers/{UID} synchronized.
            // --------------------------------------------------

            transaction.set(
              walkerRef,
              {
                'walkerId': savedWalkerId,
                'authUid': cleanUid,
                'phoneNumber': cleanPhone,
                'role': 'walker',
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );

            return savedWalkerId;
          }

          // ====================================================
          // NO WALKER ID EXISTS
          //
          // Create a new serial.
          // ====================================================

          final DocumentSnapshot<Map<String, dynamic>>
              counterSnapshot =
              await transaction.get(counterRef);

          final Map<String, dynamic>
              counterData =
              counterSnapshot.data() ?? {};

          int lastSerial = 0;

          final dynamic lastSerialValue =
              counterData['lastSerial'];

          if (lastSerialValue is num) {
            lastSerial =
                lastSerialValue.toInt();
          }

          // ====================================================
          // NEXT SERIAL
          // ====================================================

          final int nextSerial =
              lastSerial + 1;

          if (nextSerial > 9999) {
            throw Exception(
              'Walker ID serial limit reached.',
            );
          }

          // ====================================================
          // DATE
          //
          // Example:
          // 26
          // ====================================================

          final DateTime now =
              DateTime.now();

          final String year =
              (now.year % 100)
                  .toString()
                  .padLeft(2, '0');

          // ====================================================
          // MONTH CODE
          //
          // Jan = J
          // Feb = F
          // Mar = M
          // Apr = A
          // May = Y
          // Jun = U
          // Jul = L
          // Aug = G
          // Sep = S
          // Oct = O
          // Nov = N
          // Dec = D
          // ====================================================

          const List<String>
              monthCodes = [
            'J',
            'F',
            'M',
            'A',
            'Y',
            'U',
            'L',
            'G',
            'S',
            'O',
            'N',
            'D',
          ];

          final String monthCode =
              monthCodes[now.month - 1];

          // ====================================================
          // DAY CODE
          //
          // Monday    = M
          // Tuesday   = T
          // Wednesday = W
          // Thursday  = H
          // Friday    = F
          // Saturday  = A
          // Sunday    = S
          // ====================================================

          const List<String>
              dayCodes = [
            'M',
            'T',
            'W',
            'H',
            'F',
            'A',
            'S',
          ];

          final String dayCode =
              dayCodes[now.weekday - 1];

          // ====================================================
          // SERIAL
          // ====================================================

          final String serial =
              nextSerial
                  .toString()
                  .padLeft(4, '0');

          // ====================================================
          // FINAL WALKER ID
          //
          // Example:
          //
          // WAL26G W0001
          //
          // Actual:
          // WAL26G W0001
          //
          // Without space:
          // WAL26GW0001
          // ====================================================

          final String newWalkerId =
              'WAL$year$monthCode$dayCode$serial';

          // ====================================================
          // UPDATE COUNTER
          // ====================================================

          transaction.set(
            counterRef,
            {
              'lastSerial': nextSerial,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // ====================================================
          // CREATE PHONE ACCOUNT
          //
          // Document ID = Firebase UID
          // ====================================================

          transaction.set(
            accountRef,
            {
              'authUid': cleanUid,
              'phone': cleanPhone,
              'phoneNumber': cleanPhone,
              'role': 'walker',
              'walkerId': newWalkerId,
              'active': true,
              'createdAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // ====================================================
          // CREATE WALKER
          //
          // Document ID = Firebase UID
          // Walker ID = custom ID
          // ====================================================

          transaction.set(
            walkerRef,
            {
              'walkerId': newWalkerId,
              'authUid': cleanUid,
              'phoneNumber': cleanPhone,
              'role': 'walker',
              'profileCompleted': false,
              'createdAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // ====================================================
          // RETURN NEW WALKER ID
          // ====================================================

          return newWalkerId;
        },
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      return walkerId;
    } on FirebaseException catch (e) {
      // ========================================================
      // FIREBASE ERROR
      // ========================================================

      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: e.code,
        message:
            'Walker account Firestore operation failed: '
            '${e.message ?? 'Unknown Firestore error'}',
      );
    } catch (e) {
      // ========================================================
      // GENERAL ERROR
      // ========================================================

      throw Exception(
        'Walker ID creation failed: $e',
      );
    }
  }

  // ============================================================
  // GET EXISTING WALKER ID
  // ============================================================

  Future<String?> getExistingWalkerId({
    required String uid,
  }) async {
    final String cleanUid =
        uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    try {
      // ========================================================
      // FIRST: phoneAccounts/{UID}
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot =
          await _firestore
              .collection(_phoneAccounts)
              .doc(cleanUid)
              .get();

      if (accountSnapshot.exists) {
        final dynamic walkerId =
            accountSnapshot.data()?['walkerId'];

        if (walkerId is String &&
            walkerId.trim().isNotEmpty) {
          return walkerId.trim();
        }
      }

      // ========================================================
      // SECOND: walkers/{UID}
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          walkerSnapshot =
          await _firestore
              .collection(_walkers)
              .doc(cleanUid)
              .get();

      if (walkerSnapshot.exists) {
        final dynamic walkerId =
            walkerSnapshot.data()?['walkerId'];

        if (walkerId is String &&
            walkerId.trim().isNotEmpty) {
          return walkerId.trim();
        }
      }

      return null;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: e.code,
        message:
            'Unable to get existing Walker ID: '
            '${e.message ?? 'Unknown Firestore error'}',
      );
    }
  }
}
