import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';

class GradientSearchInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onSubmitted;
  final VoidCallback? onVoiceTap;
  final String hintText;
  final bool enabled;

  const GradientSearchInput({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onVoiceTap,
    this.hintText = 'Ask for a service',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: AppColors.inputBorderGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Row(
            children: [
              // Text Input
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style:  const TextStyle(
                    color:  AppColors.textDark,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText:  hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted:  onSubmitted,
                ),
              ),

              // Voice Button
              GestureDetector(
                onTap: onVoiceTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Icon(
                    Iconsax.microphone_2,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}