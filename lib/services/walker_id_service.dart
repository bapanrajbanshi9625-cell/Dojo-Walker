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
  // ============================================================

  Future<String> getOrCreateWalkerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanPhone = phoneNumber.trim();

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
        accountRef =
        _firestore
            .collection(_phoneAccounts)
            .doc(cleanUid);

    final DocumentReference<Map<String, dynamic>>
        walkerRef =
        _firestore
            .collection(_walkers)
            .doc(cleanUid);

    final DocumentReference<Map<String, dynamic>>
        counterRef =
        _firestore
            .collection(_counters)
            .doc(_walkerCounter);

    // ==========================================================
    // TRANSACTION
    // ==========================================================

    return _firestore.runTransaction<String>(
      (transaction) async {
        // ======================================================
        // READ ACCOUNT
        // ======================================================

        final DocumentSnapshot<Map<String, dynamic>>
            accountSnapshot =
            await transaction.get(accountRef);

        final Map<String, dynamic> accountData =
            accountSnapshot.data() ??
                <String, dynamic>{};

        // ======================================================
        // READ WALKER
        // ======================================================

        final DocumentSnapshot<Map<String, dynamic>>
            walkerSnapshot =
            await transaction.get(walkerRef);

        final Map<String, dynamic> walkerData =
            walkerSnapshot.data() ??
                <String, dynamic>{};

        // ======================================================
        // EXISTING ROLE CHECK
        // ======================================================

        final String existingRole =
            (accountData['role'] ??
                    walkerData['role'] ??
                    '')
                .toString()
                .trim()
                .toLowerCase();

        if (existingRole.isNotEmpty &&
            existingRole != 'walker') {
          throw Exception(
            'This Firebase account is already registered as $existingRole.',
          );
        }

        // ======================================================
        // EXISTING WALKER ID
        // ======================================================

        String existingWalkerId =
            (accountData['walkerId'] ??
                    walkerData['walkerId'] ??
                    '')
                .toString()
                .trim();

        // ======================================================
        // IF WALKER ID ALREADY EXISTS
        // ======================================================

        if (existingWalkerId.isNotEmpty) {
          // Keep phone account synchronized.
          transaction.set(
            accountRef,
            {
              'authUid': cleanUid,
              'phone': cleanPhone,
              'phoneNumber': cleanPhone,
              'role': 'walker',
              'walkerId': existingWalkerId,
              'active': true,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // Keep walker document synchronized.
          transaction.set(
            walkerRef,
            {
              'authUid': cleanUid,
              'phoneNumber': cleanPhone,
              'role': 'walker',
              'walkerId': existingWalkerId,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          return existingWalkerId;
        }

        // ======================================================
        // READ COUNTER
        // ======================================================

        final DocumentSnapshot<Map<String, dynamic>>
            counterSnapshot =
            await transaction.get(counterRef);

        final Map<String, dynamic> counterData =
            counterSnapshot.data() ??
                <String, dynamic>{};

        final int lastSerial =
            (counterData['lastSerial'] as num?)
                    ?.toInt() ??
                0;

        final int nextSerial =
            lastSerial + 1;

        // ======================================================
        // LIMIT
        // ======================================================

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
          'R',
          'A',
          'Y',
          'U',
          'L',
          'G',
          'P',
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
          'R',
          'F',
          'S',
          'N',
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
        // FINAL WALKER ID
        //
        // Example:
        //
        // WAL26GR0001
        // ======================================================

        final String newWalkerId =
            'WAL$year$monthCode$dayCode$serial';

        // ======================================================
        // COUNTER UPDATE
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
        // WALKER DOCUMENT
        //
        // walkers/{Firebase UID}
        // ======================================================

        transaction.set(
          walkerRef,
          {
            'authUid': cleanUid,
            'phoneNumber': cleanPhone,
            'role': 'walker',
            'walkerId': newWalkerId,
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
        //
        // phoneAccounts/{Firebase UID}
        // ======================================================

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
                accountSnapshot.exists
                    ? accountData['createdAt']
                    : FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return newWalkerId;
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
        snapshot =
        await _firestore
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
