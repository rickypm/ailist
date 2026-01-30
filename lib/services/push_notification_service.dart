import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  String? _deviceToken;
  String? get deviceToken => _deviceToken;

  Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing push notifications...');

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _requestPermission();
      
      // ✅ Get fresh token
      await _getAndPrintFullToken();

      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed');
        _deviceToken = newToken;
        _saveTokenToDatabase(newToken);
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('✅ Push notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Push notification init error: $e');
    }
  }

  Future<bool> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('🔔 Permission: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('❌ Permission error: $e');
      return false;
    }
  }

  // ✅ Get and print full token
  Future<String?> _getAndPrintFullToken() async {
    try {
      _deviceToken = await _messaging.getToken();

      if (_deviceToken != null) {
        debugPrint('');
        debugPrint('╔═══════════════════════════════════════════════════════════╗');
        debugPrint('║ ��� FCM DEVICE TOKEN                                       ║');
        debugPrint('╠═══════════════════════════════════════════════════════════╣');
        debugPrint('║ Length: ${_deviceToken!.length} characters');
        debugPrint('╠═══════════════════════════════════════════════════════════╣');
        
        // Print in chunks to avoid truncation
        final token = _deviceToken!;
        final chunkSize = 60;
        for (var i = 0; i < token.length; i += chunkSize) {
          final end = (i + chunkSize < token.length) ? i + chunkSize : token.length;
          debugPrint('║ ${token.substring(i, end)}');
        }
        
        debugPrint('╚═══════════════════════════════════════════════════════════╝');
        debugPrint('');
      }

      return _deviceToken;
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  // ✅ Register device with full token
  Future<void> registerDevice(String userId) async {
    if (_deviceToken == null) {
      await _getAndPrintFullToken();
    }

    if (_deviceToken == null) {
      debugPrint('❌ No device token available');
      return;
    }

    debugPrint('📤 Registering device for user: $userId');
    debugPrint('📤 Token length: ${_deviceToken!.length}');

    await _saveTokenToDatabase(_deviceToken!, userId: userId);
  }

  // ✅ Save full token to database
  Future<void> _saveTokenToDatabase(String token, {String? userId}) async {
    try {
      final uid = userId ?? _supabase.auth.currentUser?.id;
      if (uid == null) {
        debugPrint('⚠️ No user logged in');
        return;
      }

      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');

      debugPrint('💾 Saving to Supabase...');
      debugPrint('💾 User ID: $uid');
      debugPrint('💾 Platform: $platform');
      debugPrint('💾 Token length: ${token.length}');

      // Delete old tokens for this user first (optional - clean up)
      await _supabase
          .from('user_devices')
          .delete()
          .eq('user_id', uid)
          .eq('platform', platform);

      // Insert fresh token
      await _supabase.from('user_devices').insert({
        'user_id': uid,
        'device_token': token,
        'platform': platform,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Device token saved to Supabase!');
      
      // Verify it was saved
      final verify = await _supabase
          .from('user_devices')
          .select('id, device_token')
          .eq('user_id', uid)
          .eq('platform', platform)
          .single();
      
      debugPrint('✅ Verified in DB - Token length: ${verify['device_token'].toString().length}');

    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  Future<void> unregisterDevice(String userId) async {
    if (_deviceToken == null) return;

    try {
      await _supabase
          .from('user_devices')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('device_token', _deviceToken!);

      debugPrint('✅ Device unregistered');
    } catch (e) {
      debugPrint('❌ Error unregistering: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 FOREGROUND MESSAGE:');
    debugPrint('📩 Title: ${message.notification?.title}');
    debugPrint('📩 Body: ${message.notification?.body}');

    _showInAppNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  void _showInAppNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
        content: Text(body, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');
    onNotificationTap?.call(message.data);
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to: $topic');
  }

  Future<void> subscribeToUserTopics(String userRole) async {
    await subscribeToTopic('all_users');
    await subscribeToTopic(userRole == 'partner' ? 'partners' : 'users');
  }
}