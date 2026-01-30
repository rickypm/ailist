import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Handle background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.messageId}');
  debugPrint('📩 Title: ${message.notification?.title}');
  debugPrint('📩 Body: ${message.notification?.body}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  String? _deviceToken;
  String? get deviceToken => _deviceToken;

  // Callback for handling notification taps
  Function(Map<String, dynamic>)? onNotificationTap;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing push notifications...');

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await _requestPermission();

      // Get device token
      await _getToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed');
        _deviceToken = newToken;
        _saveTokenToDatabase(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from notification (terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📩 App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      debugPrint('✅ Push notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Push notification init error: $e');
    }
  }

  // ============================================================
  // REQUEST PERMISSION
  // ============================================================

  Future<bool> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted full permission');
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional permission');
        return true;
      } else {
        debugPrint('❌ User declined permission');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error requesting permission: $e');
      return false;
    }
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    try {
      _deviceToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: ${_deviceToken?.substring(0, 50)}...');
      return _deviceToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // ============================================================
  // REGISTER DEVICE
  // ============================================================

  Future<void> registerDevice(String userId) async {
    if (_deviceToken == null) {
      await _getToken();
    }

    if (_deviceToken == null) {
      debugPrint('❌ No device token available');
      return;
    }

    await _saveTokenToDatabase(_deviceToken!, userId: userId);
  }

  Future<void> _saveTokenToDatabase(String token, {String? userId}) async {
    try {
      final uid = userId ?? _supabase.auth.currentUser?.id;
      if (uid == null) {
        debugPrint('⚠️ No user logged in, skipping token save');
        return;
      }

      final platform = _getPlatform();
      debugPrint('📱 Saving device token for platform: $platform');

      await _supabase.from('user_devices').upsert(
        {
          'user_id': uid,
          'device_token': token,
          'platform': platform,
          'is_active': true,
          'last_used_at': DateTime.now().toIso8601String(),
          'device_info': {
            'registered_at': DateTime.now().toIso8601String(),
          },
        },
        onConflict: 'user_id,device_token',
      );

      debugPrint('✅ Device token saved to database');
    } catch (e) {
      debugPrint('❌ Error saving device token: $e');
    }
  }

  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  // ============================================================
  // UNREGISTER DEVICE
  // ============================================================

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
      debugPrint('❌ Error unregistering device: $e');
    }
  }

  // ============================================================
  // HANDLE FOREGROUND MESSAGE
  // ============================================================

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 ========== FOREGROUND MESSAGE ==========');
    debugPrint('📩 Message ID: ${message.messageId}');
    debugPrint('📩 Title: ${message.notification?.title}');
    debugPrint('📩 Body: ${message.notification?.body}');
    debugPrint('📩 Data: ${message.data}');
    debugPrint('📩 ==========================================');

    // You can show a local notification or in-app snackbar here
    // For now, the notification will show automatically on Android
  }

  // ============================================================
  // HANDLE NOTIFICATION TAP
  // ============================================================

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 ========== NOTIFICATION TAPPED ==========');
    debugPrint('👆 Message ID: ${message.messageId}');
    debugPrint('👆 Data: ${message.data}');
    debugPrint('👆 ==========================================');

    // Call the callback if set
    if (onNotificationTap != null) {
      onNotificationTap!(message.data);
    }

    // Handle navigation based on action
    final actionType = message.data['action_type'];
    final actionData = message.data['action_data'];

    if (actionType == 'open_screen' && actionData != null) {
      debugPrint('📱 Should navigate to: $actionData');
      // Navigation will be handled by the callback
    }
  }

  // ============================================================
  // SUBSCRIBE TO TOPICS
  // ============================================================

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  // ============================================================
  // SUBSCRIBE USER TO DEFAULT TOPICS
  // ============================================================

  Future<void> subscribeToUserTopics(String userRole) async {
    // Subscribe to general announcements
    await subscribeToTopic('all_users');
    
    // Subscribe based on role
    if (userRole == 'partner' || userRole == 'professional') {
      await subscribeToTopic('partners');
    } else {
      await subscribeToTopic('users');
    }
  }
}