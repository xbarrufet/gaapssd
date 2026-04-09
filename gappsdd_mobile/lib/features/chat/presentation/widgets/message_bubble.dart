import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/chat_models.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
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
    final (icon, label, fg, bg) = switch (response.action) {
      ResponseAction.accept => (
          Icons.check_circle_rounded,
          'Aceptado',
          const Color(0xFF1B5E20),
          const Color(0xFFE8F5E9),
        ),
      ResponseAction.reject => (
          Icons.cancel_rounded,
          'Rechazado',
          const Color(0xFF7F1D1D),
          const Color(0xFFFEE2E2),
        ),
      ResponseAction.moreInfo => (
          Icons.help_outline_rounded,
          'Solicitó más info',
          const Color(0xFF1E3A8A),
          const Color(0xFFE0E7FF),
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
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
