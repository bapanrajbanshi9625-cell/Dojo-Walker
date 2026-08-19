import 'package:cloud_firestore/cloud_firestore.dart';

class WalkerIdService {
  WalkerIdService._();

  static final WalkerIdService instance = WalkerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _phoneAccounts = 'phoneAccounts';
  static const String _walkers = 'walkers';
  static const String _counters = 'counters';
  static const String _walkerCounter = 'walker';

  // ============================================================
  // GET / CREATE WALKER ID
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

    final DocumentReference<Map<String, dynamic>> walkerRef =
        _firestore.collection(_walkers).doc(cleanUid);

    final DocumentReference<Map<String, dynamic>> accountRef =
        _firestore.collection(_phoneAccounts).doc(cleanUid);

    final DocumentReference<Map<String, dynamic>> counterRef =
        _firestore.collection(_counters).doc(_walkerCounter);

    return _firestore.runTransaction<String>(
      (transaction) async {
        // --------------------------------------------------------
        // READ WALKER
        // --------------------------------------------------------

        final walkerSnapshot =
            await transaction.get(walkerRef);

        final Map<String, dynamic> walkerData =
            walkerSnapshot.data() ?? <String, dynamic>{};

        // --------------------------------------------------------
        // READ PHONE ACCOUNT
        // --------------------------------------------------------

        final accountSnapshot =
            await transaction.get(accountRef);

        final Map<String, dynamic> accountData =
            accountSnapshot.data() ?? <String, dynamic>{};

        // --------------------------------------------------------
        // ROLE CHECK
        // --------------------------------------------------------

        final String walkerRole =
            (walkerData['role'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        final String accountRole =
            (accountData['role'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        final String existingRole =
            walkerRole.isNotEmpty
                ? walkerRole
                : accountRole;

        if (existingRole.isNotEmpty &&
            existingRole != 'walker') {
          throw Exception(
            'This Firebase account is already registered as $existingRole.',
          );
        }

        // --------------------------------------------------------
        // EXISTING WALKER ID
        // --------------------------------------------------------

        String existingWalkerId =
            (walkerData['walkerId'] ??
                    accountData['walkerId'] ??
                    '')
                .toString()
                .trim();

        // --------------------------------------------------------
        // IF EXISTING ID FOUND
        // --------------------------------------------------------

        if (existingWalkerId.isNotEmpty) {
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

          return existingWalkerId;
        }

        // --------------------------------------------------------
        // READ COUNTER
        // --------------------------------------------------------

        final counterSnapshot =
            await transaction.get(counterRef);

        final Map<String, dynamic> counterData =
            counterSnapshot.data() ?? <String, dynamic>{};

        final dynamic rawLastSerial =
            counterData['lastSerial'];

        final int lastSerial =
            rawLastSerial is num
                ? rawLastSerial.toInt()
                : 0;

        final int nextSerial = lastSerial + 1;

        if (nextSerial > 9999) {
          throw Exception(
            'Walker ID serial limit reached.',
          );
        }

        // --------------------------------------------------------
        // DATE
        // --------------------------------------------------------

        final DateTime now = DateTime.now();

        final String year =
            (now.year % 100)
                .toString()
                .padLeft(2, '0');

        // --------------------------------------------------------
        // MONTH
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // DAY
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // SERIAL
        // --------------------------------------------------------

        final String serial =
            nextSerial
                .toString()
                .padLeft(4, '0');

        // --------------------------------------------------------
        // FINAL WALKER ID
        // --------------------------------------------------------

        final String newWalkerId =
            'WAL$year$monthCode$dayCode$serial';

        // --------------------------------------------------------
        // COUNTER
        // --------------------------------------------------------

        transaction.set(
          counterRef,
          {
            'lastSerial': nextSerial,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // --------------------------------------------------------
        // WALKER DOCUMENT
        // --------------------------------------------------------

        final Map<String, dynamic> walkerWrite = {
          'authUid': cleanUid,
          'phoneNumber': cleanPhone,
          'role': 'walker',
          'walkerId': newWalkerId,
          'profileCompleted': false,
          'verificationStatus': 'pending',
          'updatedAt':
              FieldValue.serverTimestamp(),
        };

        if (!walkerSnapshot.exists) {
          walkerWrite['createdAt'] =
              FieldValue.serverTimestamp();
        }

        transaction.set(
          walkerRef,
          walkerWrite,
          SetOptions(merge: true),
        );

        // --------------------------------------------------------
        // PHONE ACCOUNT
        // --------------------------------------------------------

        final Map<String, dynamic> accountWrite = {
          'authUid': cleanUid,
          'phone': cleanPhone,
          'phoneNumber': cleanPhone,
          'role': 'walker',
          'walkerId': newWalkerId,
          'active': true,
          'updatedAt':
              FieldValue.serverTimestamp(),
        };

        if (!accountSnapshot.exists) {
          accountWrite['createdAt'] =
              FieldValue.serverTimestamp();
        }

        transaction.set(
          accountRef,
          accountWrite,
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

    final snapshot = await _firestore
        .collection(_walkers)
        .doc(cleanUid)
        .get();

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    final dynamic value = data['walkerId'];

    if (value == null) {
      return null;
    }

    final String walkerId =
        value.toString().trim();

    return walkerId.isEmpty
        ? null
        : walkerId;
  }
}
