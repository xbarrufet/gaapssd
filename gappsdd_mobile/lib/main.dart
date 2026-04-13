import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/supabase/supabase_client.dart';
import 'features/notifications/notification_service.dart';
import 'firebase_options.dart';

/// Handles FCM messages when the app is in the background or terminated.
/// Must be a top-level function annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background messages are delivered as system notifications by FCM automatically.
}

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash visible while we initialize
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await initSupabase();
  runApp(const ProviderScope(child: GappsddApp()));
  _initFirebase();
  // Remove splash once the first frame is rendered
  FlutterNativeSplash.remove();
}

/// Initializes Firebase and push notification handlers in the background.
/// Errors are logged but never crash the app.
Future<void> _initFirebase() async {
  try {
    debugPrint('[Firebase] initializeApp...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[Firebase] initializeApp OK');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('[Firebase] calling NotificationService.initialize()...');
    await NotificationService.instance.initialize();
    debugPrint('[Firebase] NotificationService.initialize() OK');
  } catch (e, st) {
    debugPrint('[Firebase] init error: $e\n$st');
  }
}
