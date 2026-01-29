import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/professional_model.dart';
import '../../models/shop_model.dart';
import '../../services/ai_service.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Function(ProfessionalModel)? onProfessionalTap;
  final Function(ShopModel)? onShopTap;
  final List<ProfessionalModel>? professionals;
  final List<ShopModel>? shops;
  final bool isLoading;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onProfessionalTap,
    this.onShopTap,
    this.professionals,
    this.shops,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserMessage();
    } else {
      return _buildAssistantMessage(context);
    }
  }

  Widget _buildUserMessage() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.inputBorderGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: AppColors.borderNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormattedContent(message.content),

          // Professional Results - ✅ FIX: Ensure cards are tappable
          if (professionals != null && professionals!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Tap to view profile:',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...professionals!.take(5).map((professional) {
              return _buildProfessionalCard(context, professional);
            }),
          ],

          // Shop Results
          if (shops != null && shops!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...shops!.take(3).map((shop) {
              return _buildShopCard(context, shop);
            }),
          ],

          // No results message
          if (professionals?.isEmpty == true &&
              shops?.isEmpty == true &&
              !isLoading) ...[
            const SizedBox(height: 8),
            Text(
              'Browse categories for more options.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('**') && line.endsWith('**')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line.replaceAll('**', ''),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                fontSize: 15,
              ),
            ),
          );
        } else if (line.startsWith('• ') || line.startsWith('- ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.primary)),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  // ✅ FIX: Professional card with proper tap handling
  Widget _buildProfessionalCard(BuildContext context, ProfessionalModel professional) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('🔍 Card tapped: ${professional.displayName}');
          if (onProfessionalTap != null) {
            onProfessionalTap!(professional);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: professional.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          professional.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(professional.displayName),
                        ),
                      )
                    : _buildAvatarPlaceholder(professional.displayName),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            professional.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (professional.isVerified)
                          const Icon(
                            Iconsax.verify5,
                            size: 14,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      professional.profession,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.location, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          professional.city,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (professional.rating > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Iconsax.star1, size: 12, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            professional.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow indicator
              const Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, ShopModel shop) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onShopTap?.call(shop),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.shop, color: AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shop.city,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}