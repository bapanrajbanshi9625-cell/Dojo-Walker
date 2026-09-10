import 'package:cloud_firestore/cloud_firestore.dart';

class CommunicationContext {
  const CommunicationContext({
    required this.contactId,
    required this.ownerUid,
    required this.walkerUid,
    required this.requestId,
    required this.sessionId,
    this.ownerPhone,
    this.walkerPhone,
  });

  final String contactId;
  final String ownerUid;
  final String walkerUid;
  final String requestId;
  final String sessionId;
  final String? ownerPhone;
  final String? walkerPhone;

  factory CommunicationContext.fromMap(
    Map<String, dynamic> data,
  ) {
    return CommunicationContext(
      contactId: data['contactId']?.toString() ?? '',
      ownerUid: data['ownerUid']?.toString() ?? '',
      walkerUid: data['walkerUid']?.toString() ?? '',
      requestId: data['requestId']?.toString() ?? '',
      sessionId: data['sessionId']?.toString() ?? '',
      ownerPhone: data['ownerPhone']?.toString(),
      walkerPhone: data['walkerPhone']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactId': contactId,
      'ownerUid': ownerUid,
      'walkerUid': walkerUid,
      'requestId': requestId,
      'sessionId': sessionId,
      if (ownerPhone != null) 'ownerPhone': ownerPhone,
      if (walkerPhone != null) 'walkerPhone': walkerPhone,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      ...toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CommunicationContext copyWith({
    String? contactId,
    String? ownerUid,
    String? walkerUid,
    String? requestId,
    String? sessionId,
    String? ownerPhone,
    String? walkerPhone,
  }) {
    return CommunicationContext(
      contactId: contactId ?? this.contactId,
      ownerUid: ownerUid ?? this.ownerUid,
      walkerUid: walkerUid ?? this.walkerUid,
      requestId: requestId ?? this.requestId,
      sessionId: sessionId ?? this.sessionId,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      walkerPhone: walkerPhone ?? this.walkerPhone,
    );
  }
}
