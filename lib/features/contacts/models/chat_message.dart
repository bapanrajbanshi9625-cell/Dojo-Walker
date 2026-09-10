import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType {
  text,
  photo,
  voice,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.type,
    this.text = '',
    this.mediaUrl,
    this.durationSeconds,
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String senderUid;
  final String receiverUid;
  final ChatMessageType type;
  final String text;
  final String? mediaUrl;
  final int? durationSeconds;
  final DateTime? createdAt;
  final bool isRead;

  bool isMine(String currentUid) {
    return senderUid == currentUid;
  }

  String get typeValue {
    switch (type) {
      case ChatMessageType.text:
        return 'text';
      case ChatMessageType.photo:
        return 'photo';
      case ChatMessageType.voice:
        return 'voice';
    }
  }

  ChatMessage copyWith({
    String? id,
    String? senderUid,
    String? receiverUid,
    ChatMessageType? type,
    String? text,
    String? mediaUrl,
    int? durationSeconds,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderUid: senderUid ?? this.senderUid,
      receiverUid: receiverUid ?? this.receiverUid,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'type': typeValue,
      'text': text,
      'mediaUrl': mediaUrl,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ChatMessage(
      id: id,
      senderUid: (map['senderUid'] ?? '').toString(),
      receiverUid: (map['receiverUid'] ?? '').toString(),
      type: _messageTypeFromString(
        (map['type'] ?? 'text').toString(),
      ),
      text: (map['text'] ?? '').toString(),
      mediaUrl: _nullableString(map['mediaUrl']),
      durationSeconds: _nullableInt(map['durationSeconds']),
      createdAt: _dateTimeFromValue(map['createdAt']),
      isRead: map['isRead'] == true,
    );
  }

  static ChatMessageType _messageTypeFromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'photo':
      case 'image':
        return ChatMessageType.photo;

      case 'voice':
      case 'audio':
        return ChatMessageType.voice;

      case 'text':
      default:
        return ChatMessageType.text;
    }
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _dateTimeFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
