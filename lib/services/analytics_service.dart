import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Log a custom event
  Future<void> logEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    try {
      await _supabase.from('analytics_events').insert({
        'event_name': eventName,
        'parameters': parameters,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? userId,
  }) async {
    await logEvent(
      eventName: 'screen_view',
      parameters: {'screen_name': screenName},
      userId: userId,
    );
  }

  /// Log search
  Future<void> logSearch({
    required String query,
    int resultsCount = 0,
    String? userId,
  }) async {
    await logEvent(
      eventName: 'search',
      parameters: {
        'query': query,
        'results_count': resultsCount,
      },
      userId: userId,
    );
  }

  /// Log professional view
  Future<void> logProfessionalView({
    required String professionalId,
    String? userId,
  }) async {
    await logEvent(
      eventName: 'professional_view',
      parameters: {'professional_id': professionalId},
      userId: userId,
    );
  }

  /// Log unlock
  Future<void> logUnlock({
    required String professionalId,
    required String userId,
  }) async {
    await logEvent(
      eventName: 'professional_unlock',
      parameters: {'professional_id': professionalId},
      userId: userId,
    );
  }

  /// Log subscription
  Future<void> logSubscription({
    required String plan,
    required int amount,
    required String userId,
  }) async {
    await logEvent(
      eventName: 'subscription',
      parameters: {
        'plan': plan,
        'amount': amount,
      },
      userId: userId,
    );
  }

  /// Log message sent
  Future<void> logMessageSent({
    required String conversationId,
    required String senderId,
    required String senderType,
  }) async {
    await logEvent(
      eventName: 'message_sent',
      parameters:  {
        'conversation_id':  conversationId,
        'sender_type': senderType,
      },
      userId: senderId,
    );
  }
}