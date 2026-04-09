import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/contact_switcher.dart';
import 'widgets/message_bubble.dart';

class ChatWithRequestModesScreen extends ConsumerStatefulWidget {
  const ChatWithRequestModesScreen({
    super.key,
    required this.repository,
    required this.conversationId,
    required this.currentUserId,
    required this.currentUserRole,
  });

  final ChatRepository repository;
  final String conversationId;
  final String currentUserId;
  final MessageRole currentUserRole;

  @override
  ConsumerState<ChatWithRequestModesScreen> createState() => _ChatWithRequestModesScreenState();
}

class _ChatWithRequestModesScreenState extends ConsumerState<ChatWithRequestModesScreen> {
  ChatThread? _thread;
  final _inputController = TextEditingController();
  bool _isLoadingThread = true;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadThread({String? conversationId}) async {
    final targetConversationId = conversationId ?? _thread?.conversationId ?? widget.conversationId;

    try {
      final thread = await ref.read(chatRepositoryProvider).loadThread(
        conversationId: targetConversationId,
        currentUserId: widget.currentUserId,
      );
      setState(() {
        _thread = thread;
        _isLoadingThread = false;
      });
    } catch (e) {
      setState(() => _isLoadingThread = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage({required bool requiresResponse}) async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thread == null) return;

    try {
      final message = await ref.read(chatRepositoryProvider).sendMessage(
        conversationId: _thread!.conversationId,
        senderId: widget.currentUserId,
        recipientId: _thread!.contactName,
        content: text,
        contentType: MessageContentType.text,
        senderRole: widget.currentUserRole,
        requiresResponse: requiresResponse,
      );

      setState(() {
        _thread = _thread!.copyWith(
          messages: [..._thread!.messages, message],
        );
        _inputController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _respondToMessage({
    required String messageId,
    required ResponseAction action,
    String? additionalMessage,
  }) async {
    if (_thread == null) return;

    try {
      final response = await ref.read(chatRepositoryProvider).respondToMessage(
        messageId: messageId,
        conversationId: _thread!.conversationId,
        responderId: widget.currentUserId,
        action: action,
        additionalMessage: additionalMessage,
      );

      setState(() {
        _thread = _thread!.copyWith(
          responses: {..._thread!.responses, messageId: response},
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error responding: $e')),
        );
      }
    }
  }

  Future<void> _openContactSwitcher() async {
    if (_thread == null) return;

    final conversations = await ref.read(chatRepositoryProvider).loadConversations(
      userId: widget.currentUserId,
      limit: 10,
    );

    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => ContactSwitcherBottomSheet(
        conversations: conversations,
        currentConversationId: _thread!.conversationId,
        onSelectConversation: (conversationId) {
          Navigator.pop(context);
          if (conversationId == _thread!.conversationId) return;

          setState(() {
            _isLoadingThread = true;
          });
          _loadThread(conversationId: conversationId);
        },
      ),
    );
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    if (widget.currentUserRole == MessageRole.gardener) {
      context.go(AppRoutes.gardenerVisits);
    } else {
      context.go(AppRoutes.clientVisits);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingThread) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_thread == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading conversation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _handleBackNavigation(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final thread = _thread!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ChatHeader(
              thread: thread,
              onBackTap: _handleBackNavigation,
              onTapContactSwitcher: _openContactSwitcher,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Today',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...thread.messages.map((message) {
                    final response = thread.responses[message.id];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MessageBubble(
                        message: message,
                        response: response,
                        isCurrentUserSender: message.senderId == widget.currentUserId,
                        isCurrentUserGardener: widget.currentUserRole == MessageRole.gardener,
                        onAccept: () => _respondToMessage(
                          messageId: message.id,
                          action: ResponseAction.accept,
                        ),
                        onReject: () => _respondToMessage(
                          messageId: message.id,
                          action: ResponseAction.reject,
                        ),
                        onMoreInfo: (additionalMessage) => _respondToMessage(
                          messageId: message.id,
                          action: ResponseAction.moreInfo,
                          additionalMessage: additionalMessage,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatInputBar(
            controller: _inputController,
            onSendSimple: () => _sendMessage(requiresResponse: false),
            onSendWithResponse: () => _sendMessage(requiresResponse: true),
            isGardener: widget.currentUserRole == MessageRole.gardener,
          ),
          // Bottom nav handled by shell route when accessed via tab navigation.
          // When pushed from visit detail, no bottom nav is shown (correct behavior).
        ],
      ),
    );
  }
}
