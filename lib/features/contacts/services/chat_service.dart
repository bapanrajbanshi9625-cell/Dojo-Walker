import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth =
            auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _conversationsCollection =
      'conversations';

  static const String _messagesCollection =
      'messages';

  // ============================================================
  // CURRENT USER
  // ============================================================

  String get currentUid {
    return _auth.currentUser?.uid ?? '';
  }

  // ============================================================
  // CURRENT WALK CHAT ID
  //
  // IMPORTANT:
  // requestId == sessionId.
  //
  // Example:
  // DW123456
  //
  // NEVER build conversation ID from ownerUid + walkerUid.
  // ============================================================

  String buildConversationId({
    required String requestId,
    String? sessionId,
  }) {
    final String cleanRequestId =
        requestId.trim();

    final String cleanSessionId =
        (sessionId ?? requestId).trim();

    if (cleanRequestId.isEmpty) {
      throw ArgumentError(
        'requestId is required for chat.',
      );
    }

    if (cleanSessionId.isEmpty) {
      throw ArgumentError(
        'sessionId is required for chat.',
      );
    }

    if (cleanRequestId != cleanSessionId) {
      throw ArgumentError(
        'requestId and sessionId must match.',
      );
    }

    if (!RegExp(
      r'^DW\d{6}$',
    ).hasMatch(cleanRequestId)) {
      throw ArgumentError(
        'Invalid requestId. Expected DW######.',
      );
    }

    return cleanRequestId;
  }

  // ============================================================
  // MESSAGE REFERENCE
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      _messagesRef(
    String conversationId,
  ) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection);
  }

  // ============================================================
  // MESSAGES STREAM
  //
  // ONLY CURRENT WALK.
  // ============================================================

  Stream<List<ChatMessage>> messagesStream({
    required String requestId,
    String? sessionId,
  }) {
    final String myUid =
        currentUid;

    if (myUid.isEmpty) {
      return const Stream<
          List<ChatMessage>>.empty();
    }

    final String conversationId;

    try {
      conversationId =
          buildConversationId(
        requestId: requestId,
        sessionId: sessionId,
      );
    } catch (_) {
      return const Stream<
          List<ChatMessage>>.empty();
    }

    return _messagesRef(
      conversationId,
    )
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots()
        .map(
          (
            QuerySnapshot<
                Map<String, dynamic>>
                snapshot,
          ) {
            return snapshot.docs
                .map(
                  (
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>
                        doc,
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

  // ============================================================
  // SEND TEXT
  // ============================================================

  Future<String?> sendTextMessage({
    required String receiverUid,
    required String requestId,
    String? sessionId,
    required String text,
  }) async {
    final String senderUid =
        currentUid;

    final String recipientUid =
        receiverUid.trim();

    final String messageText =
        text.trim();

    if (senderUid.isEmpty ||
        recipientUid.isEmpty ||
        messageText.isEmpty) {
      return null;
    }

    return _sendMessage(
      receiverUid: recipientUid,
      requestId: requestId,
      sessionId: sessionId,
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

  // ============================================================
  // SEND PHOTO
  // ============================================================

  Future<String?> sendPhotoMessage({
    required String receiverUid,
    required String requestId,
    String? sessionId,
    required String mediaUrl,
  }) async {
    final String senderUid =
        currentUid;

    final String recipientUid =
        receiverUid.trim();

    final String url =
        mediaUrl.trim();

    if (senderUid.isEmpty ||
        recipientUid.isEmpty ||
        url.isEmpty) {
      return null;
    }

    return _sendMessage(
      receiverUid: recipientUid,
      requestId: requestId,
      sessionId: sessionId,
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

  // ============================================================
  // SEND VOICE
  // ============================================================

  Future<String?> sendVoiceMessage({
    required String receiverUid,
    required String requestId,
    String? sessionId,
    required String mediaUrl,
    int? durationSeconds,
  }) async {
    final String senderUid =
        currentUid;

    final String recipientUid =
        receiverUid.trim();

    final String url =
        mediaUrl.trim();

    if (senderUid.isEmpty ||
        recipientUid.isEmpty ||
        url.isEmpty) {
      return null;
    }

    return _sendMessage(
      receiverUid: recipientUid,
      requestId: requestId,
      sessionId: sessionId,
      message: ChatMessage(
        id: '',
        senderUid: senderUid,
        receiverUid: recipientUid,
        type: ChatMessageType.voice,
        mediaUrl: url,
        durationSeconds:
            durationSeconds,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ============================================================
  // SEND VIDEO
  // ============================================================

  Future<String?> sendVideoMessage({
    required String receiverUid,
    required String requestId,
    String? sessionId,
    required String mediaUrl,
    int? durationSeconds,
  }) async {
    final String senderUid =
        currentUid;

    final String recipientUid =
        receiverUid.trim();

    final String url =
        mediaUrl.trim();

    if (senderUid.isEmpty ||
        recipientUid.isEmpty ||
        url.isEmpty) {
      return null;
    }

    return _sendMessage(
      receiverUid: recipientUid,
      requestId: requestId,
      sessionId: sessionId,
      message: ChatMessage(
        id: '',
        senderUid: senderUid,
        receiverUid: recipientUid,
        type: ChatMessageType.video,
        mediaUrl: url,
        durationSeconds:
            durationSeconds,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ============================================================
  // INTERNAL SEND
  // ============================================================

  Future<String?> _sendMessage({
    required String receiverUid,
    required String requestId,
    String? sessionId,
    required ChatMessage message,
  }) async {
    final String senderUid =
        currentUid;

    final String recipientUid =
        receiverUid.trim();

    if (senderUid.isEmpty ||
        recipientUid.isEmpty) {
      return null;
    }

    final String conversationId =
        buildConversationId(
      requestId: requestId,
      sessionId: sessionId,
    );

    final DocumentReference<
            Map<String, dynamic>>
        conversationRef =
        _firestore
            .collection(
              _conversationsCollection,
            )
            .doc(conversationId);

    final DocumentReference<
            Map<String, dynamic>>
        messageRef =
        _messagesRef(
          conversationId,
        ).doc();

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // CONVERSATION METADATA
    // ==========================================================

    batch.set(
      conversationRef,
      <String, dynamic>{
        'conversationId':
            conversationId,

        // Current walk identifiers.
        'requestId':
            conversationId,

        'sessionId':
            conversationId,

        // Participants.
        'participantUids':
            <String>[
          senderUid,
          recipientUid,
        ],

        'ownerUid':
            message.senderUid == senderUid
                ? recipientUid
                : senderUid,

        'walkerUid':
            message.senderUid == senderUid
                ? senderUid
                : recipientUid,

        'lastMessageType':
            message.typeValue,

        'lastMessageText':
            _lastMessagePreview(
          message,
        ),

        'lastMessageUrl':
            message.mediaUrl,

        'lastMessageAt':
            FieldValue.serverTimestamp(),

        'lastSenderUid':
            senderUid,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // MESSAGE
    // ==========================================================

    batch.set(
      messageRef,
      message.toMap(),
    );

    await batch.commit();

    return messageRef.id;
  }

  // ============================================================
  // MARK ONE MESSAGE READ
  // ============================================================

  Future<void> markMessageAsRead({
    required String requestId,
    String? sessionId,
    required String messageId,
  }) async {
    final String myUid =
        currentUid;

    final String id =
        messageId.trim();

    if (myUid.isEmpty ||
        id.isEmpty) {
      return;
    }

    final String conversationId =
        buildConversationId(
      requestId: requestId,
      sessionId: sessionId,
    );

    final DocumentReference<
            Map<String, dynamic>>
        ref =
        _messagesRef(
          conversationId,
        ).doc(id);

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await ref.get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    final String receiverUid =
        (data['receiverUid'] ?? '')
            .toString()
            .trim();

    if (receiverUid != myUid) {
      return;
    }

    await ref.update(
      <String, dynamic>{
        'isRead': true,
      },
    );
  }

  // ============================================================
  // MARK ALL CURRENT WALK MESSAGES READ
  // ============================================================

  Future<void> markAllMessagesAsRead({
    required String requestId,
    String? sessionId,
  }) async {
    final String myUid =
        currentUid;

    if (myUid.isEmpty) {
      return;
    }

    final String conversationId =
        buildConversationId(
      requestId: requestId,
      sessionId: sessionId,
    );

    final QuerySnapshot<
            Map<String, dynamic>>
        snapshot =
        await _messagesRef(
          conversationId,
        )
            .where(
              'receiverUid',
              isEqualTo: myUid,
            )
            .where(
              'isRead',
              isEqualTo: false,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final WriteBatch batch =
        _firestore.batch();

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc in snapshot.docs) {
      batch.update(
        doc.reference,
        <String, dynamic>{
          'isRead': true,
        },
      );
    }

    await batch.commit();
  }

  // ============================================================
  // DELETE CURRENT WALK MESSAGE
  // ============================================================

  Future<void> deleteMessage({
    required String requestId,
    String? sessionId,
    required String messageId,
  }) async {
    final String myUid =
        currentUid;

    final String id =
        messageId.trim();

    if (myUid.isEmpty ||
        id.isEmpty) {
      return;
    }

    final String conversationId =
        buildConversationId(
      requestId: requestId,
      sessionId: sessionId,
    );

    final DocumentReference<
            Map<String, dynamic>>
        ref =
        _messagesRef(
          conversationId,
        ).doc(id);

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await ref.get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    if ((data['senderUid'] ?? '')
            .toString() !=
        myUid) {
      return;
    }

    await ref.delete();
  }

  // ============================================================
  // LAST MESSAGE PREVIEW
  // ============================================================

  String _lastMessagePreview(
    ChatMessage message,
  ) {
    switch (message.type) {
      case ChatMessageType.text:
        return message.text;

      case ChatMessageType.photo:
        return '📷 Photo';

      case ChatMessageType.voice:
        return '🎙️ Voice message';

      case ChatMessageType.video:
        return '🎥 Video';
    }
  }
}
