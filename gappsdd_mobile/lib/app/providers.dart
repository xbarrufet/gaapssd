import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/chat/data/chat_repository.dart';
import '../features/visits/data/supabase_visits_repository.dart';
import '../features/visits/data/sqlite_visits_repository.dart';
import '../features/visits/data/visits_repository.dart';

/// Use Supabase if user is logged in, otherwise fall back to SQLite/Fake.
final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    return SupabaseVisitsRepository();
  }
  // Fallback to SQLite for offline or unauthenticated use
  return SqliteVisitsRepository();
});

/// Singleton provider for the chat repository.
/// TODO: Create SupabaseChatRepository when chat feature is connected.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SqliteChatRepository();
});
