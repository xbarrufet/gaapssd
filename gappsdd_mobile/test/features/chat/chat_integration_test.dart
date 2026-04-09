import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gappsdd/features/chat/data/chat_repository.dart';
import 'package:gappsdd/features/chat/domain/chat_models.dart';
import 'package:gappsdd/features/chat/presentation/chat_with_request_modes_screen.dart';

void main() {
  group('ChatWithRequestModesScreen', () {
    late SqliteChatRepository mockRepository;

    setUpAll(() {
      mockRepository = SqliteChatRepository();
    });

    testWidgets('UI renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWithRequestModesScreen(
            repository: mockRepository,
            conversationId: 'test-conv-1',
            currentUserId: 'test-user-1',
            currentUserRole: MessageRole.gardener,
          ),
        ),
      );

      // Widget should be instantiated
      expect(find.byType(ChatWithRequestModesScreen), findsOneWidget);
    });
  });

  group('Message Handling', () {
    test('Text message creates correctly', () {
      final msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        recipientId: 'user-2',
        senderRole: MessageRole.gardener,
        contentType: MessageContentType.text,
        content: 'Test message',
        createdAt: DateTime.now(),
      );

      expect(msg.id, 'msg-1');
      expect(msg.content, 'Test message');
      expect(msg.senderRole, MessageRole.gardener);
    });

    test('Image message creates with media info', () {
      final msg = Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-1',
        recipientId: 'user-2',
        senderRole: MessageRole.gardener,
        contentType: MessageContentType.image,
        content: 'Irrigation work',
        createdAt: DateTime.now(),
        mediaUrl: 'file:///path/to/image.jpg',
        mediaFileName: 'irrigation.jpg',
        mediaMimeType: 'image/jpeg',
      );

      expect(msg.contentType, MessageContentType.image);
      expect(msg.mediaFileName, 'irrigation.jpg');
    });

    test('Message with response requirement', () {
      final msg = Message(
        id: 'msg-3',
        conversationId: 'conv-1',
        senderId: 'gardener-1',
        recipientId: 'client-1',
        senderRole: MessageRole.gardener,
        contentType: MessageContentType.text,
        content: 'Approve this work?',
        createdAt: DateTime.now(),
        requiresResponse: true,
      );

      expect(msg.requiresResponse, true);
    });
  });

  group('Response Actions', () {
    test('Accept response is recorded correctly', () {
      final resp = MessageResponse(
        id: 'resp-1',
        messageId: 'msg-1',
        conversationId: 'conv-1',
        responderId: 'client-1',
        action: ResponseAction.accept,
        createdAt: DateTime.now(),
      );

      expect(resp.action, ResponseAction.accept);
      expect(resp.additionalMessage, null);
    });

    test('Reject response is recorded correctly', () {
      final resp = MessageResponse(
        id: 'resp-2',
        messageId: 'msg-1',
        conversationId: 'conv-1',
        responderId: 'client-1',
        action: ResponseAction.reject,
        createdAt: DateTime.now(),
      );

      expect(resp.action, ResponseAction.reject);
    });

    test('More info response includes additional message', () {
      final resp = MessageResponse(
        id: 'resp-3',
        messageId: 'msg-1',
        conversationId: 'conv-1',
        responderId: 'client-1',
        action: ResponseAction.moreInfo,
        createdAt: DateTime.now(),
        additionalMessage: 'Can you include antiplagas treatment?',
      );

      expect(resp.action, ResponseAction.moreInfo);
      expect(resp.additionalMessage, 'Can you include antiplagas treatment?');
    });
  });

  group('Conversation Management', () {
    test('Conversation tracks unread count', () {
      final conv = Conversation(
        id: 'conv-1',
        gardenerId: 'gardener-1',
        clientId: 'client-1',
        createdAt: DateTime.now(),
        unreadMessageCount: 5,
      );

      expect(conv.unreadMessageCount, 5);
    });

    test('Conversation can be archived', () {
      final conv = Conversation(
        id: 'conv-1',
        gardenerId: 'gardener-1',
        clientId: 'client-1',
        createdAt: DateTime.now(),
        status: ConversationStatus.archived,
      );

      expect(conv.status, ConversationStatus.archived);
    });

    test('Conversation linked to visit and garden', () {
      final conv = Conversation(
        id: 'conv-1',
        gardenerId: 'gardener-1',
        clientId: 'client-1',
        createdAt: DateTime.now(),
        visitId: 'visit-123',
        gardenId: 'garden-456',
      );

      expect(conv.visitId, 'visit-123');
      expect(conv.gardenId, 'garden-456');
    });
  });
}
