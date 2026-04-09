import 'package:flutter_test/flutter_test.dart';
import 'package:gappsdd/app/theme/app_theme.dart';
import 'package:gappsdd/features/chat/data/chat_repository.dart';
import 'package:gappsdd/features/chat/domain/chat_models.dart';

void main() {
  group('ChatRepository - Message Handling', () {
    late SqliteChatRepository repository;

    setUpAll(() {
      repository = SqliteChatRepository();
    });

    test('Message has correct initial state', () {
      final msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        recipientId: 'user-2',
        senderRole: MessageRole.gardener,
        contentType: MessageContentType.text,
        content: 'Hello',
        createdAt: DateTime.now(),
      );

      expect(msg.id, 'msg-1');
      expect(msg.senderRole, MessageRole.gardener);
      expect(msg.contentType, MessageContentType.text);
      expect(msg.isRead, false);
      expect(msg.requiresResponse, false);
    });

    test('Message copyWith updates fields correctly', () {
      final original = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        recipientId: 'user-2',
        senderRole: MessageRole.gardener,
        contentType: MessageContentType.text,
        content: 'Hello',
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        isRead: true,
        requiresResponse: true,
      );

      expect(updated.isRead, true);
      expect(updated.requiresResponse, true);
      expect(updated.id, original.id); // Should remain same
    });

    test('Message supports different content types', () {
      expect(MessageContentType.text, MessageContentType.text);
      expect(MessageContentType.image, MessageContentType.image);
      expect(MessageContentType.document, MessageContentType.document);
    });
  });

  group('ChatRepository - MessageResponse Handling', () {
    test('MessageResponse tracks all action types', () {
      final acceptResp = MessageResponse(
        id: 'resp-1',
        messageId: 'msg-1',
        conversationId: 'conv-1',
        responderId: 'user-2',
        action: ResponseAction.accept,
        createdAt: DateTime.now(),
      );

      final rejectResp = MessageResponse(
        id: 'resp-2',
        messageId: 'msg-2',
        conversationId: 'conv-1',
        responderId: 'user-2',
        action: ResponseAction.reject,
        createdAt: DateTime.now(),
      );

      final moreInfoResp = MessageResponse(
        id: 'resp-3',
        messageId: 'msg-3',
        conversationId: 'conv-1',
        responderId: 'user-2',
        action: ResponseAction.moreInfo,
        createdAt: DateTime.now(),
        additionalMessage: '¿Cuánto cuesta?',
      );

      expect(acceptResp.action, ResponseAction.accept);
      expect(rejectResp.action, ResponseAction.reject);
      expect(moreInfoResp.action, ResponseAction.moreInfo);
      expect(moreInfoResp.additionalMessage, '¿Cuánto cuesta?');
    });

    test('MessageResponse copyWith preserves data', () {
      final original = MessageResponse(
        id: 'resp-1',
        messageId: 'msg-1',
        conversationId: 'conv-1',
        responderId: 'user-2',
        action: ResponseAction.moreInfo,
        createdAt: DateTime.now(),
        additionalMessage: 'Original',
      );

      final updated = original.copyWith(
        additionalMessage: 'Updated',
      );

      expect(updated.additionalMessage, 'Updated');
      expect(updated.action, ResponseAction.moreInfo);
    });
  });

  group('ChatRepository - Conversation Management', () {
    test('Conversation initializes with correct defaults', () {
      final conv = Conversation(
        id: 'conv-1',
        gardenerId: 'gardener-1',
        clientId: 'client-1',
        createdAt: DateTime.now(),
      );

      expect(conv.status, 'ACTIVE');
      expect(conv.unreadMessageCount, 0);
      expect(conv.visitId, null);
    });

    test('Conversation with optional fields', () {
      final now = DateTime.now();
      final conv = Conversation(
        id: 'conv-1',
        gardenerId: 'gardener-1',
        clientId: 'client-1',
        createdAt: now,
        visitId: 'visit-123',
        gardenId: 'garden-456',
        lastMessageAt: now,
        unreadMessageCount: 5,
      );

      expect(conv.visitId, 'visit-123');
      expect(conv.gardenId, 'garden-456');
      expect(conv.unreadMessageCount, 5);
    });
  });

  group('ChatRepository - Role Conversions', () {
    test('MessageRole enum has two values', () {
      expect(MessageRole.values.length, 2);
      expect(MessageRole.values.contains(MessageRole.gardener), true);
      expect(MessageRole.values.contains(MessageRole.client), true);
    });

    test('MessageContentType enum has three values', () {
      expect(MessageContentType.values.length, 3);
      expect(MessageContentType.values.contains(MessageContentType.text), true);
      expect(MessageContentType.values.contains(MessageContentType.image), true);
      expect(MessageContentType.values.contains(MessageContentType.document), true);
    });

    test('ResponseAction enum has three values', () {
      expect(ResponseAction.values.length, 3);
      expect(ResponseAction.values.contains(ResponseAction.accept), true);
      expect(ResponseAction.values.contains(ResponseAction.reject), true);
      expect(ResponseAction.values.contains(ResponseAction.moreInfo), true);
    });
  });

  group('ChatRepository - ChatThread DTO', () {
    test('ChatThread aggregates messages and responses', () {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'gardener-1',
          recipientId: 'client-1',
          senderRole: MessageRole.gardener,
          contentType: MessageContentType.text,
          content: 'Test message',
          createdAt: DateTime.now(),
        ),
      ];

      final responses = {
        'msg-1': MessageResponse(
          id: 'resp-1',
          messageId: 'msg-1',
          conversationId: 'conv-1',
          responderId: 'client-1',
          action: ResponseAction.accept,
          createdAt: DateTime.now(),
        ),
      };

      final thread = ChatThread(
        conversationId: 'conv-1',
        contactName: 'Juan Martinez',
        contactAvatarUrl: 'https://example.com/avatar.jpg',
        contactRole: 'Gardener',
        messages: messages,
        responses: responses,
      );

      expect(thread.messages.length, 1);
      expect(thread.responses.length, 1);
      expect(thread.responses['msg-1']?.action, ResponseAction.accept);
    });

    test('ChatThread copyWith updates messages', () {
      final original = ChatThread(
        conversationId: 'conv-1',
        contactName: 'John',
        contactAvatarUrl: 'url',
        contactRole: 'Gardener',
        messages: [],
        responses: {},
      );

      final newMessages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'gardener-1',
          recipientId: 'client-1',
          senderRole: MessageRole.gardener,
          contentType: MessageContentType.text,
          content: 'New message',
          createdAt: DateTime.now(),
        ),
      ];

      final updated = original.copyWith(messages: newMessages);

      expect(updated.messages.length, 1);
      expect(original.messages.length, 0); // Original unmodified
    });
  });

  group('ChatRepository - ConversationListItem', () {
    test('ConversationListItem displays correct info', () {
      final item = ConversationListItem(
        conversationId: 'conv-1',
        otherUserId: 'user-123',
        otherUserName: 'Juan Martinez',
        otherUserAvatarUrl: 'https://example.com/avatar.jpg',
        lastMessagePreview: 'Hello there!',
        lastMessageAt: DateTime.now(),
        unreadCount: 3,
      );

      expect(item.conversationId, 'conv-1');
      expect(item.otherUserName, 'Juan Martinez');
      expect(item.unreadCount, 3);
    });
  });
}
