import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/visits/data/sqlite_visits_repository.dart';
import '../features/visits/data/visits_repository.dart';
import 'theme/app_theme.dart';

class GappsddApp extends StatelessWidget {
  const GappsddApp({super.key});

  @override
  Widget build(BuildContext context) {
    final VisitsRepository visitsRepository = SqliteVisitsRepository();
    final ChatRepository chatRepository = SqliteChatRepository();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GAPP Garden',
      theme: AppTheme.light(),
      home: LoginScreen(
        visitsRepository: visitsRepository,
        chatRepository: chatRepository,
      ),
    );
  }
}