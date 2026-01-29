import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/shop_model.dart';
import '../../models/item_model.dart';
import '../../providers/data_provider.dart';

class ShopDetailScreen extends StatefulWidget {
  final ShopModel shop;

  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  List<ItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final dataProvider = context.read<DataProvider>();
    await dataProvider.loadShopItems(widget.shop.id);
    setState(() {
      _items = dataProvider.myItems;
      _isLoading = false;
    });
  }

  // Launch phone dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Could not launch phone dialer');
    }
  }

  // Launch WhatsApp
  Future<void> _openWhatsApp(String number) async {
    // Remove any non-digit characters except +
    String cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    // Add country code if not present
    if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+91$cleanNumber';
    }
    
    final Uri uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open WhatsApp');
    }
  }

  // Launch email
  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Inquiry from AiList',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Could not open email app');
    }
  }

  // Launch website
  Future<void> _openWebsite(String url) async {
    String fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = 'https://$url';
    }
    final Uri uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open website');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Show contact options bottom sheet
  void _showContactOptions() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderNavy,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Contact Options',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Phone option
            if (widget.shop.hasPhone)
              _buildContactOption(
                icon: Iconsax.call,
                title: 'Call',
                subtitle: widget.shop.phone!,
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(widget.shop.phone!);
                },
              ),

            // WhatsApp option
            if (widget.shop.hasWhatsapp)
              _buildContactOption(
                icon: Icons.chat,
                title: 'WhatsApp',
                subtitle: widget.shop.whatsapp!,
                color: const Color(0xFF25D366),
                onTap: () {
                  Navigator.pop(context);
                  _openWhatsApp(widget.shop.whatsapp!);
                },
              ),

            // Email option
            if (widget.shop.hasEmail)
              _buildContactOption(
                icon: Iconsax.sms,
                title: 'Email',
                subtitle: widget.shop.email!,
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _sendEmail(widget.shop.email!);
                },
              ),

            // Website option
            if (widget.shop.hasWebsite)
              _buildContactOption(
                icon: Iconsax.global,
                title: 'Website',
                subtitle: widget.shop.website!,
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _openWebsite(widget.shop.website!);
                },
              ),

            // No contact info available
            if (!widget.shop.hasPhone && !widget.shop.hasWhatsapp && !widget.shop.hasEmail)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No contact information available',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textMuted,
        size: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundNavy,
      body: CustomScrollView(
        slivers: [
          // App Bar with Cover Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surfaceNavy,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover Image
                  widget.shop.hasCover
                      ? Image.network(
                          widget.shop.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                        )
                      : _buildPlaceholderCover(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shop Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Header
                _buildShopHeader(),
                
                const Divider(color: AppColors.borderNavy, height: 1),
                
                // Quick Contact Buttons
                _buildQuickContactButtons(),
                
                const Divider(color: AppColors.borderNavy, height: 1),
                
                // About Section
                if (widget.shop.hasDescription) _buildAboutSection(),
                
                // Opening Hours
                if (widget.shop.openingHours.isNotEmpty) _buildOpeningHours(),
                
                // Services/Items Section
                _buildServicesSection(),
                
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
      
      // Bottom Contact Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surfaceNavy,
          border: Border(top: BorderSide(color: AppColors.borderNavy)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _showContactOptions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.message, color: AppColors.white),
                SizedBox(width: 8),
                Text(
                  'Contact Shop',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: AppColors.surfaceNavy,
      child: const Center(
        child: Icon(
          Iconsax.shop,
          size: 64,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildShopHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surfaceNavy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderNavy, width: 2),
              image: widget.shop.hasLogo
                  ? DecorationImage(
                      image: NetworkImage(widget.shop.logoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !widget.shop.hasLogo
                ? const Icon(Iconsax.shop, color: AppColors.primary, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Verified Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.shop.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.shop.isVerified)
                      const Icon(Icons.verified, color: AppColors.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.shop.ratingDisplay} (${widget.shop.totalReviews} reviews)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Location
                Row(
                  children: [
                    const Icon(Iconsax.location, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.shop.locationDisplay,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContactButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Call Button
          if (widget.shop.hasPhone)
            Expanded(
              child: _buildQuickButton(
                icon: Iconsax.call,
                label: 'Call',
                color: Colors.green,
                onTap: () => _makePhoneCall(widget.shop.phone!),
              ),
            ),
          
          if (widget.shop.hasPhone && widget.shop.hasWhatsapp)
            const SizedBox(width: 12),
          
          // WhatsApp Button
          if (widget.shop.hasWhatsapp)
            Expanded(
              child: _buildQuickButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _openWhatsApp(widget.shop.whatsapp!),
              ),
            ),
          
          if ((widget.shop.hasPhone || widget.shop.hasWhatsapp) && widget.shop.hasEmail)
            const SizedBox(width: 12),
          
          // Email Button
          if (widget.shop.hasEmail)
            Expanded(
              child: _buildQuickButton(
                icon: Iconsax.sms,
                label: 'Email',
                color: Colors.orange,
                onTap: () => _sendEmail(widget.shop.email!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.shop.description!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHours() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.clock, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Opening Hours',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.shop.openingHours.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(color: AppColors.white),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.box, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Services & Products',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderNavy),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Iconsax.box, color: AppColors.textMuted, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'No services listed yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildServiceCard(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderNavy),
      ),
      child: Row(
        children: [
          // Image
          if (item.hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Image.network(
                item.imageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.backgroundNavy,
                  child: const Icon(Iconsax.image, color: AppColors.textMuted),
                ),
              ),
            )
          else
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.backgroundNavy,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: const Icon(Iconsax.box, color: AppColors.textMuted, size: 32),
            ),
          
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.hasDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        item.priceDisplay,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Duration if available
                      if (item.durationMinutes != null)
                        Row(
                          children: [
                            const Icon(Iconsax.clock, color: AppColors.textMuted, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${item.durationMinutes} min',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}