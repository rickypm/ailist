import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/professional_model.dart';
import '../../models/shop_model.dart';
import '../../models/item_model.dart';
import '../../widgets/chat/chat_message_widget.dart';
import '../../widgets/chat/category_grid.dart';
import '../../widgets/shop/shop_card.dart';
import '../../widgets/common/menu_drawer.dart';
import '../messages/inbox_screen.dart';
import '../services/professional_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';
import '../shops/shop_detail_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  int _selectedNavIndex = 0;
  int _selectedTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Updated tabs: Services, Shops, Rentals, Bookings
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Services', 'icon': Iconsax.briefcase, 'type': 'service'},
    {'label': 'Shops', 'icon': Iconsax.shop, 'type': 'shop'},
    {'label': 'Rentals', 'icon': Iconsax.calendar, 'type': 'rental'},
    {'label': 'Bookings', 'icon': Iconsax.clock, 'type': 'booking'},
  ];

  // Store items for each tab
  List<ItemModel> _rentalItems = [];
  List<ItemModel> _bookingItems = [];
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final dataProvider = context.read<DataProvider>();
    await dataProvider.loadCategories();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    setState(() => _selectedTabIndex = index);

    final dataProvider = context.read<DataProvider>();
    final userCity = dataProvider.currentUser?.city ?? AppConfig.defaultCity;

    switch (index) {
      case 1: // Shops
        dataProvider.searchShops('', city: userCity);
        break;
      case 2: // Rentals
        _loadItemsByType('rental', userCity);
        break;
      case 3: // Bookings
        _loadItemsByType('booking', userCity);
        break;
    }
  }

  Future<void> _loadItemsByType(String type, String city) async {
    setState(() => _loadingItems = true);

    final dataProvider = context.read<DataProvider>();

    try {
      final items = await dataProvider.getItemsByType(type, city: city);

      setState(() {
        if (type == 'rental') {
          _rentalItems = items;
        } else if (type == 'booking') {
          _bookingItems = items;
        }
        _loadingItems = false;
      });
    } catch (e) {
      setState(() => _loadingItems = false);
    }
  }

  void _handleSend() async {
    final query = _inputController.text.trim();
    if (query.isEmpty) return;

    setState(() => _selectedTabIndex = 0);

    final dataProvider = context.read<DataProvider>();
    final authProvider = context.read<AuthProvider>();
    _inputController.clear();

    final userCity = dataProvider.currentUser?.city ?? AppConfig.defaultCity;

    await dataProvider.sendAIMessage(
      message: query,
      userId: authProvider.user?.id,
      city: userCity,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToProfessionalDetail(ProfessionalModel professional) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessionalDetailScreen(professional: professional),
      ),
    );
  }

  void _navigateToShopDetail(ShopModel shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailScreen(shop: shop),
      ),
    );
  }

  void _requireAuth({required VoidCallback onAuthenticated}) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn) {
      onAuthenticated();
    } else {
      _showLoginPrompt();
    }
  }

  void _showLoginPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppColors.inputBorderGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.login, color: AppColors.white, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign in Required',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please sign in to access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    if (index == 1) {
      _requireAuth(
        onAuthenticated: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InboxScreen()),
          );
        },
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      setState(() => _selectedNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundNavy,
      drawer: const MenuDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabSelector(),
            Expanded(child: _buildContent()),
            _buildBottomInput(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final dataProvider = context.watch<DataProvider>();
    final userCity = dataProvider.currentUser?.city ?? AppConfig.defaultCity;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AiList',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceNavy,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderNavy),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.location, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      userCity,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              'What do you need?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          final tab = _tabs[index];

          return GestureDetector(
            onTap: () => _handleTabTap(index),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderNavy,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 16,
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        switch (_selectedTabIndex) {
          case 1: // Shops
            return _buildShopsContent(dataProvider);
          case 2: // Rentals
            return _buildItemsContent(_rentalItems, 'rental');
          case 3: // Bookings
            return _buildItemsContent(_bookingItems, 'booking');
          default: // Services (0)
            final messages = dataProvider.chatMessages;
            final matchedProfessionals = dataProvider.aiMatchedProfessionals;

            if (messages.isEmpty) {
              return _buildCategoriesContent(dataProvider);
            }
            return _buildChatContent(dataProvider, messages, matchedProfessionals);
        }
      },
    );
  }

  Widget _buildShopsContent(DataProvider dataProvider) {
    if (dataProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (dataProvider.shops.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.shop,
        title: 'No shops found nearby',
        onRefresh: () {
          final userCity = dataProvider.currentUser?.city ?? AppConfig.defaultCity;
          dataProvider.searchShops('', city: userCity);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dataProvider.shops.length,
      itemBuilder: (context, index) {
        final shop = dataProvider.shops[index];
        return ShopCard(
          shop: shop,
          onTap: () => _navigateToShopDetail(shop),
        );
      },
    );
  }

  Widget _buildItemsContent(List<ItemModel> items, String type) {
    if (_loadingItems) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (items.isEmpty) {
      final typeLabel = type == 'rental' ? 'rentals' : 'bookings';
      return _buildEmptyState(
        icon: type == 'rental' ? Iconsax.calendar : Iconsax.clock,
        title: 'No $typeLabel found nearby',
        onRefresh: () {
          final dataProvider = context.read<DataProvider>();
          final userCity = dataProvider.currentUser?.city ?? AppConfig.defaultCity;
          _loadItemsByType(type, userCity);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(ItemModel item) {
    final typeColor = _getTypeColor(item.priceType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderNavy),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.backgroundNavy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        _getTypeIcon(item.priceType),
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : Icon(_getTypeIcon(item.priceType), color: AppColors.textMuted),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTypeLabel(item.priceType),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.priceDisplay,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (item.durationMinutes != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Iconsax.clock, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${item.durationMinutes} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required VoidCallback onRefresh,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRefresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesContent(DataProvider dataProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CategoryGrid(
        categories: dataProvider.categories,
        onCategoryTap: (category) {
          _inputController.text = 'Find me a ${category.name.toLowerCase()}';
          _handleSend();
        },
      ),
    );
  }

  Widget _buildChatContent(
    DataProvider dataProvider,
    List<dynamic> messages,
    List<ProfessionalModel> matchedProfessionals,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (dataProvider.aiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && dataProvider.aiTyping) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 12),
                Text('Searching...', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }

        final message = messages[index];
        final isLastAssistantMessage =
            !message.isUser && index == messages.length - 1 && !dataProvider.aiTyping;
        final professionalsToShow = isLastAssistantMessage ? matchedProfessionals : null;

        return ChatMessageWidget(
          message: message,
          onProfessionalTap: (professional) => _navigateToProfessionalDetail(professional),
          onShopTap: _navigateToShopDetail,
          professionals: professionalsToShow,
        );
      },
    );
  }

  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceNavy,
        border: Border(top: BorderSide(color: AppColors.borderNavy)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF151E32),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: AppColors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.send_2, color: AppColors.primary, size: 24),
              onPressed: _handleSend,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceNavy,
        border: Border(top: BorderSide(color: AppColors.borderNavy, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Iconsax.home, activeIcon: Iconsax.home_1, label: 'Home'),
              _buildNavItem(index: 1, icon: Iconsax.message, activeIcon: Iconsax.message, label: 'Inbox'),
              _buildNavItem(index: 2, icon: Iconsax.user, activeIcon: Iconsax.user, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _handleNavTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textHint,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'service':
        return AppColors.primary;
      case 'product':
        return AppColors.success;
      case 'rental':
        return AppColors.info;
      case 'booking':
        return AppColors.warning;
      case 'other':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'service':
        return Iconsax.briefcase;
      case 'product':
        return Iconsax.box;
      case 'rental':
        return Iconsax.calendar;
      case 'booking':
        return Iconsax.clock;
      case 'other':
        return Iconsax.more;
      default:
        return Iconsax.box;
    }
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'service':
        return 'Service';
      case 'product':
        return 'Product';
      case 'rental':
        return 'Rental';
      case 'booking':
        return 'Booking';
      case 'other':
        return 'Other';
      default:
        return 'Service';
    }
  }
}