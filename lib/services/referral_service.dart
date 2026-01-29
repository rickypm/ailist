import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/referral_model.dart';

class ReferralService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // REFERRAL CODE
  // ============================================================

  /// Get user's referral code
  Future<String?> getUserReferralCode(String odId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('referral_code')
          .eq('id', odId)
          .single();

      return data['referral_code'];
    } catch (e) {
      debugPrint('Error getting referral code: $e');
      return null;
    }
  }

  /// Validate referral code
  Future<Map<String, dynamic>?> validateReferralCode(String code) async {
    try {
      final data = await _supabase
          .from('users')
          .select('id, name, referral_code')
          .eq('referral_code', code. toUpperCase())
          .maybeSingle();

      return data;
    } catch (e) {
      debugPrint('Error validating referral code: $e');
      return null;
    }
  }

  /// Apply referral code during signup
  Future<bool> applyReferralCode({
    required String newUserId,
    required String referralCode,
  }) async {
    try {
      // Get referrer
      final referrer = await validateReferralCode(referralCode);
      if (referrer == null) return false;

      final referrerId = referrer['id'];

      // Don't allow self-referral
      if (referrerId == newUserId) return false;

      // Update new user with referral info
      await _supabase. from('users').update({
        'referred_by_user_id': referrerId,
        'referred_by_code': referralCode. toUpperCase(),
      }).eq('id', newUserId);

      // Create referral record
      await _supabase.from('referrals').insert({
        'referrer_id': referrerId,
        'referee_id': newUserId,
        'referral_code': referralCode.toUpperCase(),
        'status': 'completed',
      });

      // Process rewards
      final referralData = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', referrerId)
          .eq('referee_id', newUserId)
          .single();

      await _supabase.rpc('process_referral_reward', params: {
        'p_referral_id': referralData['id'],
      });

      return true;
    } catch (e) {
      debugPrint('Error applying referral code: $e');
      return false;
    }
  }

  // ============================================================
  // REFERRAL STATS
  // ============================================================

  /// Get user's referral stats
  Future<Map<String, dynamic>> getReferralStats(String odId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select('referral_code, total_referrals, referral_earnings')
          .eq('id', odId)
          .single();

      final pendingCount = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', odId)
          .eq('status', 'pending');

      final rewardedCount = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', odId)
          .eq('status', 'rewarded');

      return {
        'referral_code': userData['referral_code'],
        'total_referrals': userData['total_referrals'] ?? 0,
        'referral_earnings': userData['referral_earnings'] ?? 0,
        'pending_referrals': (pendingCount as List).length,
        'rewarded_referrals': (rewardedCount as List).length,
      };
    } catch (e) {
      debugPrint('Error getting referral stats: $e');
      return {};
    }
  }

  /// Get user's referrals list
  Future<List<ReferralModel>> getUserReferrals(String odId) async {
    try {
      final data = await _supabase
          .from('v_referral_tree')
          .select('*')
          .eq('referrer_id', odId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => ReferralModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user referrals: $e');
      return [];
    }
  }

  // ============================================================
  // COUPONS
  // ============================================================

  /// Redeem coupon code
  Future<Map<String, dynamic>> redeemCoupon({
    required String odId,
    required String couponCode,
  }) async {
    try {
      final result = await _supabase. rpc('redeem_coupon', params: {
        'p_user_id': odId,
        'p_coupon_code':  couponCode. toUpperCase(),
      });

      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('Error redeeming coupon: $e');
      return {
        'success': false,
        'error':  'Failed to redeem coupon',
      };
    }
  }

  /// Validate coupon (without redeeming)
  Future<CouponModel?> validateCoupon(String code) async {
    try {
      final data = await _supabase
          .from('coupons')
          .select('*')
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (data == null) return null;
      
      final coupon = CouponModel.fromJson(data);
      return coupon. isValid ? coupon : null;
    } catch (e) {
      debugPrint('Error validating coupon: $e');
      return null;
    }
  }

  /// Get user's redeemed coupons
  Future<List<Map<String, dynamic>>> getRedeemedCoupons(String odId) async {
    try {
      final data = await _supabase
          .from('coupon_redemptions')
          .select('*, coupons(code, description, coupon_type)')
          .eq('user_id', odId)
          .order('redeemed_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting redeemed coupons: $e');
      return [];
    }
  }

  // ============================================================
  // REWARDS HISTORY
  // ============================================================

  /// Get user's rewards history
  Future<List<RewardHistoryModel>> getRewardsHistory(String odId) async {
    try {
      final data = await _supabase
          .from('rewards_history')
          .select('*')
          .eq('user_id', odId)
          .order('created_at', ascending:  false)
          .limit(50);

      return (data as List)
          .map((json) => RewardHistoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting rewards history: $e');
      return [];
    }
  }

  // ============================================================
  // ADMIN FUNCTIONS
  // ============================================================

  /// Get all referrals (admin)
  Future<List<ReferralModel>> getAllReferrals({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final data = await _supabase
          .from('v_referral_tree')
          .select('*')
          .order('created_at', ascending:  false)
          .range(offset, offset + limit - 1);

      return (data as List).map((json) => ReferralModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all referrals: $e');
      return [];
    }
  }

  /// Get referral leaderboard (admin)
  Future<List<Map<String, dynamic>>> getReferralLeaderboard({int limit = 50}) async {
    try {
      final data = await _supabase
          .from('v_referral_leaderboard')
          .select('*')
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get referral tree for specific user (admin)
  Future<List<ReferralModel>> getUserReferralTree(String odId, {int depth = 3}) async {
    try {
      // Get direct referrals
      final directReferrals = await _supabase
          .from('v_referral_tree')
          .select('*')
          .eq('referrer_id', odId);

      List<ReferralModel> allReferrals = (directReferrals as List)
          .map((json) => ReferralModel.fromJson(json))
          .toList();

      // Get nested referrals (depth levels)
      if (depth > 1) {
        for (final referral in List.from(allReferrals)) {
          final nestedReferrals = await getUserReferralTree(
            referral.refereeId,
            depth: depth - 1,
          );
          allReferrals.addAll(nestedReferrals);
        }
      }

      return allReferrals;
    } catch (e) {
      debugPrint('Error getting referral tree: $e');
      return [];
    }
  }

  /// Create coupon (admin)
  Future<CouponModel? > createCoupon(Map<String, dynamic> data) async {
    try {
      final result = await _supabase
          .from('coupons')
          .insert(data)
          .select()
          .single();

      return CouponModel.fromJson(result);
    } catch (e) {
      debugPrint('Error creating coupon: $e');
      return null;
    }
  }

  /// Update coupon (admin)
  Future<bool> updateCoupon(String couponId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await _supabase. from('coupons').update(data).eq('id', couponId);
      return true;
    } catch (e) {
      debugPrint('Error updating coupon: $e');
      return false;
    }
  }

  /// Get all coupons (admin)
  Future<List<CouponModel>> getAllCoupons() async {
    try {
      final data = await _supabase
          .from('coupons')
          .select('*')
          .order('created_at', ascending: false);

      return (data as List).map((json) => CouponModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all coupons: $e');
      return [];
    }
  }

  /// Get referral settings (admin)
  Future<Map<String, String>> getReferralSettings() async {
    try {
      final data = await _supabase
          .from('referral_settings')
          .select('setting_key, setting_value');

      Map<String, String> settings = {};
      for (final row in data) {
        settings[row['setting_key']] = row['setting_value'];
      }
      return settings;
    } catch (e) {
      debugPrint('Error getting referral settings:  $e');
      return {};
    }
  }

  /// Update referral setting (admin)
  Future<bool> updateReferralSetting(String key, String value) async {
    try {
      await _supabase
          .from('referral_settings')
          .update({
            'setting_value': value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('setting_key', key);
      return true;
    } catch (e) {
      debugPrint('Error updating referral setting:  $e');
      return false;
    }
  }
}