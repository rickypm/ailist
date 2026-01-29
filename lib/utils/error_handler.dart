import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';

class ErrorHandler {
  ErrorHandler._();

  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return _handleAuthError(error);
    }
    
    if (error is PostgrestException) {
      return _handleDatabaseError(error);
    }
    
    if (error is StorageException) {
      return _handleStorageError(error);
    }
    
    if (error is String) {
      return error;
    }
    
    return 'An unexpected error occurred.  Please try again.';
  }

  static String _handleAuthError(AuthException error) {
    switch (error.message. toLowerCase()) {
      case 'invalid login credentials':
        return 'Invalid email or password';
      case 'email not confirmed':
        return 'Please verify your email address';
      case 'user already registered':
        return 'An account with this email already exists';
      case 'password should be at least 6 characters': 
        return 'Password must be at least 6 characters';
      case 'unable to validate email address:  invalid format':
        return 'Please enter a valid email address';
      default:
        return error.message;
    }
  }

  static String _handleDatabaseError(PostgrestException error) {
    if (error.code == '23505') {
      return 'This record already exists';
    }
    
    if (error.code == '23503') {
      return 'Referenced record not found';
    }
    
    if (error.code == '42501') {
      return 'You do not have permission to perform this action';
    }
    
    return 'Database error. Please try again.';
  }

  static String _handleStorageError(StorageException error) {
    if (error.statusCode == '413') {
      return 'File is too large.  Maximum size is 5MB. ';
    }
    
    if (error.statusCode == '415') {
      return 'File type not supported';
    }
    
    return 'Error uploading file. Please try again. ';
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:  BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  Text(message),
        backgroundColor:  AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  Text(message),
        backgroundColor:  AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}