import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatSenderType {
  owner,
  walker,
}

class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.senderUid,
    required this.senderType,
    required this.text,
    required this.createdAt,
    this.seen = false,
  });

  final String messageId;
  final String senderUid;
  final ChatSenderType senderType;
  final String text;
  final DateTime? createdAt;
  final bool seen;

  bool get isOwner => senderType == ChatSenderType.owner;
  bool get isWalker => senderType == ChatSenderType.walker;

  factory ChatMessage.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final timestamp = data['createdAt'];

    return ChatMessage(
      messageId: document.id,
      senderUid: data['senderUid']?.toString() ?? '',
      senderType: _senderTypeFromString(
        data['senderType']?.toString(),
      ),
      text: data['text']?.toString() ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : null,
      seen: data['seen'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'senderType': senderType.name,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': seen,
    };
  }

  static ChatSenderType _senderTypeFromString(
    String? value,
  ) {
    if (value == ChatSenderType.owner.name) {
      return ChatSenderType.owner;
    }

    return ChatSenderType.walker;
  }
}
