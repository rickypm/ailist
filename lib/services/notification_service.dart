import 'package:flutter/foundation.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // Uncomment when adding FCM
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance; // Uncomment when adding FCM

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      // await _requestPermission();
      
      // Get FCM token
      // final token = await _messaging.getToken();
      // if (token != null) {
      //   await _saveFCMToken(token);
      // }
      
      // Listen for token refresh
      // _messaging.onTokenRefresh.listen(_saveFCMToken);
      
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      // Uncomment when adding FCM
      // final settings = await _messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      // return settings.authorizationStatus == AuthorizationStatus.authorized;
      return true;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  /// Save FCM token to database
  Future<void> saveFCMToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'device_type': 'android', // or detect platform
        'is_active': true,
        'last_active_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, device_type, device_id');
      
      debugPrint('FCM token saved');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Get notifications for user
  Future<List<Map<String, dynamic>>> getNotifications(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Send local notification for new message
  Future<void> showMessageNotification({
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    // Implement local notification display
    debugPrint('New message from $senderName: $message');
  }

  /// Send notification for unlock
  Future<void> showUnlockNotification({
    required String professionalName,
  }) async {
    // Implement local notification display
    debugPrint('Unlocked $professionalName');
  }

  /// Create in-app notification
  Future<void> createInAppNotification({
    required String userId,
    required String title,
    required String message,
    String notificationType = 'general',
    String? actionType,
    String? actionId,
  }) async {
    try {
      // FIXED: Changed 'message' to 'body' to match schema column name
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': message,  // FIXED: was 'message', now 'body'
        'notification_type': notificationType,
        'action_type': actionType,
        'action_id': actionId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating in-app notification: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Subscribe to realtime notifications
  void subscribeToNotifications(String userId, Function(Map<String, dynamic>) onNotification) {
    _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNotification(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from realtime notifications
  Future<void> unsubscribeFromNotifications(String userId) async {
    await _supabase.channel('notifications:$userId').unsubscribe();
  }
}