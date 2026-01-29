import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';

class UnlockDialog extends StatelessWidget {
  final String professionalName;
  final int unlocksRemaining;
  final bool isLoading;
  final VoidCallback onUnlock;
  final VoidCallback onUpgrade;
  final VoidCallback onCancel;

  const UnlockDialog({
    super.key,
    required this. professionalName,
    required this.unlocksRemaining,
    this.isLoading = false,
    required this.onUnlock,
    required this.onUpgrade,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnlocks = unlocksRemaining > 0;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: hasUnlocks
                    ? AppColors.inputBorderGradient
                    : null,
                color: hasUnlocks ? null : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasUnlocks ? Iconsax.unlock :  Iconsax.lock,
                color: AppColors.white,
                size: 32,
              ),
            ),
            const SizedBox(height:  20),

            // Title
            Text(
              hasUnlocks ? 'Unlock Contact' : 'No Unlocks Left',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              hasUnlocks
                  ? 'Unlock $professionalName\'s full contact details including phone number and start a conversation.'
                  : 'You have used all your unlocks.  Upgrade your plan to get more unlocks.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Unlocks Remaining Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: hasUnlocks
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child:  Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.unlock,
                    size: 16,
                    color: hasUnlocks ? AppColors.primary : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$unlocksRemaining unlocks remaining',
                    style: TextStyle(
                      color: hasUnlocks ? AppColors.primary :  AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            if (hasUnlocks) ...[
              // Unlock Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:  isLoading ? null : onUnlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment:  MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.unlock, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Unlock Now',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height:  12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed:  onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Upgrade Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.crown, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Upgrade Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double. infinity,
                height: 50,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight. w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show the unlock dialog
  static Future<bool? > show(
    BuildContext context, {
    required String professionalName,
    required int unlocksRemaining,
    required Future<bool> Function() onUnlock,
    required VoidCallback onUpgrade,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;

            return UnlockDialog(
              professionalName: professionalName,
              unlocksRemaining: unlocksRemaining,
              isLoading: isLoading,
              onUnlock: () async {
                setState(() => isLoading = true);
                final success = await onUnlock();
                if (context.mounted) {
                  Navigator.pop(context, success);
                }
              },
              onUpgrade: () {
                Navigator.pop(context, false);
                onUpgrade();
              },
              onCancel: () => Navigator.pop(context, false),
            );
          },
        );
      },
    );
  }
}