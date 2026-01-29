import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AIService {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // SEND MESSAGE TO AI (Via Edge Function)
  // ============================================================
  
  Future<AIResponse> sendMessage({
    required String message,
    String? city,
    List<ChatMessage>? history,
    bool skipAI = false,
  }) async {
    try {
      final userCity = city ?? AppConfig.defaultCity;
      final userId = _supabase.auth.currentUser?.id;
      
      debugPrint('===========================================');
      debugPrint('AI: User message: $message');
      debugPrint('AI: City: $userCity');
      debugPrint('AI: User ID: $userId');
      debugPrint('===========================================');

      // Prepare history for API (only role and content)
      List<Map<String, String>>? historyData;
      if (history != null && history.isNotEmpty) {
        historyData = history.map((h) => {
          'role': h.role,
          'content': h.content,
        }).toList();
      }

      // Build request body - ensure all values are properly typed
      final Map<String, dynamic> body = {
        'message': message,
        'city': userCity,
      };
      
      // Only add userId if not null
      if (userId != null) {
        body['userId'] = userId;
      }
      
      // Only add history if not null/empty
      if (historyData != null && historyData.isNotEmpty) {
        body['history'] = historyData;
      }

      debugPrint('AI: Request body: ${jsonEncode(body)}');

      // Build headers
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
      };
      
      // Add auth header if user is logged in
      final accessToken = _supabase.auth.currentSession?.accessToken;
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      debugPrint('AI: Calling endpoint: ${AppConfig.aiChatEndpoint}');

      // Call Edge Function
      final response = await http.post(
        Uri.parse(AppConfig.aiChatEndpoint),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('AI: Request timeout');
          throw Exception('Request timeout');
        },
      );

      debugPrint('AI: Response status: ${response.statusCode}');
      debugPrint('AI: Response body: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('AI: Error response: ${response.body}');
        
        // Try to parse error message
        String errorMsg = 'Sorry, I encountered an error. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMsg = errorData['error'].toString();
          } else if (errorData['message'] != null) {
            errorMsg = errorData['message'].toString();
          }
        } catch (_) {}
        
        return AIResponse(
          success: false,
          message: errorMsg,
          error: 'Status ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      debugPrint('AI: Response success: ${data['success']}');
      debugPrint('AI: Is paid: ${data['isPaid']}');

      // Parse matched professionals safely
      List<String>? matchedProfessionals;
      if (data['matchedProfessionals'] != null) {
        matchedProfessionals = (data['matchedProfessionals'] as List)
            .map((e) => e.toString())
            .toList();
      }

      return AIResponse(
        success: data['success'] ?? false,
        message: data['message'] ?? 'No response',
        searchIntent: data['searchIntent'] != null 
            ? SearchIntent.fromJson(Map<String, dynamic>.from(data['searchIntent'])) 
            : null,
        matchedProfessionals: matchedProfessionals,
        limitReached: data['limitReached'] ?? false,
        remaining: data['remaining'] ?? -1,
        isPaid: data['isPaid'] ?? false,
        error: data['error']?.toString(),
      );
    } catch (e) {
      debugPrint('AI Service Exception: $e');
      return AIResponse(
        success: false,
        message: 'Sorry, I encountered an error. Please try again.',
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // CHECK USAGE STATUS
  // ============================================================
  
  Future<AIUsageStatus> checkUsageStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    
    if (userId == null) {
      return AIUsageStatus(
        canUse: true,
        remaining: AppConfig.freeUserAIDailyLimit,
        limit: AppConfig.freeUserAIDailyLimit,
        isPaid: false,
      );
    }
    
    try {
      // Check user's subscription plan
      final response = await _supabase
          .from('users')
          .select('subscription_plan')
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) {
        return AIUsageStatus(
          canUse: true,
          remaining: AppConfig.freeUserAIDailyLimit,
          limit: AppConfig.freeUserAIDailyLimit,
          isPaid: false,
        );
      }
      
      final plan = response['subscription_plan'] as String? ?? 'free';
      final isPaid = AppConfig.unlimitedAIPlans.contains(plan);
      
      if (isPaid) {
        return AIUsageStatus(
          canUse: true,
          remaining: -1,
          limit: -1,
          isPaid: true,
        );
      }
      
      // Check today's usage for free users
      final today = DateTime.now().toIso8601String().split('T')[0];
      final usageResponse = await _supabase
          .from('ai_usage')
          .select('request_count')
          .eq('user_id', userId)
          .eq('usage_date', today)
          .maybeSingle();
      
      final todayUsage = (usageResponse?['request_count'] ?? 0) as int;
      final remaining = AppConfig.freeUserAIDailyLimit - todayUsage;
      
      return AIUsageStatus(
        canUse: remaining > 0,
        remaining: remaining > 0 ? remaining : 0,
        limit: AppConfig.freeUserAIDailyLimit,
        isPaid: false,
      );
    } catch (e) {
      debugPrint('AI: Error checking usage status: $e');
      return AIUsageStatus(
        canUse: true,
        remaining: AppConfig.freeUserAIDailyLimit,
        limit: AppConfig.freeUserAIDailyLimit,
        isPaid: false,
      );
    }
  }

  // ============================================================
  // GET USAGE STATS
  // ============================================================
  
  Future<AIUsageStats?> getUsageStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    
    try {
      final result = await _supabase.rpc('get_ai_usage_stats', params: {
        'p_user_id': userId,
      });
      
      if (result is Map) {
        return AIUsageStats(
          today: (result['today'] ?? 0) as int,
          thisWeek: (result['thisWeek'] ?? 0) as int,
          thisMonth: (result['thisMonth'] ?? 0) as int,
          total: (result['total'] ?? 0) as int,
        );
      }
      
      return AIUsageStats(today: 0, thisWeek: 0, thisMonth: 0, total: 0);
    } catch (e) {
      debugPrint('AI: Error getting usage stats: $e');
      return AIUsageStats(today: 0, thisWeek: 0, thisMonth: 0, total: 0);
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  SearchIntent? extractLocalIntent(String message) {
    final lowerMessage = message.toLowerCase();
    
    final categoryKeywords = {
      'electrician': ['electrician', 'electric', 'wiring', 'power', 'light', 'fan', 'switch', 'electrical'],
      'plumber': ['plumber', 'plumbing', 'pipe', 'water', 'tap', 'leak', 'drain', 'toilet'],
      'carpenter': ['carpenter', 'carpentry', 'furniture', 'wood', 'cabinet', 'door', 'table', 'wardrobe'],
      'painter': ['painter', 'painting', 'paint', 'wall', 'color', 'whitewash'],
      'ac-repair': ['ac', 'air conditioner', 'cooling', 'hvac', 'split ac', 'window ac'],
      'cleaning': ['cleaning', 'cleaner', 'housekeeping', 'maid', 'deep clean'],
      'tutoring': ['tutor', 'teacher', 'teaching', 'coaching', 'tuition'],
      'mechanic': ['mechanic', 'car', 'bike', 'vehicle', 'garage'],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          return SearchIntent(
            category: entry.key,
            query: message,
            confidence: 0.9,
          );
        }
      }
    }

    return null;
  }

  String generateFallbackResponse(String message, SearchIntent? intent) {
    if (intent != null) {
      return "I can help you find a ${intent.category?.replaceAll('-', ' ')}. Let me search...";
    }
    return "I'm here to help you find local services. What are you looking for?";
  }

  String generateLimitReachedMessage(int limit) {
    return "🔒 You've reached your daily limit of $limit AI chat requests.\n\n"
           "Upgrade to Premium for unlimited AI-powered search!";
  }
}

// ============================================================
// MODELS
// ============================================================

class AIResponse {
  final bool success;
  final String message;
  final SearchIntent? searchIntent;
  final List<String>? matchedProfessionals;
  final String? error;
  final bool limitReached;
  final int remaining;
  final bool isPaid;

  AIResponse({
    required this.success,
    required this.message,
    this.searchIntent,
    this.matchedProfessionals,
    this.error,
    this.limitReached = false,
    this.remaining = -1,
    this.isPaid = false,
  });

  bool get hasSearchIntent => searchIntent != null && searchIntent!.category != null;
  bool get hasError => error != null && error!.isNotEmpty;
  bool get isUnlimited => remaining == -1;
}

class SearchIntent {
  final String? category;
  final String? query;
  final double? confidence;

  SearchIntent({this.category, this.query, this.confidence});

  factory SearchIntent.fromJson(Map<String, dynamic> json) {
    return SearchIntent(
      category: json['category']?.toString(),
      query: json['query']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'category': category, 'query': query, 'confidence': confidence};
  }
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class AIUsageStatus {
  final bool canUse;
  final int remaining;
  final int limit;
  final bool isPaid;
  final String? error;

  AIUsageStatus({
    required this.canUse,
    required this.remaining,
    required this.limit,
    required this.isPaid,
    this.error,
  });

  bool get isUnlimited => remaining == -1 || isPaid;
  bool get isLimitReached => !canUse && !isPaid;
}

class AIUsageStats {
  final int today;
  final int thisWeek;
  final int thisMonth;
  final int total;

  AIUsageStats({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.total,
  });
}