import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class Helpers {
  Helpers._();

  // ============================================================
  // DATE & TIME HELPERS
  // ============================================================

  /// Format date to display string
  static String formatDate(DateTime?  date, {String format = 'dd MMM yyyy'}) {
    if (date == null) return '';
    return DateFormat(format).format(date);
  }

  /// Format time to display string
  static String formatTime(DateTime?  date) {
    if (date == null) return '';
    return DateFormat('h:mm a').format(date);
  }

  /// Format date and time
  static String formatDateTime(DateTime?  date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy, h:mm a').format(date);
  }

  /// Get relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ?  'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday. year &&
        date.month == yesterday.month &&
        date. day == yesterday.day;
  }

  // ============================================================
  // STRING HELPERS
  // ============================================================

  /// Capitalize first letter
  static String capitalize(String?  text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Capitalize each word
  static String capitalizeEachWord(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String?  text, int maxLength) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get initials from name
  static String getInitials(String?  name, {int count = 2}) {
    if (name == null || name.isEmpty) return '';
    final words = name.trim().split(' ');
    final initials = words.take(count).map((word) => word.isNotEmpty ? word[0] : '').join('');
    return initials.toUpperCase();
  }

  /// Mask string (e.g., for phone/email)
  static String mask(String? text, {int visibleStart = 3, int visibleEnd = 3}) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= visibleStart + visibleEnd) return text;
    
    final start = text.substring(0, visibleStart);
    final end = text. substring(text.length - visibleEnd);
    final masked = '*' * (text.length - visibleStart - visibleEnd);
    
    return '$start$masked$end';
  }

  /// Format phone number
  static String formatPhone(String?  phone) {
    if (phone == null || phone.isEmpty) return '';
    
    // Remove non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    
    return phone;
  }

  // ============================================================
  // NUMBER HELPERS
  // ============================================================

  /// Format currency
  static String formatCurrency(
    num?  amount, {
    String symbol = '₹',
    int decimalPlaces = 0,
  }) {
    if (amount == null) return '$symbol 0';
    return '$symbol ${NumberFormat('#,##,###${decimalPlaces > 0 ? '.' + '0' * decimalPlaces : ''}').format(amount)}';
  }

  /// Format number with K, M suffix
  static String formatCompactNumber(num? number) {
    if (number == null) return '0';
    return NumberFormat. compact().format(number);
  }

  /// Format percentage
  static String formatPercentage(num? value, {int decimalPlaces = 1}) {
    if (value == null) return '0%';
    return '${value.toStringAsFixed(decimalPlaces)}%';
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  /// Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.error
            : isSuccess
                ?  AppColors.success
                : AppColors.surface,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:  BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show loading dialog
  static Future<void> showLoadingDialog(
    BuildContext context, {
    String?  message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop:  false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child:  Column(
              mainAxisSize:  MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hide dialog
  static void hideDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show confirmation dialog
  static Future<bool? > showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: isDestructive ?  AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATION HELPERS
  // ============================================================

  /// Check if string is valid email
  static bool isValidEmail(String?  email) {
    if (email == null || email.isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if string is valid phone
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10;
  }

  /// Check if string is valid URL
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return Uri.tryParse(url)?.hasAbsolutePath ??  false;
  }

  // ============================================================
  // COLOR HELPERS
  // ============================================================

  /// Get color from status
  static Color getStatusColor(String?  status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'success':
      case 'completed':
      case 'verified':
        return AppColors.success;
      case 'pending':
      case 'processing':
      case 'warning':
        return AppColors.warning;
      case 'inactive':
      case 'error':
      case 'failed': 
      case 'cancelled':
        return AppColors.error;
      case 'info':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }

  /// Get color from plan
  static Color getPlanColor(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'pro':
      case 'business':
        return AppColors.accent;
      case 'plus':
      case 'starter':
        return AppColors.primary;
      case 'basic':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }
}