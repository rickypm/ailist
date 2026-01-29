import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/professional_model.dart';
import '../common/avatar_widget.dart';

class ProfessionalCard extends StatelessWidget {
  final ProfessionalModel professional;
  final bool isUnlocked;
  final VoidCallback onTap;
  final VoidCallback? onUnlock;
  final bool showUnlockButton;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.isUnlocked,
    required this. onTap,
    this. onUnlock,
    this. showUnlockButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap:  onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              AvatarWidget(
                imageUrl: professional.avatarUrl,
                name: professional.displayName,
                size: 64,
                isVerified: professional.isVerified,
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Verified Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isUnlocked
                                ? professional.displayName
                                : professional.visibleName,
                            style:  const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (professional.isVerified)
                          _buildVerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Profession
                    Text(
                      professional.profession,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Info chips
                    Row(
                      children: [
                        _buildInfoChip(
                          Iconsax.location,
                          professional.city,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Iconsax.briefcase,
                          professional.experienceDisplay,
                        ),
                      ],
                    ),
                    
                    // Services
                    if (professional.services.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: professional. services
                            .take(3)
                            .map((service) => _buildServiceChip(service))
                            .toList(),
                      ),
                    ],
                    
                    // Unlock Button
                    if (showUnlockButton && ! isUnlocked && onUnlock != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width:  double.infinity,
                        child: OutlinedButton. icon(
                          onPressed:  onUnlock,
                          icon: const Icon(Iconsax.unlock, size: 16),
                          label: const Text('Unlock Contact'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical:  4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.verify5, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 10,
              color:  AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceChip(String service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius:  BorderRadius.circular(4),
      ),
      child: Text(
        service,
        style:  const TextStyle(fontSize: 11),
      ),
    );
  }
}

class ProfessionalListTile extends StatelessWidget {
  final ProfessionalModel professional;
  final bool isUnlocked;
  final VoidCallback onTap;

  const ProfessionalListTile({
    super.key,
    required this.professional,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical:  8),
      leading: AvatarWidget(
        imageUrl: professional.avatarUrl,
        name: professional.displayName,
        size: 52,
        isVerified: professional.isVerified,
      ),
      title: Text(
        isUnlocked ? professional.displayName : professional.visibleName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            professional.profession,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height:  4),
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