import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String?  subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double iconSize;
  final Color? iconColor;

  const EmptyState({
    super.key,
    this. icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconSize = 80,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child:  Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: iconSize + 40,
              height: iconSize + 40,
              decoration: BoxDecoration(
                color: (iconColor ??  AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon ?? Iconsax.box,
                  size: iconSize,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height:  24),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign. center,
              ),
            ],

            // Button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: buttonText! ,
                onPressed: onButtonPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}