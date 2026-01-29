import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../subscription/subscription_screen.dart';
import '../partner/item_editor_screen.dart'; // Ensure this import exists

class PartnerHomeScreen extends StatefulWidget {
  final Function(int) onSwitchTab; // Callback to switch tabs

  const PartnerHomeScreen({
    super.key, 
    required this.onSwitchTab,
  });

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user != null) {
      await dataProvider.loadPartnerStats(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dataProvider = context.watch<DataProvider>();
    final user = authProvider.user;
    final professional = dataProvider.selectedProfessional;
    final stats = dataProvider.partnerStats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back! 👋',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            professional?.displayName ?? user?.name ?? 'Partner',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AvatarWidget(
                      imageUrl: professional?.avatarUrl ?? user?.avatarUrl,
                      name: professional?.displayName ?? user?.name,
                      size: 48,
                      isVerified: professional?.isVerified ?? false,
                      showBorder: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Subscription Banner
                _buildSubscriptionBanner(professional),
                const SizedBox(height: 24),

                // Stats Grid
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                if (dataProvider.partnerStatsLoading)
                  const ShimmerGrid(itemCount: 4, childAspectRatio: 1.5)
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        icon: Iconsax.search_normal,
                        title: 'Search Appearances',
                        value: '${stats['searches'] ?? 0}',
                        color: AppColors.info,
                      ),
                      _buildStatCard(
                        icon: Iconsax.eye,
                        title: 'Profile Views',
                        value: '${stats['views'] ?? 0}',
                        color: AppColors.accent,
                      ),
                      _buildStatCard(
                        icon: Iconsax.message,
                        title: 'Total Messages',
                        value: '${stats['messages'] ?? 0}',
                        color: AppColors.success,
                      ),
                      _buildStatCard(
                        icon: Iconsax.notification,
                        title: 'Unread Messages',
                        value: '${stats['unread'] ?? 0}',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Iconsax.shop_add,
                        title: 'Manage Shop',
                        color: AppColors.primary,
                        onTap: () {
                          // Switch to Shop Tab (Index 1)
                          widget.onSwitchTab(1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Iconsax.box_add,
                        title: 'Add Service',
                        color: AppColors.accent,
                        onTap: () {
                          if (dataProvider.shop != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemEditorScreen(
                                  shopId: dataProvider.shop!.id,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please create a shop first!')),
                            );
                            // Optionally switch to shop tab to create one
                            widget.onSwitchTab(1); 
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Iconsax.message,
                        title: 'Messages',
                        color: AppColors.info,
                        onTap: () {
                          // Switch to Inbox Tab (Index 2)
                          widget.onSwitchTab(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Iconsax.crown,
                        title: 'Upgrade Plan',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen(isPartner: true),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tips Section
                _buildTipsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBanner(dynamic professional) {
    final plan = professional?.subscriptionPlan ?? 'free';
    final isFreePlan = plan == 'free';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isFreePlan
            ? LinearGradient(
                colors: [
                  AppColors.warning.withOpacity(0.2),
                  AppColors.warning.withOpacity(0.1),
                ],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isFreePlan
                  ? AppColors.warning.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFreePlan ? Iconsax.crown : Iconsax.medal_star,
              color: isFreePlan ? AppColors.warning : Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFreePlan ? 'Free Plan' : '${plan.toUpperCase()} Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isFreePlan ? AppColors.warning : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFreePlan
                      ? 'Upgrade to unlock messages & more features'
                      : 'You have access to all premium features',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFreePlan
                        ? AppColors.warning.withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (isFreePlan)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(isPartner: true),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.lamp_on, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tips to Get More Customers',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('Complete your profile with a professional photo'),
          _buildTipItem('Add detailed descriptions to your services'),
          _buildTipItem('Use relevant tags to improve discoverability'),
          _buildTipItem('Respond quickly to customer inquiries'),
          _buildTipItem('Upgrade to get the verified badge'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.tick_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}