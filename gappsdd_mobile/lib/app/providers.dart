import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/notifications/notification_service.dart';
import '../features/visits/data/supabase_visits_repository.dart';
import '../features/visits/data/sqlite_visits_repository.dart';
import '../features/visits/data/visits_repository.dart';

/// Use Supabase when authenticated, SQLite otherwise.
/// Watches authProvider so the repo switches correctly after login/logout.
final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  final auth = ref.watch(authProvider);
  if (auth != null) {
    return SupabaseVisitsRepository();
  }
  return SqliteVisitsRepository();
});

/// Singleton provider for the chat repository.
/// TODO: Create SupabaseChatRepository when chat feature is connected.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SqliteChatRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});
