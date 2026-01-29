import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class RealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController> _streamControllers = {};

  /// Subscribe to messages in a conversation
  Stream<List<MessageModel>> subscribeToMessages(String conversationId) {
    final channelKey = 'messages:$conversationId';

    _streamControllers.putIfAbsent(
      channelKey,
      () => StreamController<List<MessageModel>>.broadcast(),
    );

    if (!_channels.containsKey(channelKey)) {
      final channel = _supabase
          .channel(channelKey)
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              _handleMessageInsert(conversationId, payload.newRecord);
            },
          )
          .subscribe();

      _channels[channelKey] = channel;
    }

    return (_streamControllers[channelKey] as StreamController<List<MessageModel>>).stream;
  }

  Future<void> _handleMessageInsert(
    String conversationId,
    Map<String, dynamic> newRecord,
  ) async {
    try {
      final channelKey = 'messages:$conversationId';

      final data = await _supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = (data as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      if (_streamControllers.containsKey(channelKey)) {
        (_streamControllers[channelKey] as StreamController<List<MessageModel>>)
            .add(messages);
      }
    } catch (e) {
      debugPrint('Error handling message insert: $e');
    }
  }

  Stream<List<ConversationModel>> subscribeToConversations(
    String odId, {
    bool isPartner = false,
  }) {
    final channelKey = 'conversations:$odId:$isPartner';

    _streamControllers.putIfAbsent(
      channelKey,
      () => StreamController<List<ConversationModel>>.broadcast(),
    );

    if (!_channels.containsKey(channelKey)) {
      final channel = _supabase
          .channel(channelKey)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            callback: (_) {
              _handleConversationChange(odId, isPartner);
            },
          )
          .subscribe();

      _channels[channelKey] = channel;
    }

    return (_streamControllers[channelKey] as StreamController<List<ConversationModel>>).stream;
  }

  Future<void> _handleConversationChange(String odId, bool isPartner) async {
    try {
      final channelKey = 'conversations:$odId:$isPartner';

      String query;
      if (isPartner) {
        final professional = await _supabase
            .from('professionals')
            .select('id')
            .eq('user_id', odId)
            .maybeSingle();

        if (professional == null) return;
        query = 'professional_id.eq.${professional['id']}';
      } else {
        query = 'user_id.eq.$odId';
      }

      final data = await _supabase
          .from('conversations')
          .select('*, users(name, avatar_url), professionals(display_name, avatar_url, profession)')
          .or(query)
          .order('last_message_at', ascending: false);

      final conversations = (data as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();

      if (_streamControllers.containsKey(channelKey)) {
        (_streamControllers[channelKey] as StreamController<List<ConversationModel>>)
            .add(conversations);
      }
    } catch (e) {
      debugPrint('Error handling conversation change: $e');
    }
  }

  Stream<Map<String, bool>> subscribeToPresence(List<String> userIds) {
    final channelKey = 'presence:${userIds.join(',')}';

    _streamControllers.putIfAbsent(
      channelKey,
      () => StreamController<Map<String, bool>>.broadcast(),
    );

    if (!_channels.containsKey(channelKey)) {
      final channel = _supabase.channel(channelKey);

      channel.onPresenceSync((payload) {
        final presenceMap = {for (final id in userIds) id: false};

        try {
          final state = channel.presenceState(); // List<Presence> / List<SinglePresenceState>
          for (final presence in state) {
            final userId = presence.payload['user_id'] as String?;
            if (userId != null && presenceMap.containsKey(userId)) {
              presenceMap[userId] = true;
            }
          }
        } catch (e) {
          debugPrint('Error getting presence state: $e');
        }

        if (_streamControllers.containsKey(channelKey)) {
          (_streamControllers[channelKey] as StreamController<Map<String, bool>>)
              .add(presenceMap);
        }
      });

      channel.subscribe();
      _channels[channelKey] = channel;
    }

    return (_streamControllers[channelKey] as StreamController<Map<String, bool>>).stream;
  }

  Future<void> trackPresence(String odId) async {
    try {
      final channel = _supabase.channel('presence:tracking');
      channel.subscribe(); // subscribe before track
      await channel.track({
        'user_id': odId,
        'online_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error tracking presence: $e');
    }
  }

  void unsubscribe(String channelKey) {
    _channels[channelKey]?.unsubscribe();
    _channels.remove(channelKey);

    _streamControllers[channelKey]?.close();
    _streamControllers.remove(channelKey);
  }

  void unsubscribeAll() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();

    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }

  void dispose() {
    unsubscribeAll();
  }
}