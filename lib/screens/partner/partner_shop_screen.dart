import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common/app_button.dart';
import 'shop_editor_screen.dart';
import 'item_editor_screen.dart';

class PartnerShopScreen extends StatefulWidget {
  const PartnerShopScreen({super.key});

  @override
  State<PartnerShopScreen> createState() => _PartnerShopScreenState();
}

class _PartnerShopScreenState extends State<PartnerShopScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dataProvider = context.read<DataProvider>();

    if (dataProvider.selectedProfessional != null) {
      await dataProvider.loadPartnerShop(dataProvider.selectedProfessional!.id);

      if (dataProvider.shop != null) {
        await dataProvider.loadShopItems(dataProvider.shop!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final shop = dataProvider.shop;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: shop != null ? 200 : 0,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: shop != null ? _buildShopHeader(shop) : null,
              ),
              title: const Text(
                'My Shop',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              actions: [
                if (shop != null)
                  IconButton(
                    icon: const Icon(Iconsax.edit, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShopEditorScreen(shop: shop),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: _buildBody(dataProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: shop != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddListingSheet(shop.id),
              icon: const Icon(Iconsax.add),
              label: const Text('Add Listing'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _buildShopHeader(dynamic shop) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A90D9), Color(0xFF5A7BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Cover Image
          if (shop.coverImageUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.network(
                  shop.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          // Shop Info
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Logo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: shop.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(shop.logoUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Iconsax.shop, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              shop.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (shop.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Iconsax.verify5, color: Colors.white, size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Iconsax.location, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            shop.city ?? 'Location not set',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DataProvider dataProvider) {
    if (dataProvider.shopLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final shop = dataProvider.shop;

    if (shop == null) {
      return _buildNoShop();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Stats
          _buildShopStats(shop),
          const SizedBox(height: 24),

          // Services/Products Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Listings (${dataProvider.shopItems.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (dataProvider.shopItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showAddListingSheet(shop.id),
                  icon: const Icon(Iconsax.add, size: 18),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Items List
          if (dataProvider.itemsLoading)
            const Center(child: CircularProgressIndicator())
          else if (dataProvider.shopItems.isEmpty)
            _buildNoListings(shop.id)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dataProvider.shopItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = dataProvider.shopItems[index];
                return _buildItemCard(item, dataProvider);
              },
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildShopStats(dynamic shop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2EE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Iconsax.search_normal, '${shop.searchAppearances}', 'Searches'),
          _buildStatDivider(),
          _buildStatItem(Iconsax.star1, shop.ratingDisplay, 'Rating'),
          _buildStatDivider(),
          _buildStatItem(Iconsax.message, '${shop.totalReviews}', 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: const Color(0xFFDDE2EE),
    );
  }

  Widget _buildNoShop() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.shop,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Create Your Shop',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your shop profile to start showcasing your services to customers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Create Shop',
            icon: Iconsax.shop_add,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ShopEditorScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoListings(String shopId) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2EE)),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.box,
            size: 48,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No listings yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first service or product',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showAddListingSheet(shopId),
            icon: const Icon(Iconsax.add),
            label: const Text('Add Listing'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item, DataProvider dataProvider) {
    final typeColor = _getTypeColor(item.priceType);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemEditorScreen(
              shopId: dataProvider.shop!.id,
              item: item,
            ),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE2EE)),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE2EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Iconsax.box,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : const Icon(Iconsax.box, color: AppColors.textMuted),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
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
                      const SizedBox(width: 8),
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isActive
                              ? AppColors.success.withOpacity(0.15)
                              : AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.isActive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (item.isFeatured)
                        const Icon(Iconsax.star1, size: 16, color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showAddListingSheet(String shopId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F6FA),
      isScrollControlled: true, // ✅ Fix overflow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55, // ✅ Better size
        minChildSize: 0.4,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE2EE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'What would you like to add?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildListingTypeOption(
                icon: Iconsax.briefcase,
                title: 'Service',
                subtitle: 'e.g., AC Repair, Plumbing',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemEditorScreen(shopId: shopId, initialType: 'service'),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(height: 12),
              _buildListingTypeOption(
                icon: Iconsax.box,
                title: 'Product',
                subtitle: 'Sell a physical product',
                color: AppColors.success,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemEditorScreen(shopId: shopId, initialType: 'product'),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(height: 12),
              _buildListingTypeOption(
                icon: Iconsax.calendar,
                title: 'Rental',
                subtitle: 'Rent out equipment',
                color: AppColors.info,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemEditorScreen(shopId: shopId, initialType: 'rental'),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(height: 12),
              _buildListingTypeOption(
                icon: Iconsax.clock,
                title: 'Booking',
                subtitle: 'Time-based appointments',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemEditorScreen(shopId: shopId, initialType: 'booking'),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: color, size: 18),
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
      default:
        return AppColors.primary;
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
      default:
        return 'Service';
    }
  }
}