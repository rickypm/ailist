import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Preferences',
            children: [
              _SettingsTile(
                icon: Iconsax.notification,
                title: 'Notifications',
                trailing: Switch(
                  value:  true,
                  onChanged: (value) {},
                  // FIXED: Replaced deprecated activeColor with thumbColor
                  thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppColors.primary;
                    }
                    return AppColors.white; // Or default
                  }),
                  activeTrackColor: AppColors.primary.withOpacity(0.5),
                ),
              ),
              _SettingsTile(
                icon: Iconsax. location,
                title: 'Location',
                subtitle: 'Shillong',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Iconsax. info_circle,
                title: 'Version',
                subtitle: AppConfig.appVersion,
              ),
              _SettingsTile(
                icon: Iconsax. document,
                title: 'Terms of Service',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Iconsax.shield_tick,
                title: 'Privacy Policy',
                onTap:  () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize:  14,
            fontWeight:  FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height:  12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius. circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String?  subtitle;
  final Widget?  trailing;
  final VoidCallback?  onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this. subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ?  Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: AppColors.textMuted,
                )
              : null),
      onTap: onTap,
    );
  }
}