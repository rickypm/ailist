import 'package:flutter/material.dart';
import '../../config/theme.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;

  const LoadingWidget({
    super.key,
    this.size = 40,
    this.strokeWidth = 3,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message! ,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize:  14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class LoadingPage extends StatelessWidget {
  final String?  message;

  const LoadingPage({
    super.key,
    this. message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LoadingWidget(message: message),
      ),
    );
  }
}

class LoadingOverlayWidget extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlayWidget({
    super.key,
    required this. isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: AppColors.background.withValues(alpha: 0.7),
              child: Center(
                child: LoadingWidget(message: message),
              ),
            ),
          ),
      ],
    );
  }
}