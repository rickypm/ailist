import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final bool isVerified;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.showBorder = false,
    this.borderColor,
    this.isVerified = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color: borderColor ?? AppColors.primary,
                      width: 2,
                    )
                  :  null,
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl:  imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          if (isVerified)
            Positioned(
              right: 0,
              bottom:  0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.verify5,
                  size: size * 0.35,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: name != null && name!.isNotEmpty
            ? Text(
                name![0]. toUpperCase(),
                style:  TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              )
            : Icon(
                Iconsax. user,
                size: size * 0.5,
                color: AppColors.textMuted,
              ),
      ),
    );
  }
}