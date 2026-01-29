import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/shop_model.dart';

class ShopCard extends StatelessWidget {
  final ShopModel shop;
  final VoidCallback?  onTap;
  final bool showFullDetails;

  const ShopCard({
    super.key,
    required this.shop,
    this.onTap,
    this.showFullDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border. all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Logo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Shop Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:  AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: shop.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image. network(
                              shop.logoUrl!,
                              fit:  BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                            ),
                          )
                        : _buildLogoPlaceholder(),
                  ),
                  const SizedBox(width: 16),

                  // Shop Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment. start,
                      children: [
                        // Name & Verified
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (shop.isVerified) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets. symmetric(
                                  horizontal:  6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Iconsax.verify5,
                                      size: 10,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Location
                        Row(
                          children: [
                            Icon(
                              Iconsax. location,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop.fullAddress,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize:  12,
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

                  // Arrow
                  if (onTap != null)
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),

            // Description (if available and showFullDetails)
            if (showFullDetails && shop.description != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  shop.description!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical:  12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  _buildStat(
                    icon:  Iconsax.star1,
                    value: shop.ratingDisplay,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    icon: Iconsax.message,
                    value: '${shop.totalReviews} reviews',
                  ),
                  const Spacer(),
                  if (shop.phone != null || shop.whatsapp != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.call,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Contact',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Icon(
        Iconsax. shop,
        color: AppColors.textMuted,
        size: 28,
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    Color?  color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight:  FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Compact Shop Card for lists
class ShopListTile extends StatelessWidget {
  final ShopModel shop;
  final VoidCallback? onTap;

  const ShopListTile({
    super.key,
    required this.shop,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical:  8),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius:  BorderRadius.circular(10),
        ),
        child: shop.logoUrl != null
            ?  ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  shop.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Iconsax.shop,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            : Icon(Iconsax.shop, color: AppColors.textMuted),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              shop.name,
              style: const TextStyle(
                fontWeight:  FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (shop.isVerified)
            Icon(Iconsax.verify5, size: 14, color: AppColors.primary),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Iconsax.location, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  shop.city,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Iconsax. star1, size: 12, color:  AppColors.warning),
              const SizedBox(width: 4),
              Text(
                shop.ratingDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: 18,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}