import 'package:flutter/material.dart';
import '../../config/theme.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback?  onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isDisabled;
  final double?  width;
  final double height;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    this. onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDisabled = false,
    this.width,
    this.height = 52,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    final foregroundColor = textColor ?? AppColors.white;

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: (isLoading || isDisabled) ? null : onPressed,
          style:  OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor),
            shape:  RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildChild(buttonColor),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: buttonColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius:  BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(foregroundColor),
      ),
    );
  }

  Widget _buildChild(Color textColorValue) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? textColorValue : AppColors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}