import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

class ChatWithRequestModesScreen extends StatefulWidget {
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
  State<ChatWithRequestModesScreen> createState() => _ChatWithRequestModesScreenState();
}

class _ChatWithRequestModesScreenState extends State<ChatWithRequestModesScreen> {
  ChatThread? _thread;
  final _inputController = TextEditingController();
  bool _isLoadingThread = true;
  bool _sendWithResponse = false;

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

  Future<void> _loadThread() async {
    try {
      final thread = await widget.repository.loadThread(
        conversationId: widget.conversationId,
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

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _thread == null) return;

    try {
      final message = await widget.repository.sendMessage(
        conversationId: widget.conversationId,
        senderId: widget.currentUserId,
        recipientId: _thread!.contactName,
        content: text,
        contentType: MessageContentType.text,
        senderRole: widget.currentUserRole,
        requiresResponse: _sendWithResponse,
      );

      setState(() {
        _thread = _thread!.copyWith(
          messages: [..._thread!.messages, message],
        );
        _inputController.clear();
        _sendWithResponse = false;
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
      final response = await widget.repository.respondToMessage(
        messageId: messageId,
        conversationId: widget.conversationId,
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
                onPressed: () => Navigator.of(context).pop(),
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
            _ChatHeader(thread: thread),
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
                      child: _MessageBubble(
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
      bottomNavigationBar: _ChatInputBar(
        controller: _inputController,
        onSend: _sendMessage,
        onLongPressStart: () => setState(() => _sendWithResponse = true),
        onLongPressEnd: () => setState(() => _sendWithResponse = false),
        isLongPressing: _sendWithResponse,
        isGardener: widget.currentUserRole == MessageRole.gardener,
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showContactSwitcher(context, thread);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          border: Border(bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primary,
            ),
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: thread.contactAvatarUrl.isNotEmpty
                      ? Image.network(
                          thread.contactAvatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
                        )
                      : const Icon(Icons.person_rounded),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread.contactName, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    thread.contactRole.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showContactSwitcher(BuildContext context, ChatThread thread) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ContactSwitcherBottomSheet(
        currentContact: thread.contactName,
      ),
    );
  }
}

class _ContactSwitcherBottomSheet extends StatelessWidget {
  const _ContactSwitcherBottomSheet({required this.currentContact});

  final String currentContact;

  @override
  Widget build(BuildContext context) {
    final contacts = [
      {'name': currentContact, 'preview': 'Last message...', 'unread': 0},
      {'name': 'Juan Martinez', 'preview': 'How much for the poda?', 'unread': 2},
      {'name': 'Sofia Garcia', 'preview': 'Thanks for the work!', 'unread': 0},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Conversations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final unread = contact['unread'] as int;
                return ListTile(
                  leading: Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(contact['name'] as String),
                  subtitle: Text(contact['preview'] as String),
                  trailing: unread > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.response,
    required this.isCurrentUserSender,
    required this.isCurrentUserGardener,
    required this.onAccept,
    required this.onReject,
    required this.onMoreInfo,
  });

  final Message message;
  final MessageResponse? response;
  final bool isCurrentUserSender;
  final bool isCurrentUserGardener;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final Function(String) onMoreInfo;

  @override
  Widget build(BuildContext context) {
    final isIncoming = !isCurrentUserSender;

    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: message.contentType == MessageContentType.image
            ? _ImageMessageBubble(message: message, isIncoming: isIncoming)
            : _TextMessageBubble(
                message: message,
                response: response,
                isIncoming: isIncoming,
                isCurrentUserGardener: isCurrentUserGardener,
                onAccept: onAccept,
                onReject: onReject,
                onMoreInfo: onMoreInfo,
              ),
      ),
    );
  }
}

class _TextMessageBubble extends StatefulWidget {
  const _TextMessageBubble({
    required this.message,
    required this.response,
    required this.isIncoming,
    required this.isCurrentUserGardener,
    required this.onAccept,
    required this.onReject,
    required this.onMoreInfo,
  });

  final Message message;
  final MessageResponse? response;
  final bool isIncoming;
  final bool isCurrentUserGardener;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final Function(String) onMoreInfo;

  @override
  State<_TextMessageBubble> createState() => _TextMessageBubbleState();
}

class _TextMessageBubbleState extends State<_TextMessageBubble> {
  bool _showMoreInfoInput = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isIncoming ? AppColors.surfaceHigh : AppColors.primaryContainer;
    final fg = widget.isIncoming ? AppColors.textPrimary : AppColors.onPrimary;
    final hasResponse = widget.response != null;

    return Column(
      crossAxisAlignment:
          widget.isIncoming ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.isIncoming ? 8 : 22),
              topRight: Radius.circular(widget.isIncoming ? 22 : 8),
              bottomLeft: const Radius.circular(22),
              bottomRight: const Radius.circular(22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Text(
                  widget.message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
              if (widget.message.requiresResponse && widget.isIncoming && !hasResponse)
                _ResponseButtonGroup(
                  onAccept: widget.onAccept,
                  onReject: widget.onReject,
                  onMoreInfo: () => setState(() => _showMoreInfoInput = true),
                )
              else if (hasResponse)
                _ResponseStatus(response: widget.response!),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Text(
                  _formatTime(widget.message.createdAt),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: widget.isIncoming ? AppColors.textMuted : AppColors.surfaceLow,
                        fontSize: 9,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (_showMoreInfoInput && widget.isIncoming && !hasResponse)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _MoreInfoInputField(
              onSubmit: (text) {
                widget.onMoreInfo(text);
                setState(() => _showMoreInfoInput = false);
              },
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

class _ResponseButtonGroup extends StatelessWidget {
  const _ResponseButtonGroup({
    required this.onAccept,
    required this.onReject,
    required this.onMoreInfo,
  });

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onMoreInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onAccept,
                    child: const Text('ACEPTAR'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('RECHAZAR'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: onMoreInfo,
              child: const Text('MÁS INFO'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseStatus extends StatelessWidget {
  const _ResponseStatus({required this.response});

  final MessageResponse response;

  @override
  Widget build(BuildContext context) {
    final icon = response.action == ResponseAction.accept
        ? '✓'
        : response.action == ResponseAction.reject
            ? '✗'
            : '📝';

    final color = response.action == ResponseAction.accept
        ? Colors.green
        : response.action == ResponseAction.reject
            ? Colors.red
            : Colors.blue;

    final label = response.action == ResponseAction.accept
        ? 'Aceptado'
        : response.action == ResponseAction.reject
            ? 'Rechazado'
            : 'Solicitó más info';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          Text(icon, style: TextStyle(color: color, fontSize: 16)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MoreInfoInputField extends StatefulWidget {
  const _MoreInfoInputField({required this.onSubmit});

  final Function(String) onSubmit;

  @override
  State<_MoreInfoInputField> createState() => _MoreInfoInputFieldState();
}

class _MoreInfoInputFieldState extends State<_MoreInfoInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                widget.onSubmit(text);
              }
            },
            icon: const Icon(Icons.send),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ImageMessageBubble extends StatelessWidget {
  const _ImageMessageBubble({
    required this.message,
    required this.isIncoming,
  });

  final Message message;
  final bool isIncoming;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isIncoming ? 8 : 22),
          topRight: Radius.circular(isIncoming ? 22 : 8),
          bottomLeft: const Radius.circular(22),
          bottomRight: const Radius.circular(22),
        ),
      ),
      child: Stack(
        children: [
          Image.network(
            message.mediaUrl ?? '',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 320,
              height: 200,
              color: AppColors.surfaceLow,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
          if (message.mediaFileName != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                padding: const EdgeInsets.all(8),
                child: Text(
                  message.mediaFileName!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.isLongPressing,
    required this.isGardener,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final bool isLongPressing;
  final bool isGardener;

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.isGardener)
              GestureDetector(
                onLongPressStart: (_) => widget.onLongPressStart(),
                onLongPressEnd: (_) => widget.onLongPressEnd(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isLongPressing
                        ? Colors.orange.withValues(alpha: 0.8)
                        : AppColors.primary,
                  ),
                  child: IconButton(
                    onPressed: widget.onSend,
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: IconButton(
                  onPressed: widget.onSend,
                  icon: const Icon(Icons.send),
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
