import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/professional_model.dart';
import '../models/shop_model.dart';
import '../models/item_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';

class DataProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();
  final AIService _aiService = AIService();

  // ============================================================
  // STATE
  // ============================================================
  
  // User & Auth
  UserModel? _currentUser;
  ProfessionalModel? _currentProfessional;
  
  // Data Lists
  List<CategoryModel> _categories = [];
  List<ProfessionalModel> _professionals = [];
  List<ProfessionalModel> _unlockedProfessionals = [];
  List<ProfessionalModel> _savedProfessionals = [];
  List<ShopModel> _shops = [];
  List<ItemModel> _items = [];
  List<ItemModel> _featuredItems = [];
  
  // Messaging
  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  int _unreadCount = 0;
  
  // Partner Specific
  ShopModel? _myShop;
  List<ItemModel> _myItems = [];
  Map<String, dynamic> _partnerStats = {};

  // UI State
  bool _isLoading = false;
  String? _error;
  
  // AI Chat State
  List<ChatMessage> _chatMessages = [];
  bool _aiTyping = false;
  List<ProfessionalModel> _aiMatchedProfessionals = [];
  
  // Loading states
  bool _conversationsLoading = false;
  bool _shopLoading = false;
  bool _itemsLoading = false;
  bool _professionalsLoading = false;
  bool _partnerStatsLoading = false;

  // Realtime subscriptions
  StreamSubscription? _messagesSubscription;

  // ============================================================
  // GETTERS
  // ============================================================
  
  UserModel? get currentUser => _currentUser;
  ProfessionalModel? get currentProfessional => _currentProfessional;
  ProfessionalModel? get selectedProfessional => _currentProfessional;
  
  List<CategoryModel> get categories => _categories;
  List<ProfessionalModel> get professionals => _professionals;
  List<ProfessionalModel> get unlockedProfessionals => _unlockedProfessionals;
  List<ProfessionalModel> get savedProfessionals => _savedProfessionals;
  List<ShopModel> get shops => _shops;
  List<ItemModel> get items => _items;
  List<ItemModel> get featuredItems => _featuredItems;
  
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  int get unreadCount => _unreadCount;
  
  ShopModel? get myShop => _myShop;
  ShopModel? get shop => _myShop;
  
  List<ItemModel> get myItems => _myItems;
  List<ItemModel> get shopItems => _myItems;
  
  Map<String, dynamic> get partnerStats => _partnerStats;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<ChatMessage> get chatMessages => _chatMessages;
  bool get aiTyping => _aiTyping;
  List<ProfessionalModel> get aiMatchedProfessionals => _aiMatchedProfessionals;
  
  bool get conversationsLoading => _conversationsLoading;
  bool get shopLoading => _shopLoading;
  bool get itemsLoading => _itemsLoading;
  bool get professionalsLoading => _professionalsLoading;
  bool get partnerStatsLoading => _partnerStatsLoading;

  // ============================================================
  // INITIALIZATION & USER
  // ============================================================

  // NEW CODE - REPLACE lines 111-129 with this:
Future<void> initUser(String userId) async {
  _setLoading(true);
  try {
    debugPrint('========== INIT USER ==========');
    debugPrint('Loading user with ID: $userId');
    
    _currentUser = await _db.getUser(userId);
    debugPrint('✅ User loaded: ${_currentUser?.email}');
    
    // ✅ FIX: ALWAYS try to load professional (remove role check)
    debugPrint('Attempting to load professional profile...');
    try {
      _currentProfessional = await _db.getProfessionalByUserId(userId);
      if (_currentProfessional != null) {
        debugPrint('✅ Professional loaded: ${_currentProfessional!.displayName}');
        debugPrint('✅ Professional ID: ${_currentProfessional!.id}');
        await loadMyShop(_currentProfessional!.id);
        await loadPartnerStats(_currentProfessional!.id);
      } else {
        debugPrint('ℹ️ No professional profile found');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading professional: $e');
    }
    
    await loadUnlockedProfessionals(userId);
    debugPrint('========== INIT COMPLETE ==========');
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    debugPrint('❌ Error in initUser: $e');
  } finally {
    _setLoading(false);
  }
}

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    try {
      _currentUser = await _db.getUser(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      final success = await _db.updateUser(_currentUser!.id, data);
      if (success) {
        _currentUser = await _db.getUser(_currentUser!.id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfessionalProfile(Map<String, dynamic> data) async {
    if (_currentProfessional == null) return false;
    _setLoading(true);
    try {
      final success = await _db.updateProfessional(_currentProfessional!.id, data);
      if (success) {
        _currentProfessional = await _db.getProfessionalById(_currentProfessional!.id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProfessionalByUserId(String userId) async {
    _setLoading(true);
    try {
      _currentProfessional = await _db.getProfessionalByUserId(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Future<void> loadCategories() async {
    try {
      _categories = await _db.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Provider Error loading categories: $e');
    }
  }

  // ============================================================
  // PROFESSIONALS
  // ============================================================

  Future<ProfessionalModel?> getProfessionalById(String id) async {
    try {
      return await _db.getProfessionalById(id);
    } catch (e) {
      debugPrint('Error getting professional: $e');
      return null;
    }
  }

  Future<void> loadProfessionalsByCategory(String categoryId) async {
    _professionalsLoading = true;
    _setLoading(true);
    try {
      _professionals = await _db.getProfessionalsByCategory(categoryId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _professionalsLoading = false;
      _setLoading(false);
    }
  }

  Future<void> searchProfessionals(String query, {String? city}) async {
    _professionalsLoading = true;
    _setLoading(true);
    try {
      _professionals = await _db.searchProfessionals(query, city: city);
    } catch (e) {
      _error = e.toString();
    } finally {
      _professionalsLoading = false;
      _setLoading(false);
    }
  }

  Future<void> loadUnlockedProfessionals(String userId) async {
    try {
      _unlockedProfessionals = await _db.getUnlockedProfessionals(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Provider Error loading unlocked: $e');
    }
  }

  Future<void> incrementProfileViews(String professionalId) async {
    await _db.incrementProfileViews(professionalId);
  }

  // ============================================================
  // UNLOCKS
  // ============================================================

  Future<bool> unlockProfessional(String userId, String professionalId) async {
    try {
      final success = await _db.unlockProfessional(userId, professionalId);
      if (success) {
        await loadUnlockedProfessionals(userId);
        _currentUser = await _db.getUser(userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> isProfessionalUnlocked(String professionalId) async {
    if (_currentUser == null) return false;
    
    if (_currentUser!.subscriptionPlan == 'plus' || 
        _currentUser!.subscriptionPlan == 'pro') {
      return true;
    }
    
    if (_unlockedProfessionals.any((p) => p.id == professionalId)) return true;
    
    return await _db.checkUnlockStatus(_currentUser!.id, professionalId);
  }

  Future<List<Map<String, dynamic>>> getUserUnlocks(String userId) async {
    try {
      final response = await _db.getUserUnlocks(userId);
      return response;
    } catch (e) {
      debugPrint('Error getting user unlocks: $e');
      return [];
    }
  }

  // ============================================================
  // SHOPS
  // ============================================================

  Future<void> loadMyShop(String professionalId) async {
    _shopLoading = true;
    notifyListeners();
    try {
      _myShop = await _db.getShopByProfessionalId(professionalId);
      if (_myShop != null) {
        await loadMyItems(_myShop!.id);
      }
    } catch (e) {
      debugPrint('Provider Error loading my shop: $e');
    } finally {
      _shopLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPartnerShop(String professionalId) async {
    await loadMyShop(professionalId);
  }

  Future<void> searchShops(String query, {String? city}) async {
    _setLoading(true);
    try {
      _shops = await _db.searchShops(query, city: city);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createShop(Map<String, dynamic> data, File? logoFile, File? coverFile) async {
    _setLoading(true);
    try {
      if (logoFile != null) {
        final url = await _storage.uploadImage(logoFile, 'shops/logos');
        data['logo_url'] = url;
      }
      if (coverFile != null) {
        final url = await _storage.uploadImage(coverFile, 'shops/covers');
        data['cover_url'] = url;
      }

      final shop = await _db.createShop(data);
      if (shop != null) {
        _myShop = shop;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateShop(Map<String, dynamic> data, File? logoFile, File? coverFile) async {
    if (_myShop == null) return false;
    _setLoading(true);
    try {
      if (logoFile != null) {
        final url = await _storage.uploadImage(logoFile, 'shops/logos');
        data['logo_url'] = url;
      }
      if (coverFile != null) {
        final url = await _storage.uploadImage(coverFile, 'shops/covers');
        data['cover_url'] = url;
      }

      final success = await _db.updateShop(_myShop!.id, data);
      if (success) {
        if (_currentProfessional != null) {
          _myShop = await _db.getShopByProfessionalId(_currentProfessional!.id);
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ITEMS
  // ============================================================

  Future<void> loadMyItems(String shopId) async {
    _itemsLoading = true;
    notifyListeners();
    try {
      _myItems = await _db.getItemsByShop(shopId);
    } catch (e) {
      debugPrint('Provider Error loading items: $e');
    } finally {
      _itemsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadShopItems(String shopId) async {
    await loadMyItems(shopId);
  }

  Future<void> loadFeaturedItems({String? city}) async {
    try {
      final rawItems = await _db.getFeaturedItems(city: city);
      _featuredItems = rawItems.map((e) => ItemModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Provider Error loading featured items: $e');
    }
  }

  Future<void> searchItems(String query, {String? city}) async {
    _setLoading(true);
    try {
      _items = await _db.searchItems(query, city: city);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createItem(Map<String, dynamic> data, List<File> images) async {
    if (_myShop == null) return false;
    _setLoading(true);
    try {
      List<String> imageUrls = [];
      for (var image in images) {
        final url = await _storage.uploadImage(image, 'items/${_myShop!.id}');
        if (url != null) imageUrls.add(url);
      }
      
      data['shop_id'] = _myShop!.id;
      data['images'] = imageUrls;
      
      final item = await _db.createItem(data);
      if (item != null) {
        _myItems.add(item);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<ItemModel?> createItemWithTags(String professionalId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final item = await _db.createItem(data);
      if (item != null) {
        _myItems.add(item);
        notifyListeners();
      }
      return item;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateItem(String itemId, Map<String, dynamic> data, List<File> newImages) async {
    _setLoading(true);
    try {
      List<String> imageUrls = List<String>.from(data['images'] ?? []);
      
      for (var image in newImages) {
        final url = await _storage.uploadImage(image, 'items/${_myShop!.id}');
        if (url != null) imageUrls.add(url);
      }
      data['images'] = imageUrls;

      final success = await _db.updateItem(itemId, data);
      if (success) {
        if (_myShop != null) {
          await loadMyItems(_myShop!.id);
        }
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateItemWithTags(String itemId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final success = await _db.updateItem(itemId, data);
      if (success && _myShop != null) {
        await loadMyItems(_myShop!.id);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      final success = await _db.deleteItem(itemId);
      if (success) {
        _myItems.removeWhere((item) => item.id == itemId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ============================================================
  // MESSAGING
  // ============================================================

  Future<void> loadConversations(String userId, {bool isPartner = false}) async {
    _conversationsLoading = true;
    _setLoading(true);
    try {
      _conversations = await _db.getConversations(userId, isPartner: isPartner);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _conversationsLoading = false;
      _setLoading(false);
    }
  }

  Future<ConversationModel?> startConversation(String userId, String professionalId) async {
    try {
      final conversation = await _db.getOrCreateConversation(userId, professionalId);
      if (conversation != null) {
        if (!_conversations.any((c) => c.id == conversation.id)) {
          _conversations.insert(0, conversation);
          notifyListeners();
        }
      }
      return conversation;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<ConversationModel?> getOrCreateConversation(String userId, String professionalId) async {
    return startConversation(userId, professionalId);
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      _messages = await _db.getMessages(conversationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Provider Error loading messages: $e');
    }
  }

  void subscribeToMessages(String conversationId) {
    _messagesSubscription?.cancel();
    debugPrint('Subscribed to messages for conversation: $conversationId');
  }

  Future<void> markMessagesAsRead(String conversationId, String odType) async {
    try {
      await _db.markMessagesAsRead(conversationId, odType);
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderType,
    required String content,
  }) async {
    try {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final tempMessage = MessageModel(
        id: tempId,
        conversationId: conversationId,
        senderId: senderId,
        senderType: senderType,
        content: content,
        createdAt: DateTime.now(),
        isRead: false,
      );
      
      _messages.add(tempMessage);
      notifyListeners();

      await _db.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        senderType: senderType,
        content: content,
      );
      
      return true;
    } catch (e) {
      _messages.removeLast();
      notifyListeners();
      _error = e.toString();
      return false;
    }
  }

  // ============================================================
  // AI CHAT - ✅ FIXED
  // ============================================================

  Future<void> sendAIMessage({
    required String message,
    String? userId,
    String? city,
  }) async {
    // Add user message
    _chatMessages.add(ChatMessage(
      role: 'user',
      content: message,
    ));
    _aiTyping = true;
    _aiMatchedProfessionals = []; // Clear previous matches
    notifyListeners();

    try {
      final response = await _aiService.sendMessage(
        message: message,
        city: city,
        history: _chatMessages,
      );

      debugPrint('🔍 AI Response success: ${response.success}');
      debugPrint('🔍 AI Matched IDs: ${response.matchedProfessionals}');

      if (response.success) {
        // Add assistant message
        _chatMessages.add(ChatMessage(
          role: 'assistant',
          content: response.message,
        ));

        // ✅ FIX: Load matched professionals BEFORE setting aiTyping to false
        if (response.matchedProfessionals != null && response.matchedProfessionals!.isNotEmpty) {
          debugPrint('🔍 Loading ${response.matchedProfessionals!.length} matched professionals...');
          await _loadMatchedProfessionals(response.matchedProfessionals!);
          debugPrint('🔍 Loaded professionals: ${_aiMatchedProfessionals.length}');
        } else {
          debugPrint('🔍 No matched professionals in response');
        }
      } else {
        _chatMessages.add(ChatMessage(
          role: 'assistant',
          content: response.error ?? 'Sorry, I encountered an error. Please try again.',
        ));
      }
    } catch (e) {
      debugPrint('🔍 AI Error: $e');
      _chatMessages.add(ChatMessage(
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
      ));
    } finally {
      _aiTyping = false;
      // ✅ FIX: Notify listeners AFTER professionals are loaded
      notifyListeners();
    }
  }

  Future<void> _loadMatchedProfessionals(List<String> ids) async {
    try {
      debugPrint('🔍 _loadMatchedProfessionals called with IDs: $ids');
      final List<ProfessionalModel> matched = [];
      
      for (final id in ids) {
        debugPrint('🔍 Fetching professional with ID: $id');
        final professional = await _db.getProfessionalById(id);
        if (professional != null) {
          debugPrint('🔍 Found: ${professional.displayName}');
          matched.add(professional);
        } else {
          debugPrint('🔍 Professional not found for ID: $id');
        }
      }
      
      _aiMatchedProfessionals = matched;
      debugPrint('🔍 Total matched professionals loaded: ${matched.length}');
      
      // ✅ FIX: Notify listeners after loading professionals
      notifyListeners();
    } catch (e) {
      debugPrint('🔍 Error loading matched professionals: $e');
    }
  }

  void clearChat() {
    _chatMessages.clear();
    _aiMatchedProfessionals = [];
    notifyListeners();
  }

  // ============================================================
  // SUBSCRIPTIONS & STATS
  // ============================================================

  Future<bool> subscribe({
    required String userId,
    required String userType,
    required String plan,
    required double amount,
    required String paymentId,
    String? orderId,
  }) async {
    _setLoading(true);
    try {
      final success = await _db.createSubscription(
        ownerId: userId,
        ownerType: userType,
        plan: plan,
        amount: amount,
        paymentId: paymentId,
        orderId: orderId,
      );
      
      if (success) {
        if (userType == 'user') {
          await initUser(userId);
        } else {
          if (_currentProfessional != null) {
             _currentProfessional = await _db.getProfessionalById(_currentProfessional!.id);
             notifyListeners();
          }
        }
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createSubscription({
    required String ownerId,
    required String ownerType,
    required String plan,
    required double amount,
    required String paymentId,
    String? orderId,
  }) async {
    return subscribe(
      userId: ownerId,
      userType: ownerType,
      plan: plan,
      amount: amount,
      paymentId: paymentId,
      orderId: orderId,
    );
  }

  Future<void> loadPartnerStats(String professionalId) async {
    _partnerStatsLoading = true;
    notifyListeners();
    try {
      _partnerStats = await _db.getPartnerStats(professionalId);
    } catch (e) {
      debugPrint('Provider Error loading stats: $e');
    } finally {
      _partnerStatsLoading = false;
      notifyListeners();
    }
  }

  Future<int> getUnreadCount(String userId, String userType) async {
    try {
      final count = await _db.getUnreadNotificationCount(userId: userId, userType: userType);
      _unreadCount = count;
      notifyListeners();
      return count;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================
  // STORAGE HELPERS
  // ============================================================

  Future<String?> uploadImage(File file, String path) async {
    return await _storage.uploadImage(file, path);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _currentUser = null;
    _currentProfessional = null;
    _categories = [];
    _professionals = [];
    _unlockedProfessionals = [];
    _shops = [];
    _items = [];
    _conversations = [];
    _messages = [];
    _myShop = null;
    _myItems = [];
    _chatMessages = [];
    _aiMatchedProfessionals = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}