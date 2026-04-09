import 'package:flutter_test/flutter_test.dart';
import 'package:gappsdd/features/chat/domain/chat_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  final now = DateTime(2026, 4, 8, 12, 0);

  Message _message({String id = 'm1'}) => Message(
        id: id,
        conversationId: 'c1',
        senderId: 's1',
        recipientId: 'r1',
        senderRole: MessageRole.gardener,
        contentType: MessageContentType.text,
        content: 'Hello',
        createdAt: now,
      );

  MessageResponse _messageResponse({String id = 'mr1'}) => MessageResponse(
        id: id,
        messageId: 'm1',
        conversationId: 'c1',
        responderId: 'r1',
        action: ResponseAction.accept,
        createdAt: now,
      );

  Conversation _conversation({String id = 'c1'}) => Conversation(
        id: id,
        gardenerId: 'g1',
        clientId: 'cl1',
        createdAt: now,
      );

  ConversationListItem _listItem({String conversationId = 'c1'}) =>
      ConversationListItem(
        conversationId: conversationId,
        otherUserId: 'u2',
        otherUserName: 'Alice',
        otherUserAvatarUrl: 'https://example.com/avatar.jpg',
        lastMessagePreview: 'Hello',
        lastMessageAt: now,
        unreadCount: 0,
      );

  ChatThread _chatThread({String conversationId = 'c1'}) => ChatThread(
        conversationId: conversationId,
        contactName: 'Alice',
        contactAvatarUrl: 'https://example.com/avatar.jpg',
        contactRole: 'Gardener',
        messages: const [],
        responses: const {},
      );

  // ---------------------------------------------------------------------------
  // Equality tests
  // ---------------------------------------------------------------------------

  group('Message equality', () {
    test('same id are equal', () {
      expect(_message(id: 'm1'), equals(_message(id: 'm1')));
    });

    test('different ids are not equal', () {
      expect(_message(id: 'a'), isNot(equals(_message(id: 'b'))));
    });
  });

  group('MessageResponse equality', () {
    test('same id are equal', () {
      expect(
          _messageResponse(id: 'mr1'), equals(_messageResponse(id: 'mr1')));
    });
  });

  group('Conversation equality', () {
    test('same id are equal', () {
      expect(_conversation(id: 'c1'), equals(_conversation(id: 'c1')));
    });
  });

  group('ConversationListItem equality', () {
    test('same conversationId are equal', () {
      expect(_listItem(conversationId: 'c1'),
          equals(_listItem(conversationId: 'c1')));
    });
  });

  group('ChatThread equality', () {
    test('same conversationId are equal', () {
      expect(_chatThread(conversationId: 'c1'),
          equals(_chatThread(conversationId: 'c1')));
    });
  });

  // ---------------------------------------------------------------------------
  // Enum tests
  // ---------------------------------------------------------------------------

  group('ConversationStatus enum', () {
    test('has active and archived values', () {
      expect(ConversationStatus.values,
          containsAll([ConversationStatus.active, ConversationStatus.archived]));
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith tests
  // ---------------------------------------------------------------------------

  group('Message.copyWith', () {
    test('preserves unmodified fields', () {
      final original = _message(id: 'm1');
      final copied = original.copyWith(content: 'Updated');

      expect(copied.id, equals(original.id));
      expect(copied.conversationId, equals(original.conversationId));
      expect(copied.senderId, equals(original.senderId));
      expect(copied.recipientId, equals(original.recipientId));
      expect(copied.senderRole, equals(original.senderRole));
      expect(copied.contentType, equals(original.contentType));
      expect(copied.createdAt, equals(original.createdAt));
      expect(copied.isRead, equals(original.isRead));
      expect(copied.requiresResponse, equals(original.requiresResponse));
      // The changed field
      expect(copied.content, equals('Updated'));
    });
  });

  group('Conversation.copyWith', () {
    test('preserves unmodified fields', () {
      final original = _conversation(id: 'c1');
      final copied =
          original.copyWith(status: ConversationStatus.archived);

      expect(copied.id, equals(original.id));
      expect(copied.gardenerId, equals(original.gardenerId));
      expect(copied.clientId, equals(original.clientId));
      expect(copied.createdAt, equals(original.createdAt));
      expect(copied.unreadMessageCount, equals(original.unreadMessageCount));
      // The changed field
      expect(copied.status, equals(ConversationStatus.archived));
    });
  });
}
