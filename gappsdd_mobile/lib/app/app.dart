import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class GappsddApp extends ConsumerWidget {
  const GappsddApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'GAPP Garden',
      theme: AppTheme.light(platform: defaultTargetPlatform),
      darkTheme: AppTheme.dark(platform: defaultTargetPlatform),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
