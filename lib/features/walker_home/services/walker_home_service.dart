import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/past_walk_model.dart';

class WalkerHomeService {
  WalkerHomeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<PastWalkModel>> watchPastWalks() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <PastWalkModel>[]);
    }

    return _firestore
        .collection('walk_history')
        .where('walkerId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final walks = snapshot.docs
          .map(PastWalkModel.fromDocument)
          .where(
            (walk) =>
                walk.status.toLowerCase() == 'completed' ||
                walk.status.toLowerCase() == 'complete' ||
                walk.status.toLowerCase() == 'done',
          )
          .toList();

      walks.sort((a, b) {
        final aDate = a.completedAt;
        final bDate = b.completedAt;

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      });

      return walks;
    });
  }
}
