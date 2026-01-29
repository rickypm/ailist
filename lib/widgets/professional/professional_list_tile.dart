import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/professional_model.dart';

class ProfessionalListTile extends StatelessWidget {
  final ProfessionalModel professional;
  final VoidCallback?  onTap;
  final bool showUnlockStatus;
  final bool isUnlocked;

  const ProfessionalListTile({
    super.key,
    required this.professional,
    this.onTap,
    this.showUnlockStatus = false,
    this.isUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border. all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children:  [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Verified
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isUnlocked ?  professional.displayName : professional.visibleName,
                          style:  const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors. textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (professional.isVerified) ...[
                        const SizedBox(width: 6),
                        Icon(Iconsax. verify5, size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Profession
                  Text(
                    professional. profession,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Stats Row
                  Row(
                    children: [
                      // Rating
                      Icon(Iconsax.star1, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        professional. ratingDisplay,  // Fixed: removed space
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Location
                      Icon(Iconsax.location, size: 14, color: AppColors. textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          professional.city,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
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

            // Arrow or Lock
            if (showUnlockStatus)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors. warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:  Icon(
                  isUnlocked ?  Iconsax.unlock :  Iconsax.lock,
                  size: 18,
                  color: isUnlocked ?  AppColors.success : AppColors. warning,
                ),
              )
            else
              Icon(
                Iconsax.arrow_right_3,
                size:  20,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration:  BoxDecoration(
        color:  AppColors.surfaceLight,
        borderRadius:  BorderRadius.circular(12),
        border: professional.isVerified
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(professional.isVerified ? 10 : 12),
        child: professional.avatarUrl != null
            ? Image.network(
                professional.avatarUrl!,
                fit: BoxFit. cover,
                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
              )
            : _buildAvatarPlaceholder(),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          professional.displayName. isNotEmpty
              ? professional. displayName[0].toUpperCase()
              : 'P',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors. textMuted,
          ),
        ),
      ),
    );
  }
}

class ProfessionalCompactTile extends StatelessWidget {
  final ProfessionalModel professional;
  final VoidCallback? onTap;

  const ProfessionalCompactTile({
    super.key,
    required this. professional,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:  onTap,
      child:  Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius. circular(10),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius:  BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius:  BorderRadius.circular(8),
                child: professional.avatarUrl != null
                    ? Image. network(
                        professional. avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            professional.displayName.isNotEmpty
                                ? professional. displayName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontWeight:  FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          professional.displayName.isNotEmpty
                              ? professional.displayName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:  Text(
                          professional.visibleName,
                          style:  const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors. textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (professional.isVerified)
                        Icon(Iconsax.verify5, size: 14, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    professional.profession,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow. ellipsis,
                  ),
                ],
              ),
            ),

            // Rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize. min,
                children: [
                  Icon(Iconsax. star1, size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    professional.ratingDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:  FontWeight.w600,
                      color: AppColors.warning,
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
}