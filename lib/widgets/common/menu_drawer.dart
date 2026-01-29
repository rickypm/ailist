import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/partner/partner_main_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/subscription/subscription_screen.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dataProvider = context.watch<DataProvider>();

    return Drawer(
      backgroundColor: AppColors.surfaceNavy,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, authProvider),

            const Divider(color: AppColors.borderNavy, height: 1),

            // Menu Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Iconsax.home,
                      title: 'Home',
                      onTap: () => Navigator.pop(context),
                    ),

                    if (authProvider.isLoggedIn) ...[
                      _buildDrawerItem(
                        context,
                        icon: Iconsax.user,
                        title: 'My Profile',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                      ),
                      
                      _buildDrawerItem(
                        context,
                        icon: Iconsax.heart,
                        title: 'Saved Professionals',
                        badge: dataProvider.savedProfessionals.length.toString(),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved professionals coming soon!')),
                          );
                        },
                      ),

                      _buildDrawerItem(
                        context,
                        icon: Iconsax.clock,
                        title: 'Booking History',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking history coming soon!')),
                          );
                        },
                      ),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(color: AppColors.borderNavy, height: 1),
                    ),

                    // Partner Section
                    _buildSectionTitle('For Professionals'),

                    _buildDrawerItem(
                      context,
                      icon: Iconsax.briefcase,
                      title: 'Become a Partner',
                      subtitle: 'List your services',
                      onTap: () {
                        Navigator.pop(context);
                        if (authProvider.isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PartnerMainScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                    ),

                    if (authProvider.isLoggedIn && authProvider.user?.isPartner == true)
                      _buildDrawerItem(
                        context,
                        icon: Iconsax.chart,
                        title: 'Partner Dashboard',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PartnerMainScreen()),
                          );
                        },
                      ),

                    _buildDrawerItem(
                      context,
                      icon: Iconsax.crown,
                      title: 'Subscription Plans',
                      badge: 'PRO',
                      badgeColor: AppColors.warning,
                      onTap: () {
                        Navigator.pop(context);
                        if (authProvider.isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(color: AppColors.borderNavy, height: 1),
                    ),

                    // Support Section
                    _buildSectionTitle('Support'),

                    _buildDrawerItem(
                      context,
                      icon: Iconsax.message_question,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        _showHelpDialog(context);
                      },
                    ),

                    _buildDrawerItem(
                      context,
                      icon: Iconsax.star,
                      title: 'Rate Us',
                      onTap: () {
                        Navigator.pop(context);
                        _rateApp(context);
                      },
                    ),

                    _buildDrawerItem(
                      context,
                      icon: Iconsax.share,
                      title: 'Share App',
                      onTap: () {
                        Navigator.pop(context);
                        _shareApp();
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(color: AppColors.borderNavy, height: 1),
                    ),

                    // Settings & Legal
                    _buildDrawerItem(
                      context,
                      icon: Iconsax.setting_2,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),

                    _buildDrawerItem(
                      context,
                      icon: Iconsax.shield_tick,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.pop(context);
                        _openPrivacyPolicy();
                      },
                    ),

                    _buildDrawerItem(
                      context,
                      icon: Iconsax.document,
                      title: 'Terms of Service',
                      onTap: () {
                        Navigator.pop(context);
                        _openTermsOfService();
                      },
                    ),

                    if (authProvider.isLoggedIn) ...[
                      const SizedBox(height: 8),
                      _buildDrawerItem(
                        context,
                        icon: Iconsax.logout,
                        title: 'Logout',
                        textColor: AppColors.error,
                        iconColor: AppColors.error,
                        onTap: () => _confirmLogout(context, authProvider),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            _buildFooter(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Logo Row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.menu_board,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AiList',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Find local services',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (authProvider.isLoggedIn) ...[
            const SizedBox(height: 20),
            // User Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderNavy),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: authProvider.user?.avatarUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              authProvider.user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  _getInitial(authProvider.user?.name),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _getInitial(authProvider.user?.name),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.user?.name ?? 'User',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authProvider.user?.email ?? '',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Iconsax.arrow_right_3,
                    color: AppColors.textHint,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to safely get initial
  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
            )
          : null,
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(
              Iconsax.arrow_right_3,
              color: AppColors.textHint,
              size: 16,
            ),
      onTap: onTap,
    );
  }

  Widget _buildFooter(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderNavy),
        ),
      ),
      child: Column(
        children: [
          if (!authProvider.isLoggedIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Version ${AppConfig.appVersion}',
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderNavy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'How can we help?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildHelpOption(
              context,
              icon: Iconsax.message_question,
              title: 'FAQs',
              subtitle: 'Find answers to common questions',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildHelpOption(
              context,
              icon: Iconsax.message,
              title: 'Chat with us',
              subtitle: 'We usually reply within minutes',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildHelpOption(
              context,
              icon: Iconsax.call,
              title: 'Call support',
              subtitle: 'Mon-Sat, 9AM to 6PM',
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('tel:${AppConfig.supportPhone}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            _buildHelpOption(
              context,
              icon: Iconsax.sms,
              title: 'Email us',
              subtitle: AppConfig.supportEmail,
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('mailto:${AppConfig.supportEmail}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Iconsax.arrow_right_3,
        color: AppColors.textHint,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _rateApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Enjoying WeList?',
          style: TextStyle(color: AppColors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'If you love using WeList, please take a moment to rate us!',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => const Icon(
                  Iconsax.star1,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your support!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    Share.share(
      'Check out WeList - Find trusted local service professionals in your area! Download now: ${AppConfig.appStoreUrl}',
      subject: 'WeList - Find Local Services',
    );
  }

  void _openPrivacyPolicy() async {
    final uri = Uri.parse(AppConfig.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openTermsOfService() async {
    final uri = Uri.parse(AppConfig.termsOfServiceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              await authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}