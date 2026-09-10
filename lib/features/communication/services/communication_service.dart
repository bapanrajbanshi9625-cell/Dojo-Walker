import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/communication_context.dart';

class CommunicationService {
  CommunicationService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _contacts =>
      _firestore.collection('contacts');

  DocumentReference<Map<String, dynamic>> contactReference(
    String contactId,
  ) {
    return _contacts.doc(contactId);
  }

  Future<void> createOrUpdateContact({
    required CommunicationContext context,
  }) async {
    final reference = contactReference(context.contactId);

    await reference.set(
      {
        ...context.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<CommunicationContext?> getContact(
    String contactId,
  ) async {
    final snapshot = await contactReference(contactId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return CommunicationContext.fromMap(data);
  }

  Stream<CommunicationContext?> watchContact(
    String contactId,
  ) {
    return contactReference(contactId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      return CommunicationContext.fromMap(data);
    });
  }
}
