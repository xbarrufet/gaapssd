/// Roles in messaging system
enum MessageRole { gardener, client }

/// Content types for messages
enum MessageContentType { text, image, document }

/// Actions a client can take on a "requires response" message
enum ResponseAction { accept, reject, moreInfo }

/// Model for a single message
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.senderRole,
    required this.contentType,
    required this.content,
    required this.createdAt,
    this.mediaUrl,
    this.mediaFileName,
    this.mediaMimeType,
    this.isRead = false,
    this.readAt,
    this.requiresResponse = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final MessageRole senderRole;
  final MessageContentType contentType;
  final String content;
  final DateTime createdAt;
  
  final String? mediaUrl;
  final String? mediaFileName;
  final String? mediaMimeType;
  
  final bool isRead;
  final DateTime? readAt;
  final bool requiresResponse;

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? recipientId,
    MessageRole? senderRole,
    MessageContentType? contentType,
    String? content,
    DateTime? createdAt,
    String? mediaUrl,
    String? mediaFileName,
    String? mediaMimeType,
    bool? isRead,
    DateTime? readAt,
    bool? requiresResponse,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      senderRole: senderRole ?? this.senderRole,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaFileName: mediaFileName ?? this.mediaFileName,
      mediaMimeType: mediaMimeType ?? this.mediaMimeType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      requiresResponse: requiresResponse ?? this.requiresResponse,
    );
  }
}

/// Model for a response to a "requires response" message
class MessageResponse {
  const MessageResponse({
    required this.id,
    required this.messageId,
    required this.conversationId,
    required this.responderId,
    required this.action,
    required this.createdAt,
    this.additionalMessage,
    this.updatedAt,
  });

  final String id;
  final String messageId;
  final String conversationId;
  final String responderId;
  final ResponseAction action;
  final DateTime createdAt;
  
  final String? additionalMessage;
  final DateTime? updatedAt;

  MessageResponse copyWith({
    String? id,
    String? messageId,
    String? conversationId,
    String? responderId,
    ResponseAction? action,
    DateTime? createdAt,
    String? additionalMessage,
    DateTime? updatedAt,
  }) {
    return MessageResponse(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      responderId: responderId ?? this.responderId,
      action: action ?? this.action,
      createdAt: createdAt ?? this.createdAt,
      additionalMessage: additionalMessage ?? this.additionalMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model for a conversation between a gardener and a client
class Conversation {
  const Conversation({
    required this.id,
    required this.gardenerId,
    required this.clientId,
    required this.createdAt,
    this.visitId,
    this.gardenId,
    this.status = 'ACTIVE',
    this.lastMessageAt,
    this.unreadMessageCount = 0,
    this.updatedAt,
  });

  final String id;
  final String gardenerId;
  final String clientId;
  final DateTime createdAt;
  
  final String? visitId;
  final String? gardenId;
  
  final String status; // ACTIVE | ARCHIVED
  final DateTime? lastMessageAt;
  final int unreadMessageCount;
  final DateTime? updatedAt;

  Conversation copyWith({
    String? id,
    String? gardenerId,
    String? clientId,
    DateTime? createdAt,
    String? visitId,
    String? gardenId,
    String? status,
    DateTime? lastMessageAt,
    int? unreadMessageCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      gardenerId: gardenerId ?? this.gardenerId,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      visitId: visitId ?? this.visitId,
      gardenId: gardenId ?? this.gardenId,
      status: status ?? this.status,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// DTO for displaying conversation in list
class ConversationListItem {
  const ConversationListItem({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatarUrl;
  final String lastMessagePreview;
  final DateTime lastMessageAt;
  final int unreadCount;
}

/// DTO for displaying a chat thread
class ChatThread {
  const ChatThread({
    required this.conversationId,
    required this.contactName,
    required this.contactAvatarUrl,
    required this.contactRole,
    required this.messages,
    required this.responses,
  });

  final String conversationId;
  final String contactName;
  final String contactAvatarUrl;
  final String contactRole;
  final List<Message> messages;
  final Map<String, MessageResponse> responses; // Keyed by messageId

  ChatThread copyWith({
    String? conversationId,
    String? contactName,
    String? contactAvatarUrl,
    String? contactRole,
    List<Message>? messages,
    Map<String, MessageResponse>? responses,
  }) {
    return ChatThread(
      conversationId: conversationId ?? this.conversationId,
      contactName: contactName ?? this.contactName,
      contactAvatarUrl: contactAvatarUrl ?? this.contactAvatarUrl,
      contactRole: contactRole ?? this.contactRole,
      messages: messages ?? this.messages,
      responses: responses ?? this.responses,
    );
  }
}