import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import 'partner_home_screen.dart';
import 'partner_shop_screen.dart';
// import 'partner_inbox_screen.dart';
import '../profile/profile_screen.dart';
import '../messages/inbox_screen.dart';

class PartnerMainScreen extends StatefulWidget {
  const PartnerMainScreen({super.key});

  @override
  State<PartnerMainScreen> createState() => _PartnerMainScreenState();
}

class _PartnerMainScreenState extends State<PartnerMainScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('🔴🔴🔴 PARTNER MAIN LOADING ���🔴🔴');
    final authProvider = context.read<AuthProvider>();
    final dataProvider = context.read<DataProvider>();

    if (authProvider.user != null) {
      // ✅ FIX: First load professional profile
      await dataProvider.loadProfessionalByUserId(authProvider.user!.id);
      
      // ✅ FIX: Then load shop using the professional ID
      final professional = dataProvider.selectedProfessional;
      debugPrint('🔍 Partner Main: Professional loaded: ${professional?.id}');
      
      if (professional != null) {
        // Load shop by professional ID
        await dataProvider.loadPartnerShop(professional.id);
        debugPrint('🔍 Partner Main: Shop loaded: ${dataProvider.shop?.name}');
        
        // Load stats
        await dataProvider.loadPartnerStats(professional.id);
        
        // Load conversations
        await dataProvider.loadConversations(professional.id, isPartner: true);
        
        // Load shop items if shop exists
        if (dataProvider.shop != null) {
          await dataProvider.loadShopItems(dataProvider.shop!.id);
          debugPrint('🔍 Partner Main: Shop items loaded: ${dataProvider.shopItems.length}');
        }
      } else {
        debugPrint('⚠️ Partner Main: No professional profile found for user');
      }
      
      await dataProvider.loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      PartnerHomeScreen(onSwitchTab: _switchTab),
      const PartnerShopScreen(),
      const InboxScreen(initialPartnerView: true),
      const ProfileScreen(isPartner: true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Iconsax.home,
                  activeIcon: Iconsax.home_15,
                  label: 'Dashboard',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Iconsax.shop,
                  activeIcon: Iconsax.shop,
                  label: 'My Shop',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Iconsax.message,
                  activeIcon: Iconsax.message,
                  label: 'Inbox',
                  showBadge: _getUnreadCount() > 0,
                  badgeCount: _getUnreadCount(),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Iconsax.user,
                  activeIcon: Iconsax.user,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getUnreadCount() {
    try {
      final dataProvider = context.watch<DataProvider>();
      int count = 0;
      for (final conv in dataProvider.conversations) {
        count += conv.professionalUnreadCount;
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
                if (showBadge && badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}