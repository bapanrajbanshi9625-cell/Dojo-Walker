import 'package:cloud_firestore/cloud_firestore.dart';

class WalkerIdService {
  WalkerIdService._();

  static final WalkerIdService instance = WalkerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  static const String _walkerProfilesCollection =
      'walkerProfiles';

  static const String _countersCollection =
      'counters';

  static const String _walkerCounterDocument =
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

    // ==========================================================
    // PHONE ACCOUNT
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        phoneAccountRef = _firestore
            .collection(_phoneAccountsCollection)
            .doc(cleanUid);

    final DocumentSnapshot<Map<String, dynamic>>
        phoneAccount = await phoneAccountRef.get();

    // ==========================================================
    // EXISTING WALKER ID
    // ==========================================================

    if (phoneAccount.exists) {
      final Map<String, dynamic>? data =
          phoneAccount.data();

      final String existingWalkerId =
          data?['walkerId']?.toString().trim() ?? '';

      final String existingRole =
          data?['role']?.toString().trim() ?? '';

      if (existingWalkerId.isNotEmpty &&
          existingRole == 'walker') {
        return existingWalkerId;
      }
    }

    // ==========================================================
    // CREATE WALKER ID
    // ==========================================================

    return _firestore.runTransaction<String>(
      (transaction) async {
        final DocumentReference<Map<String, dynamic>>
            counterRef = _firestore
                .collection(_countersCollection)
                .doc(_walkerCounterDocument);

        final DocumentSnapshot<Map<String, dynamic>>
            counterSnapshot =
            await transaction.get(counterRef);

        int lastSerial = 0;

        if (counterSnapshot.exists) {
          final dynamic value =
              counterSnapshot.data()?['lastSerial'];

          if (value is int) {
            lastSerial = value;
          } else if (value is num) {
            lastSerial = value.toInt();
          }
        }

        final int nextSerial = lastSerial + 1;

        if (nextSerial > 9999) {
          throw Exception(
            'Walker ID serial limit reached.',
          );
        }

        // ======================================================
        // DATE
        // ======================================================

        final DateTime now = DateTime.now();

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
        // FINAL WALKER ID
        //
        // Example:
        //
        // WKR26G M0001
        //
        // Actual:
        // WKR26GM0001
        // ======================================================

        final String walkerId =
            'WKR$year$monthCode$dayCode$serial';

        // ======================================================
        // WALKER PROFILE
        // ======================================================

        final DocumentReference<Map<String, dynamic>>
            walkerProfileRef = _firestore
                .collection(_walkerProfilesCollection)
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
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // ======================================================
        // PHONE ACCOUNT
        // ======================================================

        transaction.set(
          phoneAccountRef,
          {
            'authUid': cleanUid,
            'phone': cleanPhone,
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
            .collection(_phoneAccountsCollection)
            .doc(cleanUid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    final String walkerId =
        data?['walkerId']?.toString().trim() ?? '';

    if (walkerId.isNotEmpty) {
      return walkerId;
    }

    return null;
  }
}
