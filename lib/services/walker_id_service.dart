import 'package:cloud_firestore/cloud_firestore.dart';

class WalkerIdService {
  WalkerIdService._();

  static final WalkerIdService instance =
      WalkerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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
  // ============================================================

  Future<String> getOrCreateWalkerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanPhone = phoneNumber.trim();

    if (cleanUid.isEmpty) {
      throw Exception('Firebase UID is empty.');
    }

    if (cleanPhone.isEmpty) {
      throw Exception('Phone number is empty.');
    }

    final DocumentReference<Map<String, dynamic>>
        accountRef = _firestore
            .collection(_phoneAccounts)
            .doc(cleanUid);

    // ==========================================================
    // EXISTING UID ACCOUNT
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        accountSnapshot = await accountRef.get();

    if (accountSnapshot.exists) {
      final Map<String, dynamic>? data =
          accountSnapshot.data();

      final String? role =
          data?['role']?.toString().trim();

      final String? existingWalkerId =
          data?['walkerId']?.toString().trim();

      if (role == 'walker' &&
          existingWalkerId != null &&
          existingWalkerId.isNotEmpty) {
        return existingWalkerId;
      }

      // --------------------------------------------------------
      // IMPORTANT:
      // Same UID cannot change owner -> walker.
      // --------------------------------------------------------

      if (role != null &&
          role.isNotEmpty &&
          role != 'walker') {
        throw Exception(
          'This Firebase account is already registered as $role.',
        );
      }
    }

    // ==========================================================
    // CREATE WALKER ID
    // ==========================================================

    return _firestore.runTransaction<String>(
      (transaction) async {
        final DocumentReference<Map<String, dynamic>>
            counterRef = _firestore
                .collection(_counters)
                .doc(_walkerCounter);

        final DocumentSnapshot<Map<String, dynamic>>
            counterSnapshot =
            await transaction.get(counterRef);

        int lastSerial = 0;

        if (counterSnapshot.exists) {
          final dynamic value =
              counterSnapshot.data()?['lastSerial'];

          if (value is num) {
            lastSerial = value.toInt();
          }
        }

        final int nextSerial =
            lastSerial + 1;

        if (nextSerial > 9999) {
          throw Exception(
            'Walker ID serial limit reached.',
          );
        }

        // ======================================================
        // DATE
        // ======================================================

        final DateTime now =
            DateTime.now();

        final String year =
            (now.year % 100)
                .toString()
                .padLeft(2, '0');

        // ======================================================
        // MONTH CODE
        // ======================================================

        const List<String> monthCodes = [
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

        // ======================================================
        // DAY CODE
        // ======================================================

        const List<String> dayCodes = [
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

        // ======================================================
        // SERIAL
        // ======================================================

        final String serial =
            nextSerial
                .toString()
                .padLeft(4, '0');

        // ======================================================
        // WALKER ID
        //
        // Example:
        //
        // WAL26GM0001
        // ======================================================

        final String walkerId =
            'WAL$year$monthCode$dayCode$serial';

        final DocumentReference<Map<String, dynamic>>
            walkerProfileRef = _firestore
                .collection(_walkerProfiles)
                .doc(walkerId);

        final DocumentReference<Map<String, dynamic>>
            walkerRef = _firestore
                .collection(_walkers)
                .doc(cleanUid);

        // ======================================================
        // COUNTER
        // ======================================================

        transaction.set(
          counterRef,
          {
            'lastSerial': nextSerial,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // ======================================================
        // WALKER PROFILE
        // ======================================================

        transaction.set(
          walkerProfileRef,
          {
            'walkerId': walkerId,
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

        // ======================================================
        // WALKERS/{UID}
        // ======================================================

        transaction.set(
          walkerRef,
          {
            'walkerId': walkerId,
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

        // ======================================================
        // PHONE ACCOUNT
        // ======================================================

        transaction.set(
          accountRef,
          {
            'authUid': cleanUid,
            'phone': cleanPhone,
            'phoneNumber': cleanPhone,
            'role': 'walker',
            'walkerId': walkerId,
            'active': true,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return walkerId;
      },
    );
  }

  // ============================================================
  // GET EXISTING WALKER ID
  // ============================================================

  Future<String?> getExistingWalkerId({
    required String uid,
  }) async {
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(_phoneAccounts)
            .doc(cleanUid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final dynamic walkerId =
        snapshot.data()?['walkerId'];

    if (walkerId is String &&
        walkerId.trim().isNotEmpty) {
      return walkerId.trim();
    }

    return null;
  }
}
