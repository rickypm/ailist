import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/referral_service.dart';
import '../../models/referral_model.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _referralService = ReferralService();
  final _couponController = TextEditingController();

  Map<String, dynamic> _stats = {};
  List<ReferralModel> _referrals = [];
  List<RewardHistoryModel> _rewards = [];
  bool _isLoading = true;
  bool _isRedeemingCoupon = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    setState(() => _isLoading = true);

    final odId = authProvider.user!. id;

    final results = await Future.wait([
      _referralService.getReferralStats(odId),
      _referralService.getUserReferrals(odId),
      _referralService.getRewardsHistory(odId),
    ]);

    setState(() {
      _stats = results[0] as Map<String, dynamic>;
      _referrals = results[1] as List<ReferralModel>;
      _rewards = results[2] as List<RewardHistoryModel>;
      _isLoading = false;
    });
  }

  void _copyReferralCode() {
    final code = _stats['referral_code'] ?? '';
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied! '),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareReferralCode() {
    final code = _stats['referral_code'] ?? '';
    final message = '''
🎉 Join ${AppConfig.appName} and get FREE unlocks! 

Use my referral code: $code

Download now and find the best local services near you!
''';
    Share.share(message);
  }

  Future<void> _redeemCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger. of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coupon code'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider. user == null) return;

    setState(() => _isRedeemingCoupon = true);

    final result = await _referralService.redeemCoupon(
      odId: authProvider.user! .id,
      couponCode: code,
    );

    setState(() => _isRedeemingCoupon = false);

    if (result['success'] == true) {
      _couponController.clear();
      await authProvider.refreshUser();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Coupon redeemed! '),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to redeem coupon'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Referrals & Rewards', style: AppTextStyles.h3),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Referral Code Card
                    _buildReferralCodeCard(),
                    const SizedBox(height: 24),

                    // Stats
                    _buildStatsRow(),
                    const SizedBox(height: 24),

                    // Coupon Redemption
                    _buildCouponSection(),
                    const SizedBox(height: 24),

                    // How It Works
                    _buildHowItWorks(),
                    const SizedBox(height: 24),

                    // Referrals List
                    if (_referrals.isNotEmpty) ...[
                      Text('Your Referrals', style:  AppTextStyles.h3),
                      const SizedBox(height: 12),
                      _buildReferralsList(),
                      const SizedBox(height: 24),
                    ],

                    // Rewards History
                    if (_rewards.isNotEmpty) ...[
                      Text('Rewards History', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      _buildRewardsHistory(),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReferralCodeCard() {
    final code = _stats['referral_code'] ?? '--------';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.inputBorderGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Iconsax.gift,
            color: AppColors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Share & Earn',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height:  8),
          Text(
            'Invite friends and earn free unlocks!',
            style:  TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Code Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    color:  AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _copyReferralCode,
                  child:  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:  AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.copy,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Share Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareReferralCode,
              icon: const Icon(Iconsax.share, size: 20),
              label:  const Text('Share with Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.people,
            value: '${_stats['total_referrals'] ?? 0}',
            label: 'Total Referrals',
          ),
        ),
        const SizedBox(width:  12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax. unlock,
            value: '${(_stats['referral_earnings'] ?? 0).toInt()}',
            label: 'Unlocks Earned',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding:  const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.ticket_discount, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Text('Have a Coupon?', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width:  12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isRedeemingCoupon ?  null : _redeemCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isRedeemingCoupon
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How It Works', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          _buildStep(1, 'Share your referral code with friends'),
          _buildStep(2, 'They sign up using your code'),
          _buildStep(3, 'You both get FREE unlocks!  🎉'),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:  Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _referrals.length,
      itemBuilder: (context, index) {
        final referral = _referrals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    referral.refereeName?.isNotEmpty == true
                        ? referral.refereeName![0]. toUpperCase()
                        :  '?',
                    style:  const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:  CrossAxisAlignment.start,
                  children: [
                    Text(
                      referral.refereeName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(referral.createdAt),
                      style:  TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: referral.isRewarded
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius:  BorderRadius.circular(20),
                ),
                child:  Text(
                  referral.isRewarded ? '+${referral.referrerRewardAmount. toInt()}' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: referral. isRewarded ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardsHistory() {
    return ListView.builder(
      shrinkWrap: true,
      physics:  const NeverScrollableScrollPhysics(),
      itemCount: _rewards.take(10).length,
      itemBuilder: (context, index) {
        final reward = _rewards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:  Icon(
                  _getRewardIcon(reward.rewardType),
                  color:  AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.description ?? reward.rewardType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(reward.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                reward.rewardText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'referral_bonus':
        return Iconsax.people;
      case 'signup_bonus':
        return Iconsax.gift;
      case 'coupon_redemption':
        return Iconsax.ticket_discount;
      default: 
        return Iconsax.medal_star;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date. year}';
    }
  }
}