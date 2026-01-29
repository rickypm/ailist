import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/app_config.dart';
import 'payment_service.dart';

class SubscriptionService {
  final _supabase = Supabase.instance.client;
  final _paymentService = PaymentService();
  
  // Callbacks for UI
  Function(String plan, int unlocks)? onSubscriptionSuccess;
  Function(String error)? onSubscriptionFailure;

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  void initialize({
    required Function(String plan, int unlocks) onSuccess,
    required Function(String error) onFailure,
  }) {
    onSubscriptionSuccess = onSuccess;
    onSubscriptionFailure = onFailure;

    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
    );
  }

  void dispose() {
    _paymentService.dispose();
  }

  // ============================================================
  // GET PLANS
  // ============================================================
  
  /// Get all available subscription plans
  Future<List<SubscriptionPlan>> getPlans({required String planType}) async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select()
          .eq('plan_type', planType)
          .eq('is_active', true)
          .order('display_order');

      return (response as List)
          .map((json) => SubscriptionPlan. fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Get Plans Error: $e');
      return _getDefaultPlans(planType);
    }
  }

  List<SubscriptionPlan> _getDefaultPlans(String planType) {
    if (planType == 'user') {
      return [
        SubscriptionPlan(
          id: 'user_free',
          planId: 'free',
          name: 'Free',
          description: 'Basic access',
          planType: 'user',
          price: 0,
          unlocks: 0,
          features: ['Browse services', 'AI chat search', 'View limited details'],
        ),
        SubscriptionPlan(
          id: 'user_basic',
          planId:  'basic',
          name:  'Basic',
          description:  '3 unlocks per month',
          planType: 'user',
          price: 99,
          unlocks: 3,
          features: ['3 contact unlocks', 'Full profiles', 'Direct messaging'],
          isPopular: false,
        ),
        SubscriptionPlan(
          id:  'user_plus',
          planId: 'plus',
          name: 'Plus',
          description: '8 unlocks per month',
          planType:  'user',
          price:  199,
          unlocks: 8,
          features: ['8 contact unlocks', 'Priority support', 'All Basic features'],
          isPopular:  true,
        ),
        SubscriptionPlan(
          id:  'user_pro',
          planId: 'pro',
          name: 'Pro',
          description: '15 unlocks per month',
          planType:  'user',
          price:  499,
          unlocks: 15,
          features: ['15 contact unlocks', 'Exclusive deals', 'All Plus features'],
        ),
      ];
    } else {
      return [
        SubscriptionPlan(
          id:  'partner_free',
          planId: 'free',
          name: 'Free',
          description: 'Basic listing',
          planType: 'partner',
          price: 0,
          unlocks: 0,
          features: ['Basic profile', 'Limited visibility', 'View messages'],
        ),
        SubscriptionPlan(
          id:  'partner_starter',
          planId: 'starter',
          name: 'Starter',
          description: 'Read & reply to messages',
          planType: 'partner',
          price: 199,
          unlocks: 0,
          features: ['Reply to messages', 'Analytics dashboard', 'Priority listing'],
        ),
        SubscriptionPlan(
          id:  'partner_business',
          planId: 'business',
          name: 'Business',
          description: 'Full featured profile',
          planType: 'partner',
          price: 499,
          unlocks: 0,
          features: ['Verified badge', 'Top search placement', 'Unlimited services', 'All Starter features'],
          isPopular: true,
        ),
      ];
    }
  }

  // ============================================================
  // GET CURRENT SUBSCRIPTION
  // ============================================================
  
  /// Get user's current subscription
  Future<UserSubscription? > getCurrentSubscription(String userId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('owner_id', userId)
          .eq('status', 'active')
          .gte('end_date', DateTime.now().toIso8601String())
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return UserSubscription.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Get Current Subscription Error: $e');
      return null;
    }
  }

  // ============================================================
  // SUBSCRIBE TO PLAN
  // ============================================================
  
  /// Start subscription process via Edge Function (secure)
  Future<bool> subscribeToPlan({
    required SubscriptionPlan plan,
    required String userEmail,
    required String userName,
    String? userPhone,
  }) async {
    if (plan.price == 0) {
      // Free plan - just update directly
      return await _activateFreePlan(plan);
    }

    // Paid plan - use PaymentService (which calls Edge Functions)
    return await _paymentService.startPayment(
      planId: plan.planId,
      planType: plan.planType,
      amountInRupees: plan.price,
      planName: plan.name,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
    );
  }

  Future<bool> _activateFreePlan(SubscriptionPlan plan) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase. from('users').update({
        'subscription_plan':  plan.planId,
        'unlocks_remaining': plan.unlocks,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      onSubscriptionSuccess?.call(plan. planId, plan.unlocks);
      return true;
    } catch (e) {
      debugPrint('Activate Free Plan Error: $e');
      onSubscriptionFailure?.call(e.toString());
      return false;
    }
  }

  // ============================================================
  // PAYMENT CALLBACKS
  // ============================================================
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Subscription Payment Success: ${response.paymentId}');
    
    // Fetch updated user data to get new plan
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final userData = await _supabase
            .from('users')
            .select('subscription_plan, unlocks_remaining')
            .eq('id', userId)
            .single();

        onSubscriptionSuccess?.call(
          userData['subscription_plan'] ?? 'free',
          userData['unlocks_remaining'] ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Fetch Updated User Error: $e');
      onSubscriptionSuccess?.call('unknown', 0);
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    debugPrint('Subscription Payment Failed: ${response.message}');
    onSubscriptionFailure?.call(response.message ??  'Payment failed');
  }

  // ============================================================
  // CANCEL SUBSCRIPTION
  // ============================================================
  
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _supabase. from('subscriptions').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'auto_renew': false,
      }).eq('id', subscriptionId);

      return true;
    } catch (e) {
      debugPrint('Cancel Subscription Error: $e');
      return false;
    }
  }
}

// ============================================================
// MODELS
// ============================================================

class SubscriptionPlan {
  final String id;
  final String planId;
  final String name;
  final String description;
  final String planType;
  final int price;
  final int unlocks;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.planId,
    required this.name,
    required this.description,
    required this.planType,
    required this.price,
    required this. unlocks,
    required this. features,
    this.isPopular = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ??  '',
      planId: json['plan_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      planType: json['plan_type'] ?? 'user',
      price: (json['price'] ?? 0).toInt(),
      unlocks: json['unlocks_included'] ?? 0,
      features: json['features'] != null
          ?  List<String>.from(json['features'])
          : [],
      isPopular: json['is_popular'] ?? false,
    );
  }

  String get priceDisplay => price == 0 ? 'Free' : '₹$price/mo';
  bool get isFree => price == 0;
}

class UserSubscription {
  final String id;
  final String ownerId;
  final String plan;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;

  UserSubscription({
    required this.id,
    required this.ownerId,
    required this.plan,
    required this.status,
    required this. startDate,
    required this. endDate,
    required this. autoRenew,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'active',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      autoRenew: json['auto_renew'] ?? true,
    );
  }

  bool get isActive => status == 'active' && endDate. isAfter(DateTime.now());
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}