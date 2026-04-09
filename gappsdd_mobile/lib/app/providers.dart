import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/data/chat_repository.dart';
import '../features/visits/data/sqlite_visits_repository.dart';
import '../features/visits/data/visits_repository.dart';

/// Singleton provider for the visits repository.
final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  return SqliteVisitsRepository();
});

/// Singleton provider for the chat repository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SqliteChatRepository();
});
