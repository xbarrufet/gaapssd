import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/domain/auth_state.dart';

/// Provides the current unread message status.
/// Screens can call `ref.read(chatUnreadProvider.notifier).refresh()`
/// after navigation returns from chat.
class ChatUnreadNotifier extends StateNotifier<bool> {
  ChatUnreadNotifier(this._ref) : super(false) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final auth = _ref.read(authProvider);
    if (auth == null) {
      state = false;
      return;
    }

    try {
      final chatRepo = _ref.read(chatRepositoryProvider);
      final conversations = await chatRepo.loadConversations(
        userId: auth.userId,
        limit: 10,
      );
      state = conversations.any((c) => c.unreadCount > 0);
    } catch (_) {
      state = false;
    }
  }
}

final chatUnreadProvider =
    StateNotifierProvider<ChatUnreadNotifier, bool>((ref) {
  return ChatUnreadNotifier(ref);
});
