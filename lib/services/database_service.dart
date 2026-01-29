import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/professional_model.dart';
import '../models/shop_model.dart';
import '../models/item_model.dart';
import '../models/category_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // ERROR HANDLING
  // ============================================================
  void _handleError(dynamic error) {
    debugPrint('Database Error: ${error.toString()}');
    if (error is PostgrestException) {
      throw 'Database error: ${error.message}';
    }
    throw 'An unexpected error occurred.';
  }

  // ============================================================
  // USER & AUTH
  // ============================================================
  Future<UserModel?> getUser(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      debugPrint('User data loaded: $data');
      return UserModel.fromJson(data);
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('users').update(data).eq('id', userId);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ============================================================
  // PROFESSIONALS
  // ============================================================
  
  Future<ProfessionalModel?> getProfessionalById(String id) async {
    try {
      final data = await _supabase
          .from('professionals')
          .select('*, category:categories(*)')
          .eq('id', id)
          .single();
      return ProfessionalModel.fromJson(data);
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  Future<ProfessionalModel?> getProfessionalByUserId(String userId) async {
    try {
      final data = await _supabase
          .from('professionals')
          .select('*, category:categories(*)')
          .eq('user_id', userId)
          .single();
      return ProfessionalModel.fromJson(data);
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  Future<List<ProfessionalModel>> getProfessionalsByCategory(String categoryId) async {
    try {
      final data = await _supabase
          .from('professionals')
          .select('*, category:categories(*)')
          .eq('category_id', categoryId)
          .eq('is_available', true)
          .order('rating', ascending: false);
      return (data as List).map((e) => ProfessionalModel.fromJson(e)).toList();
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  Future<bool> updateProfessional(String professionalId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('professionals').update(data).eq('id', professionalId);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<List<ProfessionalModel>> searchProfessionals(String query, {String? city}) async {
    try {
      final data = await _supabase.rpc('search_professionals', params: {'search_term': query});
      
      List<ProfessionalModel> results = (data as List).map((e) => ProfessionalModel.fromJson(e)).toList();
      
      if (city != null && city.isNotEmpty) {
        results = results.where((p) => 
          p.city.toLowerCase().contains(city.toLowerCase())
        ).toList();
      }
      
      return results;
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  Future<void> incrementProfileViews(String professionalId) async {
    try {
      await _supabase.rpc('increment_profile_views', params: {'p_professional_id': professionalId});
    } catch (e) {
      debugPrint("Error incrementing views: $e");
    }
  }
  
  // ============================================================
  // UNLOCKS
  // ============================================================
  Future<bool> checkUnlockStatus(String userId, String professionalId) async {
    try {
      final data = await _supabase
        .from('user_unlocks')
        .select('id')
        .eq('user_id', userId)
        .eq('professional_id', professionalId)
        .eq('is_active', true)
        .maybeSingle();
      return data != null;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> unlockProfessional(String userId, String professionalId) async {
    try {
      final result = await _supabase.rpc('unlock_professional', params: {
        'p_user_id': userId,
        'p_professional_id': professionalId,
      });
      
      if (result is Map && result['success'] == true) {
        return true;
      } else if (result is Map && result['error'] != null) {
        throw result['error'];
      }
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<List<ProfessionalModel>> getUnlockedProfessionals(String userId) async {
    try {
      final data = await _supabase
          .from('user_unlocks')
          .select('professional:professionals(*, category:categories(*))')
          .eq('user_id', userId)
          .eq('is_active', true);
          
      final professionals = (data as List)
        .where((e) => e['professional'] != null)
        .map((e) => ProfessionalModel.fromJson(e['professional']))
        .toList();
      return professionals;
    } catch (e) {
      _handleError(e);
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserUnlocks(String userId) async {
    try {
      final data = await _supabase
          .from('user_unlocks')
          .select('*, professional:professionals(display_name, avatar_url)')
          .eq('user_id', userId)
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  // ============================================================
  // CATEGORIES
  // ============================================================
  Future<List<CategoryModel>> getCategories() async {
    try {
      final data = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order');
      return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  // ============================================================
  // SHOPS
  // ============================================================
  Future<ShopModel?> getShopByProfessionalId(String professionalId) async {
    try {
      final data = await _supabase
          .from('shops')
          .select()
          .eq('professional_id', professionalId)
          .maybeSingle();
      return data != null ? ShopModel.fromJson(data) : null;
    } catch (e) {
      _handleError(e);
      return null;
    }
  }
  
  Future<List<ShopModel>> searchShops(String query, {String? city}) async {
    try {
      var request = _supabase
          .from('shops')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%');
      
      if (city != null && city.isNotEmpty) {
        request = request.ilike('city', '%$city%');
      }
      
      final data = await request;
      return (data as List).map((e) => ShopModel.fromJson(e)).toList();
    } catch(e) {
      _handleError(e);
      return [];
    }
  }
  
  Future<ShopModel?> createShop(Map<String, dynamic> data) async {
    try {
      final newShop = await _supabase.from('shops').insert(data).select().single();
      return ShopModel.fromJson(newShop);
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  Future<bool> updateShop(String shopId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('shops').update(data).eq('id', shopId);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ============================================================
  // ITEMS
  // ============================================================
  Future<List<ItemModel>> getItemsByShop(String shopId) async {
    try {
      final data = await _supabase
          .from('items')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .order('display_order');
      return (data as List).map((e) => ItemModel.fromJson(e)).toList();
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFeaturedItems({String? city}) async {
    try {
      final data = await _supabase.rpc('get_featured_items', params: {
        'p_city': city ?? ''
      });
      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _handleError(e);
      return [];
    }
  }
  
  Future<List<ItemModel>> searchItems(String query, {String? city}) async {
    try {
      final data = await _supabase.rpc('search_items', params: {'search_term': query});
      List<ItemModel> results = (data as List).map((e) => ItemModel.fromJson(e)).toList();
      return results;
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  Future<ItemModel?> createItem(Map<String, dynamic> data) async {
    try {
      final newItem = await _supabase.from('items').insert(data).select().single();
      return ItemModel.fromJson(newItem);
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  Future<bool> updateItem(String itemId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('items').update(data).eq('id', itemId);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _supabase.from('items').delete().eq('id', itemId);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ============================================================
  // MESSAGING - ✅ FIXED with fallback
  // ============================================================
  Future<List<ConversationModel>> getConversations(String odId, {bool isPartner = false}) async {
    try {
      final column = isPartner ? 'professional_id' : 'user_id';
      final data = await _supabase
          .from('conversations')
          .select('*, user:users(*), professional:professionals(*, category:categories(*))')
          .eq(column, odId)
          .order('last_message_at', ascending: false);
      return (data as List).map((e) => ConversationModel.fromJson(e)).toList();
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  // ✅ FIX: Get or create conversation with fallback to direct insert
  Future<ConversationModel?> getOrCreateConversation(String userId, String professionalId) async {
    try {
      // First, try to find existing conversation
      final existing = await _supabase
          .from('conversations')
          .select('*, user:users(*), professional:professionals(*, category:categories(*))')
          .eq('user_id', userId)
          .eq('professional_id', professionalId)
          .maybeSingle();
      
      if (existing != null) {
        debugPrint('Found existing conversation');
        return ConversationModel.fromJson(existing);
      }
      
      // If not exists, create new conversation
      debugPrint('Creating new conversation');
      final newConversation = await _supabase
          .from('conversations')
          .insert({
            'user_id': userId,
            'professional_id': professionalId,
            'status': 'active',
            'last_message_at': DateTime.now().toIso8601String(),
            'user_unread_count': 0,
            'professional_unread_count': 0,
          })
          .select('*, user:users(*), professional:professionals(*, category:categories(*))')
          .single();
      
      return ConversationModel.fromJson(newConversation);
    } catch (e) {
      debugPrint('Error in getOrCreateConversation: $e');
      _handleError(e);
      return null;
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return (data as List).map((e) => MessageModel.fromJson(e)).toList();
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  // ✅ FIX: Mark messages as read with fallback
  Future<void> markMessagesAsRead(String conversationId, String readerType) async {
    try {
      // Try RPC first
      await _supabase.rpc('mark_as_read', params: {
        'p_conversation_id': conversationId,
        'p_reader_type': readerType
      });
    } catch (e) {
      debugPrint('RPC mark_as_read failed, using fallback: $e');
      // Fallback: direct update
      try {
        if (readerType == 'user') {
          await _supabase
              .from('conversations')
              .update({'user_unread_count': 0})
              .eq('id', conversationId);
        } else {
          await _supabase
              .from('conversations')
              .update({'professional_unread_count': 0})
              .eq('id', conversationId);
        }
      } catch (e2) {
        debugPrint('Fallback also failed: $e2');
      }
    }
  }

  // ✅ FIX: Send message with fallback to direct insert
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderType,
    required String content,
  }) async {
    try {
      // Direct insert instead of RPC
      final data = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'sender_type': senderType,
            'content': content,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      // Update conversation
      final updateData = {
        'last_message_at': DateTime.now().toIso8601String(),
        'last_message_preview': content.length > 100 ? '${content.substring(0, 100)}...' : content,
      };
      
      // Increment unread count for the other party
      if (senderType == 'user') {
        // User sent message, increment professional's unread
        await _supabase.rpc('increment_professional_unread', params: {'p_conversation_id': conversationId}).catchError((_) async {
          // Fallback if RPC doesn't exist
          final conv = await _supabase.from('conversations').select('professional_unread_count').eq('id', conversationId).single();
          updateData['professional_unread_count'] = (conv['professional_unread_count'] ?? 0) + 1;
        });
      } else {
        // Professional sent message, increment user's unread
        await _supabase.rpc('increment_user_unread', params: {'p_conversation_id': conversationId}).catchError((_) async {
          final conv = await _supabase.from('conversations').select('user_unread_count').eq('id', conversationId).single();
          updateData['user_unread_count'] = (conv['user_unread_count'] ?? 0) + 1;
        });
      }
      
      await _supabase.from('conversations').update(updateData).eq('id', conversationId);
      
      return MessageModel.fromJson(data);
    } catch (e) {
      debugPrint('Error sending message: $e');
      _handleError(e);
      return null;
    }
  }

  // ============================================================
  // SUBSCRIPTIONS & STATS
  // ============================================================
  Future<bool> createSubscription({
    required String ownerId,
    required String ownerType,
    required String plan,
    required double amount,
    required String paymentId,
    String? orderId,
    int durationDays = 30,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));
      
      await _supabase.from('subscriptions').insert({
        'owner_id': ownerId,
        'owner_type': ownerType,
        'plan': plan,
        'amount': amount,
        'payment_id': paymentId,
        'order_id': orderId,
        'status': 'active',
        'start_date': now.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getPartnerStats(String professionalId) async {
    try {
      final data = await _supabase
        .rpc('get_partner_dashboard_stats', params: {'p_professional_id': professionalId});
      
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    } catch (e) {
      _handleError(e);
      return {};
    }
  }
  
  Future<int> getUnreadNotificationCount({required String userId, required String userType}) async {
    try {
      final result = await _supabase.rpc('get_total_unread_count', params: {
        'p_user_id': userId,
        'p_user_type': userType
      });
      return (result as int?) ?? 0;
    } catch (e) {
      _handleError(e);
      return 0;
    }
  }

  // ============================================================
  // SETTINGS
  // ============================================================
  Future<String?> getSetting(String key) async {
    try {
      final data = await _supabase
          .from('settings')
          .select('value')
          .eq('key', key)
          .eq('is_public', true)
          .maybeSingle();
      return data?['value'] as String?;
    } catch (e) {
      debugPrint('Error getting setting $key: $e');
      return null;
    }
  }

  // ============================================================
  // EVENTS TRACKING
  // ============================================================
  Future<void> trackEvent({
    String? userId,
    required String eventType,
    Map<String, dynamic>? eventData,
    String? sessionId,
  }) async {
    try {
      await _supabase.from('events').insert({
        'user_id': userId,
        'event_type': eventType,
        'event_data': eventData ?? {},
        'session_id': sessionId,
      });
    } catch (e) {
      debugPrint('Error tracking event: $e');
    }
  }
}