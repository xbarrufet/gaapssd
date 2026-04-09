import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/chat_models.dart';

class ContactSwitcherBottomSheet extends StatelessWidget {
  const ContactSwitcherBottomSheet({
    super.key,
    required this.conversations,
    required this.currentConversationId,
    required this.onSelectConversation,
  });

  final List<ConversationListItem> conversations;
  final String currentConversationId;
  final ValueChanged<String> onSelectConversation;

  @override
  Widget build(BuildContext context) {
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
          if (conversations.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Text(
                'No conversations available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final contact = conversations[index];
                final unread = contact.unreadCount;
                final isSelected = contact.conversationId == currentConversationId;
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
                  title: Text(contact.otherUserName),
                  subtitle: Text(contact.lastMessagePreview),
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
                      : (isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null),
                  onTap: () {
                    onSelectConversation(contact.conversationId);
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
