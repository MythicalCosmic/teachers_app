import 'package:flutter/foundation.dart';

enum MessagingKind { text, image, video, voice }

enum MessagingDelivery { sending, sent, delivered, read }

/// The server-approved recipient class used by the new-conversation picker.
///
/// This is intentionally narrower than a free-form role string. A contact can
/// only enter the picker as staff or as a student returned by the scoped
/// messaging directory; parent/manager-style rows and unknown values fail
/// closed in the controller.
enum MessagingContactKind { staff, student, unknown }

@immutable
class MessagingContact {
  const MessagingContact({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.role,
    this.kind = MessagingContactKind.staff,
    this.bio = '',
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String username;
  final String phone;
  final String role;
  final MessagingContactKind kind;
  final String bio;
  final bool isOnline;

  bool get isStudent => kind == MessagingContactKind.student;
}

@immutable
class MessagingMessage {
  const MessagingMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.sentAt,
    this.body = '',
    this.kind = MessagingKind.text,
    this.mediaLabel,
    this.mediaDuration,
    this.attachmentKeys = const <String>[],
    this.isDemoMedia = false,
    this.delivery = MessagingDelivery.read,
    this.reactions = const <String, int>{},
  });

  final String id;
  final String senderId;
  final String senderName;
  final DateTime sentAt;
  final String body;
  final MessagingKind kind;
  final String? mediaLabel;
  final Duration? mediaDuration;
  final List<String> attachmentKeys;

  /// True when the attachment is a locally generated interaction preview.
  ///
  /// Keeping this in persisted state prevents the UI from presenting demo
  /// metadata as if it came from the device camera, gallery, or microphone.
  final bool isDemoMedia;
  final MessagingDelivery delivery;
  final Map<String, int> reactions;

  String get preview => switch (kind) {
    MessagingKind.text => body,
    MessagingKind.image => '📷 ${mediaLabel ?? 'Rasm'}',
    MessagingKind.video => '🎬 ${mediaLabel ?? 'Video'}',
    MessagingKind.voice => '🎙 Ovozli xabar',
  };

  MessagingMessage copyWith({
    MessagingDelivery? delivery,
    Map<String, int>? reactions,
  }) => MessagingMessage(
    id: id,
    senderId: senderId,
    senderName: senderName,
    sentAt: sentAt,
    body: body,
    kind: kind,
    mediaLabel: mediaLabel,
    mediaDuration: mediaDuration,
    attachmentKeys: attachmentKeys,
    isDemoMedia: isDemoMedia,
    delivery: delivery ?? this.delivery,
    reactions: reactions ?? this.reactions,
  );
}

@immutable
class MessagingThread {
  const MessagingThread({
    required this.id,
    required this.title,
    required this.contact,
    required this.participantIds,
    required this.messages,
    this.isGroup = false,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.isRead = true,
    this.folderIds = const <String>{},
  });

  final String id;
  final String title;
  final MessagingContact contact;
  final Set<String> participantIds;
  final List<MessagingMessage> messages;
  final bool isGroup;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;
  final bool isRead;
  final Set<String> folderIds;

  MessagingMessage? get lastMessage => messages.lastOrNull;
  DateTime? get lastActivity => lastMessage?.sentAt;

  MessagingThread copyWith({
    List<MessagingMessage>? messages,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    bool? isRead,
    Set<String>? folderIds,
  }) => MessagingThread(
    id: id,
    title: title,
    contact: contact,
    participantIds: participantIds,
    messages: messages ?? this.messages,
    isGroup: isGroup,
    isPinned: isPinned ?? this.isPinned,
    isMuted: isMuted ?? this.isMuted,
    isArchived: isArchived ?? this.isArchived,
    isRead: isRead ?? this.isRead,
    folderIds: folderIds ?? this.folderIds,
  );
}

@immutable
class MessagingFolder {
  const MessagingFolder({required this.id, required this.name});

  final String id;
  final String name;
}
