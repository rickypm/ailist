import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/user_model.dart';
import '../../screens/subscription/subscription_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isPartner;

  const ProfileScreen({
    super.key,
    this.isPartner = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();
    
    if (authProvider.user != null) {
      await dataProvider.initUser(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dataProvider = context.watch<DataProvider>();
    final user = dataProvider.currentUser;

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
          'Profile',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: AppColors.white),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: _getPlanGradient(user),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceNavy,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: user?.avatarUrl != null
                              ? Image.network(
                                  user!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 94,
                                  height: 94,
                                  errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(user.name ?? 'U'),
                                )
                              : _buildAvatarPlaceholder(user?.name ?? 'U'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name - ✅ WHITE TEXT
                  Text(
                    user?.name ?? user?.displayNameOrEmail ?? 'User',
                    style: AppTextStyles.h2.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 8),

                  // Email - ✅ MUTED TEXT
                  Text(
                    user?.email ?? authProvider.user?.email ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),

                  // Plan badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _getPlanGradient(user),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isPremiumPlan(user)) ...[
                          const Icon(Iconsax.crown1, color: AppColors.white, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          user?.displayPlan ?? 'FREE',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Account Section
                  _buildSection(
                    context,
                    title: 'Account',
                    items: [
                      _ProfileItem(
                        icon: Iconsax.user_edit,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ).then((_) => _loadUserData());
                        },
                      ),
                      _ProfileItem(
                        icon: Iconsax.lock,
                        title: 'Change Password',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Change password - Coming soon')),
                          );
                        },
                      ),
                      _ProfileItem(
                        icon: Iconsax.location,
                        title: 'Location',
                        subtitle: user?.city ?? 'Not set',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          ).then((_) => _loadUserData());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Subscription Section
                  _buildSection(
                    context,
                    title: 'Subscription',
                    items: [
                      _ProfileItem(
                        icon: Iconsax.crown,
                        title: 'Current Plan',
                        subtitle: _getPlanDescription(user),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SubscriptionScreen(isPartner: widget.isPartner)),
                          ).then((_) => _loadUserData());
                        },
                      ),
                      _ProfileItem(
                        icon: Iconsax.unlock,
                        title: 'Unlocks Remaining',
                        subtitle: _getUnlocksText(user),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SubscriptionScreen(isPartner: widget.isPartner)),
                          ).then((_) => _loadUserData());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Support Section
                  _buildSection(
                    context,
                    title: 'Support',
                    items: [
                      _ProfileItem(
                        icon: Iconsax.info_circle,
                        title: 'Help & Support',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help & Support - Coming soon')),
                          );
                        },
                      ),
                      _ProfileItem(
                        icon: Iconsax.document,
                        title: 'Terms & Privacy',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terms & Privacy - Coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await authProvider.signOut();
                        if (context.mounted) {
                          dataProvider.clearData();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      icon: const Icon(Iconsax.logout, color: AppColors.error),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  bool _isPremiumPlan(UserModel? user) {
    if (user == null) return false;
    final plan = user.subscriptionPlan.toLowerCase();
    return plan == 'plus' || plan == 'pro';
  }

  Gradient _getPlanGradient(UserModel? user) {
    if (user == null) return AppColors.inputBorderGradient;
    
    final plan = user.subscriptionPlan.toLowerCase();
    switch (plan) {
      case 'plus':
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        );
      case 'pro':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        );
      case 'basic':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        );
      default:
        return AppColors.inputBorderGradient;
    }
  }

  String _getPlanDescription(UserModel? user) {
    if (user == null) return 'Free';
    
    final plan = user.subscriptionPlan.toLowerCase();
    switch (plan) {
      case 'plus':
        return 'Plus • Unlimited Unlocks';
      case 'pro':
        return 'Pro • All Features';
      case 'basic':
        return 'Basic • 3 Unlocks/month';
      default:
        return 'Free';
    }
  }

  String _getUnlocksText(UserModel? user) {
    if (user == null) return '0';
    
    final plan = user.subscriptionPlan.toLowerCase();
    
    if (plan == 'plus' || plan == 'pro') {
      return '∞ Unlimited';
    }
    
    final unlocks = user.unlockBalance ?? 0;
    if (unlocks == -1) {
      return '∞ Unlimited';
    }
    
    return '$unlocks';
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      width: 94,
      height: 94,
      color: AppColors.surfaceNavy,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_ProfileItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Section title - visible on dark background
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        // ✅ Section container - dark surface color
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderNavy,
              width: 1,
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    // ✅ Title - WHITE text
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                    // ✅ Subtitle - MUTED text
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Iconsax.arrow_right_3,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    Divider(
                      color: AppColors.borderNavy,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _ProfileItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}