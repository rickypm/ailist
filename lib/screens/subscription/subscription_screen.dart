import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isPartner;  // ADDED

  const SubscriptionScreen({
    super.key,
    this.isPartner = false,  // ADDED
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _selectedPlan;

  // User plans
  final List<Map<String, dynamic>> _userPlans = [
    {
      'id': 'basic',
      'name': 'Basic',
      'price': 99,
      'duration': 'month',
      'features': [
        '3 Unlocks per month',
        'AI-powered search',
        'Message professionals',
        'Basic support',
      ],
      'color': AppColors.info,
    },
    {
      'id': 'plus',
      'name': 'Plus',
      'price': 199,
      'duration': 'month',
      'features': [
        'Unlimited unlocks',
        'AI-powered search',
        'Message professionals',
        'Priority support',
        'No ads',
      ],
      'color': AppColors.primary,
      'popular': true,
    },
    {
      'id': 'pro',
      'name': 'Pro',
      'price': 499,
      'duration': 'month',
      'features': [
        'Everything in Plus',
        'Early access to features',
        'Dedicated support',
        'Profile badge',
        'Analytics dashboard',
      ],
      'color': AppColors.warning,
    },
  ];

  // Partner plans
  final List<Map<String, dynamic>> _partnerPlans = [
    {
      'id': 'starter',
      'name': 'Starter',
      'price': 199,
      'duration': 'month',
      'features': [
        'Business profile listing',
        'Up to 10 portfolio items',
        'Basic analytics',
        'Email support',
      ],
      'color': AppColors.info,
    },
    {
      'id': 'business',
      'name': 'Business',
      'price': 499,
      'duration': 'month',
      'features': [
        'Featured profile listing',
        'Unlimited portfolio items',
        'Advanced analytics',
        'Priority support',
        'Verified badge',
      ],
      'color': AppColors.primary,
      'popular': true,
    },
    {
      'id': 'enterprise',
      'name': 'Enterprise',
      'price': 999,
      'duration': 'month',
      'features': [
        'Everything in Business',
        'Top search ranking',
        'Dedicated account manager',
        'Custom branding',
        'API access',
      ],
      'color': AppColors.warning,
    },
  ];

  List<Map<String, dynamic>> get _plans => widget.isPartner ? _partnerPlans : _userPlans;

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  void _initPayment() {
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = false);

    // Refresh user data
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();
    
    if (authProvider.user != null) {
      await dataProvider.initUser(authProvider.user!.id);
    }

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Payment failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your ${_selectedPlan?.toUpperCase()} plan is now active.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: AppColors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPayment(Map<String, dynamic> plan) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to subscribe')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedPlan = plan['id'];
    });

    try {
      await _paymentService.startPayment(
        userId: user.id,
        userType: widget.isPartner ? 'professional' : 'user',  // UPDATED
        plan: plan['id'],
        amount: (plan['price'] as int).toDouble(),
        userName: user.name ?? user.displayNameOrEmail,
        userEmail: user.email,
        userPhone: user.phone,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNavy,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isPartner ? 'Partner Plans' : 'Choose Plan',  // UPDATED
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              widget.isPartner ? 'Grow Your Business' : 'Upgrade to Premium',  // UPDATED
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isPartner 
                  ? 'Get more visibility and reach more customers'  // UPDATED
                  : 'Get unlimited access to all features',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Current Plan
            Consumer<DataProvider>(
              builder: (context, dataProvider, _) {
                final currentPlan = widget.isPartner
                    ? dataProvider.currentProfessional?.subscriptionPlan ?? 'free'
                    : dataProvider.currentUser?.subscriptionPlan ?? 'free';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderNavy),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.crown, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Plan',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currentPlan.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Plans
            ..._plans.map((plan) => _buildPlanCard(plan)),

            const SizedBox(height: 24),

            // Features comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isPartner 
                        ? 'All Partner Plans Include:'  // UPDATED
                        : 'All Premium Plans Include:',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.isPartner) ...[
                    _buildFeatureRow('Professional business listing'),
                    _buildFeatureRow('Direct customer inquiries'),
                    _buildFeatureRow('Portfolio showcase'),
                    _buildFeatureRow('Business analytics'),
                    _buildFeatureRow('Customer support'),
                  ] else ...[
                    _buildFeatureRow('AI-powered professional search'),
                    _buildFeatureRow('Direct messaging with professionals'),
                    _buildFeatureRow('View complete contact details'),
                    _buildFeatureRow('Priority customer support'),
                    _buildFeatureRow('Ad-free experience'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            const Text(
              'Subscriptions auto-renew monthly. Cancel anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isPopular = plan['popular'] == true;
    final color = plan['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? color : AppColors.borderNavy,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Popular badge
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name & price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['name'],
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '₹${plan['price']}',
                            style: TextStyle(
                              color: color,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '/${plan['duration']}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
                ...((plan['features'] as List<String>).map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Iconsax.tick_circle, color: color, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          feature,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                })),

                const SizedBox(height: 16),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _startPayment(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? color : AppColors.surfaceNavy,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: color),
                      ),
                    ),
                    child: _isLoading && _selectedPlan == plan['id']
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            'Subscribe to ${plan['name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Iconsax.tick_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}