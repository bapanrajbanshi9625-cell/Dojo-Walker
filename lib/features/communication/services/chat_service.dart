import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _messages(
    String contactId,
  ) {
    return _firestore
        .collection('contacts')
        .doc(contactId)
        .collection('messages');
  }

  Stream<List<ChatMessage>> watchMessages(
    String contactId,
  ) {
    return _messages(contactId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChatMessage.fromDocument)
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String contactId,
    required ChatSenderType senderType,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User is not authenticated.');
    }

    await _messages(contactId).add({
      'senderUid': user.uid,
      'senderType': senderType.name,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });

    await _firestore.collection('contacts').doc(contactId).set(
      {
        'lastMessage': cleanText,
        'lastMessageSenderUid': user.uid,
        'lastMessageSenderType': senderType.name,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markMessageSeen({
    required String contactId,
    required String messageId,
  }) async {
    await _messages(contactId).doc(messageId).set(
      {
        'seen': true,
      },
      SetOptions(merge: true),
    );
  }
}
