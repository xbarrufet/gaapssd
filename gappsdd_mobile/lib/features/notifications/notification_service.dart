import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/nav_keys.dart';

/// Singleton service that manages FCM push notifications.
///
/// Responsibilities:
/// - Foreground notification display (flutter_local_notifications)
/// - Navigation on notification tap (via rootNavigatorKey)
/// - FCM token registration/deregistration in Supabase device_tokens
/// - Auto token management on Supabase auth state changes
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  // late: defers access to FirebaseMessaging.instance until Firebase is initialized
  late final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'gapp_visits';
  static const _androidChannelName = 'Visitas GAPP';

  /// Call once from main() after Firebase.initializeApp().
  Future<void> initialize() async {
    debugPrint('[NS] initialize: localNotifications.initialize...');
    // Local notifications: used to display banners when app is in foreground
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    debugPrint('[NS] initialize: localNotifications OK');

    // Android notification channel (required for Android 8+)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
        ));

    debugPrint('[NS] initialize: setForegroundNotificationPresentationOptions...');
    // iOS: show banner + badge + sound when app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[NS] initialize: foreground options OK');

    // Foreground message → show local notification banner
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // User taps notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    debugPrint('[NS] initialize: getInitialMessage...');
    // App was launched from terminated state by tapping a notification.
    // Timeout guard: getInitialMessage() can hang on iOS before permissions are granted.
    final initialMessage = await _messaging.getInitialMessage()
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    debugPrint('[NS] initialize: getInitialMessage OK (${initialMessage != null ? "has message" : "null"})');
    if (initialMessage != null) {
      // Delay to allow the widget tree to be ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }

    // If a session already exists when initialize() is called (login happened
    // before Firebase was ready), register the token immediately.
    final currentUser = Supabase.instance.client.auth.currentUser;
    debugPrint('[NS] initialize: currentUser=${currentUser?.id ?? "null"}');
    if (currentUser != null) {
      await registerToken(currentUser.id);
    }

    // Auto-register/deregister token on Supabase auth state changes.
    // Register for all roles: the backend only delivers notifications to users
    // with a matching client_profile, so gardener tokens are safely ignored.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        await registerToken(data.session!.user.id);
      } else if (data.event == AuthChangeEvent.signedOut) {
        await _deleteCurrentToken();
      }
    });

    // Keep token fresh if FCM rotates it
    _messaging.onTokenRefresh.listen((token) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _upsertToken(user.id, token);
      }
    });
  }

  /// Requests push notification permission from the OS.
  /// Called from ClientVisitsScreen on first entry (iOS needs explicit request).
  /// After permission is granted, registers the FCM token if a user is logged in.
  /// No-op if Firebase hasn't finished initializing yet.
  Future<void> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission status: ${settings.authorizationStatus}');
      // APNs token is only available after permission is granted.
      // Re-register now that we know permission is authorized.
      final authorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (authorized) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await registerToken(user.id);
        }
      }
    } catch (e) {
      debugPrint('requestPermission skipped (Firebase not ready): $e');
    }
  }

  /// Fetches the current FCM token and upserts it in Supabase device_tokens.
  Future<void> registerToken(String userId) async {
    // On iOS, the APNs token must be available before FCM can issue a token.
    // Retry for up to 10 seconds to handle the startup race condition.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apns;
      for (var i = 0; i < 10; i++) {
        apns = await _messaging.getAPNSToken();
        if (apns != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }
      if (apns == null) {
        debugPrint('FCM registerToken: APNs token not available after 10s, skipping');
        return;
      }
      debugPrint('FCM registerToken: APNs token OK');
    }

    final token = await _messaging.getToken();
    debugPrint('FCM registerToken: userId=$userId token=${token == null ? "NULL" : "${token.substring(0, 20)}..."}');
    if (token == null) return;
    await _upsertToken(userId, token);
  }

  Future<void> _upsertToken(String userId, String token) async {
    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    await Supabase.instance.client.from('device_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id, token',
    );
  }

  Future<void> _deleteCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await Supabase.instance.client
          .from('device_tokens')
          .delete()
          .eq('token', token);
    } catch (_) {
      // Best-effort: token cleanup on logout should not block sign-out
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final visitId = data['visitId'] as String?;

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    if (type == 'visit_ended' && visitId != null) {
      context.push('/client/visit-report', extra: visitId);
    } else if (type == 'visit_started') {
      context.go('/client/visits');
    }
  }
}
