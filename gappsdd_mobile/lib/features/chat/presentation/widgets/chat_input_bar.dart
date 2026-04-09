import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSendSimple,
    required this.onSendWithResponse,
    required this.isGardener,
  });

  final TextEditingController controller;
  final VoidCallback onSendSimple;
  final VoidCallback onSendWithResponse;
  final bool isGardener;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _isLongPressing = false;

  Future<void> _showSendOptions() async {
    setState(() {
      _isLongPressing = true;
    });

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.send_rounded),
                title: const Text('Envío simple'),
                subtitle: const Text('Mensaje normal sin respuesta requerida'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onSendSimple();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mark_chat_unread_rounded),
                title: const Text('Envío con respuesta'),
                subtitle: const Text('El cliente debe aceptar, rechazar o pedir más info'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onSendWithResponse();
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _isLongPressing = false;
    });
  }

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
                onLongPress: _showSendOptions,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLongPressing
                        ? Colors.orange.withValues(alpha: 0.8)
                        : AppColors.primary,
                  ),
                  child: IconButton(
                    onPressed: widget.onSendSimple,
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
                  onPressed: widget.onSendSimple,
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
