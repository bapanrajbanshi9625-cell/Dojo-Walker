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

  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';

  String get currentUid {
    return _auth.currentUser?.uid ?? '';
  }

  String buildConversationId(
    String firstUid,
    String secondUid,
  ) {
    final List<String> ids = <String>[
      firstUid.trim(),
      secondUid.trim(),
    ]..sort();

    return ids.join('_');
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String conversationId,
  ) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection);
  }

  Stream<List<ChatMessage>> messagesStream({
    required String otherUid,
  }) {
    final String myUid = currentUid;
    final String contactUid = otherUid.trim();

    if (myUid.isEmpty || contactUid.isEmpty) {
      return const Stream<List<ChatMessage>>.empty();
    }

    final String conversationId = buildConversationId(
      myUid,
      contactUid,
    );

    return _messagesRef(conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            return snapshot.docs
                .map(
                  (
                    QueryDocumentSnapshot<Map<String, dynamic>> doc,
                  ) {
                    return ChatMessage.fromMap(
                      doc.id,
                      doc.data(),
                    );
                  },
                )
                .toList();
          },
        );
  }

  Future<String?> sendTextMessage({
    required String receiverUid,
    required String text,
  }) async {
    final String senderUid = currentUid;
    final String recipientUid = receiverUid.trim();
    final String messageText = text.trim();

    if (senderUid.isEmpty ||
        recipientUid.isEmpty ||
        messageText.isEmpty) {
      return null;
    }

    return _sendMessage(
      receiverUid: recipientUid,
      message: ChatMessage(
        id: '',
        senderUid: senderUid,
        receiverUid: recipientUid,
        type: ChatMessageType.text,
        text: messageText,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<String?> sendPhotoMessage({
    required String receiverUid,
    required String mediaUrl,
  }) async {
    final String senderUid = currentUid;
    final String recipientUid = receiverUid.trim();
    final String url = mediaUrl.trim();

    if (senderUid.isEmpty ||
        recipientUid.isEmpty ||
        url.isEmpty) {
      return null;
    }

    return _sendMessage(
      receiverUid: recipientUid,
      message: ChatMessage(
        id: '',
        senderUid: senderUid,
        receiverUid: recipientUid,
        type: ChatMessageType.photo,
        mediaUrl: url,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<String?> sendVoiceMessage({
    required String receiverUid,
    required String mediaUrl,
    int? durationSeconds,
  }) async {
    final String senderUid = currentUid;
    final String recipientUid = receiverUid.trim();
    final String url = mediaUrl.trim();

    if (senderUid.isEmpty ||
        recipientUid.isEmpty ||
        url.isEmpty) {
      return null;
    }

    return _sendMessage(
      receiverUid: recipientUid,
      message: ChatMessage(
        id: '',
        senderUid: senderUid,
        receiverUid: recipientUid,
        type: ChatMessageType.voice,
        mediaUrl: url,
        durationSeconds: durationSeconds,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<String?> _sendMessage({
    required String receiverUid,
    required ChatMessage message,
  }) async {
    final String senderUid = currentUid;

    if (senderUid.isEmpty || receiverUid.trim().isEmpty) {
      return null;
    }

    final String conversationId = buildConversationId(
      senderUid,
      receiverUid,
    );

    final DocumentReference<Map<String, dynamic>> conversationRef =
        _firestore
            .collection(_conversationsCollection)
            .doc(conversationId);

    final DocumentReference<Map<String, dynamic>> messageRef =
        _messagesRef(conversationId).doc();

    final WriteBatch batch = _firestore.batch();

    batch.set(
      conversationRef,
      <String, dynamic>{
        'participantUids': <String>[
          senderUid,
          receiverUid,
        ],
        'lastMessageType': message.typeValue,
        'lastMessageText': _lastMessagePreview(message),
        'lastMessageUrl': message.mediaUrl,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderUid': senderUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      messageRef,
      message.toMap(),
    );

    await batch.commit();

    return messageRef.id;
  }

  Future<void> markMessageAsRead({
    required String otherUid,
    required String messageId,
  }) async {
    final String myUid = currentUid;
    final String contactUid = otherUid.trim();
    final String id = messageId.trim();

    if (myUid.isEmpty ||
        contactUid.isEmpty ||
        id.isEmpty) {
      return;
    }

    final String conversationId = buildConversationId(
      myUid,
      contactUid,
    );

    await _messagesRef(conversationId)
        .doc(id)
        .update(<String, dynamic>{
      'isRead': true,
    });
  }

  Future<void> markAllMessagesAsRead({
    required String otherUid,
  }) async {
    final String myUid = currentUid;
    final String contactUid = otherUid.trim();

    if (myUid.isEmpty || contactUid.isEmpty) {
      return;
    }

    final String conversationId = buildConversationId(
      myUid,
      contactUid,
    );

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _messagesRef(conversationId)
            .where('receiverUid', isEqualTo: myUid)
            .where('isRead', isEqualTo: false)
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      batch.update(
        doc.reference,
        <String, dynamic>{
          'isRead': true,
        },
      );
    }

    await batch.commit();
  }

  Future<void> deleteMessage({
    required String otherUid,
    required String messageId,
  }) async {
    final String myUid = currentUid;
    final String contactUid = otherUid.trim();
    final String id = messageId.trim();

    if (myUid.isEmpty ||
        contactUid.isEmpty ||
        id.isEmpty) {
      return;
    }

    final String conversationId = buildConversationId(
      myUid,
      contactUid,
    );

    final DocumentReference<Map<String, dynamic>> ref =
        _messagesRef(conversationId).doc(id);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await ref.get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    if ((data['senderUid'] ?? '').toString() != myUid) {
      return;
    }

    await ref.delete();
  }

  String _lastMessagePreview(ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.text:
        return message.text;

      case ChatMessageType.photo:
        return '📷 Photo';

      case ChatMessageType.voice:
        return '🎙️ Voice message';
    }
  }
}
